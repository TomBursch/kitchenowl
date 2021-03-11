import 'dart:io';

import 'package:flutter/foundation.dart';
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
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).requestFocus(FocusNode());
      },
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (BuildContext context) => AuthCubit()),
          BlocProvider(create: (BuildContext context) => SettingsCubit()),
        ],
        child: BlocBuilder<SettingsCubit, SettingsState>(
          builder: (context, state) => MaterialApp(
            onGenerateTitle: (BuildContext context) =>
                AppLocalizations.of(context).appTitle,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: AppThemes.light,
            darkTheme: AppThemes.dark,
            themeMode: state.themeMode,
            debugShowCheckedModeBanner: false,
            home: BlocListener<SettingsCubit, SettingsState>(
              listener: (context, state) {
                if (!kIsWeb && (Platform.isAndroid || Platform.isIOS))
                  _setSystemUI(context, state);
              },
              listenWhen: (previous, current) =>
                  previous.themeMode != current.themeMode,
              child: BlocBuilder<AuthCubit, AuthState>(
                builder: (context, state) {
                  if (state is Setup) return SetupPage();
                  if (state is Onboarding) return OnboardingPage();
                  if (state is Unauthenticated) return LoginPage();
                  if (state is Authenticated) return HomePage();
                  if (state is Unreachable) return UnreachablePage();
                  if (state is Unsupported) return UnsupportedPage();
                  return SplashPage();
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _setSystemUI(BuildContext context, SettingsState state) {
    switch (state.themeMode) {
      case ThemeMode.system:
        final Brightness brightnessValue =
            MediaQuery.of(context).platformBrightness;
        if (brightnessValue == Brightness.dark)
          continue dark;
        else
          continue light;
        break;
      light:
      case ThemeMode.light:
        final Color backgroundColor = AppThemes.light.scaffoldBackgroundColor;
        SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarColor: backgroundColor,
          systemNavigationBarDividerColor: backgroundColor,
          systemNavigationBarIconBrightness: Brightness.dark,
        ));
        break;
      dark:
      case ThemeMode.dark:
        final Color backgroundColor = AppThemes.dark.scaffoldBackgroundColor;
        SystemChrome.setSystemUIOverlayStyle(
            SystemUiOverlayStyle.light.copyWith(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: backgroundColor,
          systemNavigationBarDividerColor: backgroundColor,
          systemNavigationBarIconBrightness: Brightness.light,
        ));
        break;
    }
  }
}
