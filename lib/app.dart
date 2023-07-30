import 'dart:async';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:kitchenowl/cubits/auth_cubit.dart';
import 'package:kitchenowl/cubits/server_info_cubit.dart';
import 'package:kitchenowl/cubits/settings_cubit.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/router.dart';
import 'package:kitchenowl/services/storage/storage.dart';
import 'package:kitchenowl/services/transaction_handler.dart';
import 'package:kitchenowl/styles/colors.dart';
import 'package:kitchenowl/styles/themes.dart';
import 'package:share_handler/share_handler.dart';
// ignore: depend_on_referenced_packages
import 'package:image_picker_android/image_picker_android.dart';
// ignore: depend_on_referenced_packages
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';

class App extends StatefulWidget {
  static App? _instance;
  final TransactionHandler transactionHandler =
      TransactionHandler.getInstance(); // TODO refactor to repository pattern
  final SettingsCubit _settingsCubit = SettingsCubit();
  final AuthCubit _authCubit = AuthCubit();
  final ServerInfoCubit _serverInfoCubit = ServerInfoCubit();

  static bool get isOffline =>
      _instance!._authCubit.state is AuthenticatedOffline || isForcedOffline;

  static bool get isForcedOffline =>
      _instance!._authCubit.state.forcedOfflineMode;

  static SettingsState get settings => _instance!._settingsCubit.state;

  static ServerInfoState get serverInfo => _instance!._serverInfoCubit.state;

  App({super.key}) {
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

    final ImagePickerPlatform imagePickerPlatform =
        ImagePickerPlatform.instance;
    if (imagePickerPlatform is ImagePickerAndroid) {
      DeviceInfoPlugin().androidInfo.then((value) {
        if (value.version.sdkInt >= 30) {
          imagePickerPlatform.useAndroidPhotoPicker = true;
        }
      });
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
      child: RepositoryProvider.value(
        value: widget.transactionHandler,
        child: MultiRepositoryProvider(
          providers: [
            RepositoryProvider.value(value: routeObserver),
          ],
          child: MultiBlocProvider(
            providers: [
              BlocProvider.value(value: widget._authCubit),
              BlocProvider.value(value: widget._settingsCubit),
              BlocProvider.value(value: widget._serverInfoCubit),
            ],
            child: BlocListener<AuthCubit, AuthState>(
              bloc: widget._authCubit,
              listenWhen: (previous, current) =>
                  previous != current &&
                  !(previous is Authenticated && current is Authenticated),
              listener: (context, state) {
                if (state is Setup) router.go("/setup");
                if (state is Onboarding) router.go("/onboarding");
                if (state is Unauthenticated) router.go("/signin");
                if (state is Unreachable) router.go("/unreachable");
                if (state is Unsupported) router.go("/unsupported");
                if (state is Loading) router.go("/");
                if (state is Authenticated) {
                  if (initialLocation != null && initialLocation != "/") {
                    router.go(initialLocation!);
                  } else {
                    PreferenceStorage.getInstance()
                        .readInt(key: 'lastHouseholdId')
                        .then((id) =>
                            router.go("/household${id == null ? "" : "/$id"}"));
                  }
                }
              },
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
                  } else if (state.accentColor != null) {
                    lightColorScheme =
                        ColorScheme.fromSeed(seedColor: state.accentColor!);
                    darkColorScheme = ColorScheme.fromSeed(
                      seedColor: state.accentColor!,
                      brightness: Brightness.dark,
                    );
                  }

                  return MaterialApp.router(
                    builder: (context, child) =>
                        AnnotatedRegion<SystemUiOverlayStyle>(
                      value: _getSystemUI(context, state),
                      child: child ?? const SizedBox(),
                    ),
                    onGenerateTitle: (BuildContext context) =>
                        AppLocalizations.of(context)!.appTitle,
                    localizationsDelegates:
                        AppLocalizations.localizationsDelegates,
                    supportedLocales: const [Locale('en')] +
                        AppLocalizations.supportedLocales,
                    theme: AppThemes.light(lightColorScheme),
                    darkTheme: AppThemes.dark(darkColorScheme),
                    themeMode: state.themeMode,
                    color: AppColors.green,
                    debugShowCheckedModeBanner: false,
                    restorationScopeId: "com.tombursch.kitchenowl",
                    routerConfig: router,
                  );
                }),
              ),
            ),
          ),
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
      PreferenceStorage.getInstance()
          .readInt(key: 'lastHouseholdId')
          .then((id) {
        if (id != null) {
          router.go(Uri(
            path: "/household/$id/recipes/scrape",
            queryParameters: {"url": media.content!},
          ).toString());
        }
      });
    }
  }
}
