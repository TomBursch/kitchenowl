import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:kitchenowl/cubits/auth_cubit.dart';
import 'package:kitchenowl/cubits/settings_cubit.dart';
import 'package:kitchenowl/pages/login_page.dart';
import 'package:kitchenowl/pages/onboarding_page.dart';
import 'package:kitchenowl/pages/setup_page.dart';
import 'package:kitchenowl/pages/splash_page.dart';
import 'package:kitchenowl/pages/unreachable_page.dart';
import 'package:kitchenowl/pages/home_page.dart';
import 'package:kitchenowl/pages/unsupported_page.dart';
import 'package:kitchenowl/styles/themes.dart';

class App extends StatelessWidget {
  static App? _instance;
  final SettingsCubit _settingsCubit = SettingsCubit();

  static bool isOffline(BuildContext context) =>
      BlocProvider.of<AuthCubit>(context).state is AuthenticatedOffline ||
      isForcedOffline;

  static bool get isForcedOffline =>
      _instance!._settingsCubit.state.forcedOfflineMode;

  App({Key? key}) : super(key: key) {
    _instance = this;
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
          BlocProvider(create: (BuildContext context) => AuthCubit()),
          BlocProvider.value(value: _settingsCubit),
        ],
        child: BlocBuilder<SettingsCubit, SettingsState>(
          builder: (context, state) => MaterialApp(
            onGenerateTitle: (BuildContext context) =>
                AppLocalizations.of(context)!.appTitle,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: AppThemes.light,
            darkTheme: AppThemes.dark,
            themeMode: state.themeMode,
            debugShowCheckedModeBanner: false,
            restorationScopeId: "com.tombursch.kitchenowl",
            home: Builder(
              builder: (context) => AnnotatedRegion<SystemUiOverlayStyle>(
                value: _getSystemUI(context, state),
                child: BlocBuilder<AuthCubit, AuthState>(
                  builder: (context, state) {
                    if (state is Setup) return SetupPage();
                    if (state is Onboarding) return OnboardingPage();
                    if (state is Unauthenticated) return LoginPage();
                    if (state is Authenticated) return const HomePage();
                    if (state is Unreachable) return const UnreachablePage();
                    if (state is Unsupported) return const UnsupportedPage();
                    return const SplashPage();
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Method always returns a value
  // ignore: missing_return
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
        final Color backgroundColor = AppThemes.light.scaffoldBackgroundColor;
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
        final Color backgroundColor = AppThemes.dark.scaffoldBackgroundColor;
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
}
