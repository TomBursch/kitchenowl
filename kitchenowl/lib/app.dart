import 'dart:async';
import 'dart:io';

import 'package:background_fetch/background_fetch.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:dynamic_system_colors/dynamic_system_colors.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localized_locales/flutter_localized_locales.dart';
import 'package:kitchenowl/config.dart';
import 'package:kitchenowl/cubits/auth_cubit.dart';
import 'package:kitchenowl/cubits/server_info_cubit.dart';
import 'package:kitchenowl/cubits/settings_cubit.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/router.dart';
import 'package:kitchenowl/services/api/api_service.dart';
import 'package:kitchenowl/services/background_task.dart';
import 'package:kitchenowl/services/storage/storage.dart';
import 'package:kitchenowl/services/transaction_handler.dart';
import 'package:kitchenowl/styles/colors.dart';
import 'package:kitchenowl/styles/themes.dart';
import 'package:share_handler/share_handler.dart';
import 'package:image_picker_android/image_picker_android.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';

class App extends StatefulWidget {
  static App? _instance;
  final SettingsCubit _settingsCubit = SettingsCubit();
  final AuthCubit _authCubit = AuthCubit();
  final ServerInfoCubit _serverInfoCubit = ServerInfoCubit();

  static bool get isOffline => _instance!._authCubit.state.isOffline;

  static bool get isForcedOffline =>
      _instance!._authCubit.state.forcedOfflineMode;

  static bool get isDefaultServer => currentServer == Config.defaultServer;

  static String get currentServer => ApiService.getInstance().baseUrl.isEmpty
      ? Config.defaultServer
      : ApiService.getInstance()
          .baseUrl
          .substring(0, ApiService.getInstance().baseUrl.length - 4);

  static SettingsState get settings => _instance!._settingsCubit.state;

  static ServerInfoState get serverInfo => _instance!._serverInfoCubit.state;

  App({super.key}) {
    _instance = this;
  }

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> with WidgetsBindingObserver {
  StreamSubscription? _intentDataStreamSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

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

    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      BackgroundFetch.configure(
        BackgroundFetchConfig(
          minimumFetchInterval: 30,
          stopOnTerminate: false,
          enableHeadless: true,
          requiresBatteryNotLow: false,
          requiresCharging: false,
          requiresStorageNotLow: false,
          requiresDeviceIdle: false,
          requiredNetworkType: NetworkType.ANY,
        ),
        (String taskId) async {
          // <-- Event handler
          debugPrint("[BackgroundFetch] Event received $taskId");

          await BackgroundTask.run(widget._authCubit);

          // IMPORTANT:  You must signal completion of your task or the OS can punish your app
          // for taking too long in the background.
          BackgroundFetch.finish(taskId);
        },
        (String taskId) async {
          // <-- Task timeout handler.
          // This task has exceeded its allowed running-time.  You must stop what you're doing and immediately .finish(taskId)
          debugPrint("[BackgroundFetch] TASK TIMEOUT taskId: $taskId");
          BackgroundFetch.finish(taskId);
        },
      );
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      ApiService.getInstance().refresh().then((_) {
        TransactionHandler.getInstance().runOpenTransactions();
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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
      child: MultiRepositoryProvider(
        providers: [
          RepositoryProvider.value(value: TransactionHandler.getInstance()),
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
              if (state is Setup) return router.go("/setup");
              if (state is Onboarding) return router.go("/onboarding");
              if (state is Unauthenticated &&
                  (initialLocation == null ||
                      !publicRoutes.any(
                          (path) => initialLocation!.path.startsWith(path)))) {
                return router.go("/signin");
              }
              if (state is Unreachable) return router.go("/unreachable");
              if (state is Unsupported) return router.go("/unsupported");
              if (state is Loading) return router.go("/");
              if (state is Authenticated) {
                if ((initialLocation == null || initialLocation?.path == "/")) {
                  PreferenceStorage.getInstance()
                      .readInt(key: 'lastHouseholdId')
                      .then((id) =>
                          router.go("/household${id == null ? "" : "/$id"}"));
                  return;
                }
                if (initialLocation != null) {
                  final match = RegExp(r'\/recipe\/(\d+)')
                      .matchAsPrefix(initialLocation!.path);
                  if (match != null) {
                    // Redirect public recipe links to last household recipe links
                    PreferenceStorage.getInstance()
                        .readInt(key: 'lastHouseholdId')
                        .then((id) => router.go(id == null
                            ? initialLocation!.toString()
                            : "/household/${id}/recipes/details/${match.group(1)}"));
                    return;
                  }
                }
              }
              router.go(initialLocation!.toString());
              initialLocation = Uri(path: "/");
            },
            child: BlocBuilder<SettingsCubit, SettingsState>(
              builder: (context, state) =>
                  DynamicColorBuilder(builder: (lightDynamic, darkDynamic) {
                ColorScheme lightColorScheme = AppThemes.lightScheme;
                ColorScheme darkColorScheme = AppThemes.darkScheme;

                if (state.dynamicAccentColor &&
                    lightDynamic != null &&
                    darkDynamic != null) {
                  (lightColorScheme, darkColorScheme) =
                      (lightDynamic.harmonized(), darkDynamic.harmonized());
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
                      AppLocalizations.localizationsDelegates +
                          [
                            LocaleNamesLocalizationsDelegate(),
                          ],
                  supportedLocales:
                      const [Locale('en')] + AppLocalizations.supportedLocales,
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
    );
  }

  // Method always returns a value
  SystemUiOverlayStyle _getSystemUI(BuildContext context, SettingsState state) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    switch (state.themeMode) {
      case ThemeMode.system:
        final Brightness brightnessValue =
            MediaQuery.platformBrightnessOf(context);
        if (brightnessValue == Brightness.dark) {
          continue dark;
        } else {
          continue light;
        }
      light:
      case ThemeMode.light:
        final Color backgroundColor = Theme.of(context).colorScheme.surface;
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
        final Color backgroundColor = Theme.of(context).colorScheme.surface;
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
