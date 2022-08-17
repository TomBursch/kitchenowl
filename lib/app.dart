import 'dart:async';
import 'dart:io';

import 'package:animations/animations.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:kitchenowl/cubits/auth_cubit.dart';
import 'package:kitchenowl/cubits/settings_cubit.dart';
import 'package:kitchenowl/enums/update_enum.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/pages/login_page.dart';
import 'package:kitchenowl/pages/onboarding_page.dart';
import 'package:kitchenowl/pages/recipe_scraper_page.dart';
import 'package:kitchenowl/pages/setup_page.dart';
import 'package:kitchenowl/pages/splash_page.dart';
import 'package:kitchenowl/pages/unreachable_page.dart';
import 'package:kitchenowl/pages/home_page.dart';
import 'package:kitchenowl/pages/unsupported_page.dart';
import 'package:kitchenowl/styles/themes.dart';
import 'package:share_handler/share_handler.dart';

class App extends StatefulWidget {
  static App? _instance;
  final SettingsCubit _settingsCubit = SettingsCubit();
  final AuthCubit _authCubit = AuthCubit();

  static bool get isOffline =>
      _instance!._authCubit.state is AuthenticatedOffline || isForcedOffline;

  static bool get isForcedOffline =>
      _instance!._settingsCubit.state.forcedOfflineMode;

  App({Key? key}) : super(key: key) {
    _instance = this;
  }

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  StreamSubscription? _intentDataStreamSubscription;

  @override
  void initState() {
    super.initState();

    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      final handler = ShareHandlerPlatform.instance;
      _intentDataStreamSubscription =
          handler.sharedMediaStream.listen(_handleSharedMedia);
    }
  }

  @override
  void dispose() {
    _intentDataStreamSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScopeNode currentFocus = FocusScope.of(context);
        if (!currentFocus.hasPrimaryFocus) {
          currentFocus.focusedChild?.unfocus();
        }
      },
      child: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: widget._authCubit),
          BlocProvider.value(value: widget._settingsCubit),
        ],
        child: BlocBuilder<SettingsCubit, SettingsState>(
          builder: (context, state) =>
              DynamicColorBuilder(builder: (lightDynamic, darkDynamic) {
            ColorScheme lightColorScheme = AppThemes.lightScheme;
            ColorScheme darkColorScheme = AppThemes.darkScheme;

            if (state.dynamicAccentColor &&
                lightDynamic != null &&
                darkDynamic != null) {
              // On Android S+ devices, use the provided dynamic color scheme.
              // (Recommended) Harmonize the dynamic color scheme' built-in semantic colors.
              lightColorScheme = lightDynamic.harmonized();
              darkColorScheme = darkDynamic.harmonized();
            }

            return MaterialApp(
              onGenerateTitle: (BuildContext context) =>
                  AppLocalizations.of(context)!.appTitle,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              theme: AppThemes.light(lightColorScheme),
              darkTheme: AppThemes.dark(darkColorScheme),
              themeMode: state.themeMode,
              debugShowCheckedModeBanner: false,
              restorationScopeId: "com.tombursch.kitchenowl",
              home: Builder(
                builder: (context) => AnnotatedRegion<SystemUiOverlayStyle>(
                  value: _getSystemUI(context, state),
                  child: BlocBuilder<AuthCubit, AuthState>(
                    bloc: widget._authCubit,
                    builder: (context, state) => PageTransitionSwitcher(
                      transitionBuilder: (
                        Widget child,
                        Animation<double> animation,
                        Animation<double> secondaryAnimation,
                      ) {
                        return SharedAxisTransition(
                          animation: animation,
                          secondaryAnimation: secondaryAnimation,
                          transitionType: SharedAxisTransitionType.horizontal,
                          child: child,
                        );
                      },
                      child: Builder(
                        key: ValueKey(state.orderId),
                        builder: (context) {
                          if (state is Setup) return const SetupPage();
                          if (state is Onboarding) {
                            return const OnboardingPage();
                          }
                          if (state is Unauthenticated) {
                            return const LoginPage();
                          }
                          if (state is Authenticated) return const HomePage();
                          if (state is Unreachable) {
                            return const UnreachablePage();
                          }
                          if (state is Unsupported) {
                            return UnsupportedPage(
                              unsupportedBackend: state.unsupportedBackend,
                            );
                          }
                          if (state is LoadingOnboard) {
                            return SplashPage(
                              message: AppLocalizations.of(context)!
                                  .onboardingLoading,
                            );
                          }

                          return const SplashPage();
                        },
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  // Method always returns a value
  SystemUiOverlayStyle _getSystemUI(BuildContext context, SettingsState state) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    switch (state.themeMode) {
      case ThemeMode.system:
        final Brightness brightnessValue =
            MediaQuery.of(context).platformBrightness;
        if (brightnessValue == Brightness.dark) {
          continue dark;
        } else {
          continue light;
        }
      light:
      case ThemeMode.light:
        final Color backgroundColor = Theme.of(context).colorScheme.background;
        return SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarColor: backgroundColor.withAlpha(0),
          systemNavigationBarDividerColor: backgroundColor.withAlpha(0),
          systemNavigationBarIconBrightness: Brightness.dark,
          systemNavigationBarContrastEnforced: false,
        );
      dark:
      case ThemeMode.dark:
        final Color backgroundColor = Theme.of(context).colorScheme.background;
        return SystemUiOverlayStyle.light.copyWith(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: backgroundColor.withAlpha(0),
          systemNavigationBarDividerColor: backgroundColor.withAlpha(0),
          systemNavigationBarIconBrightness: Brightness.light,
          systemNavigationBarContrastEnforced: false,
        );
    }
  }

  void _handleSharedMedia(SharedMedia media) {
    if (mounted && media.content != null) {
      Navigator.of(context).push<UpdateEnum>(MaterialPageRoute(
        builder: (context) => RecipeScraperPage(
          url: media.content!,
        ),
      ));
    }
  }
}
