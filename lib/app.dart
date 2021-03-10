import 'package:flutter/material.dart';
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
import 'package:kitchenowl/styles/colors.dart';

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
            theme: ThemeData(
              primarySwatch: AppColors.green,
              visualDensity: VisualDensity.adaptivePlatformDensity,
            ),
            darkTheme: ThemeData.dark().copyWith(
              accentColor: AppColors.green,
              colorScheme: ColorScheme.fromSwatch(
                primarySwatch: AppColors.green,
                accentColor: AppColors.green,
                brightness: Brightness.dark,
              ),
              visualDensity: VisualDensity.adaptivePlatformDensity,
            ),
            themeMode: state.themeMode,
            debugShowCheckedModeBanner: false,
            home: BlocBuilder<AuthCubit, AuthState>(
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
    );
  }
}
