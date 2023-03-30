import 'dart:async';
import 'dart:io';

import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:kitchenowl/cubits/auth_cubit.dart';
import 'package:kitchenowl/cubits/settings_cubit.dart';
import 'package:kitchenowl/helpers/fade_through_transition_page.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/models/expense.dart';
import 'package:kitchenowl/models/household.dart';
import 'package:kitchenowl/models/recipe.dart';
import 'package:kitchenowl/pages/expense_page.dart';
import 'package:kitchenowl/pages/household_page/_export.dart';
import 'package:kitchenowl/pages/household_list_page.dart';
import 'package:kitchenowl/pages/login_page.dart';
import 'package:kitchenowl/pages/onboarding_page.dart';
import 'package:kitchenowl/pages/page_not_found.dart';
import 'package:kitchenowl/pages/recipe_page.dart';
import 'package:kitchenowl/pages/recipe_scraper_page.dart';
import 'package:kitchenowl/pages/setup_page.dart';
import 'package:kitchenowl/pages/splash_page.dart';
import 'package:kitchenowl/pages/unreachable_page.dart';
import 'package:kitchenowl/pages/household_page.dart';
import 'package:kitchenowl/pages/unsupported_page.dart';
import 'package:kitchenowl/styles/colors.dart';
import 'package:kitchenowl/styles/themes.dart';
import 'package:share_handler/share_handler.dart';

class App extends StatefulWidget {
  static App? _instance;
  final SettingsCubit _settingsCubit = SettingsCubit();
  final AuthCubit _authCubit = AuthCubit();

  static bool get isOffline =>
      _instance!._authCubit.state is AuthenticatedOffline || isForcedOffline;

  static bool get isForcedOffline =>
      _instance!._authCubit.state.forcedOfflineMode;

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
        child: BlocListener<AuthCubit, AuthState>(
          bloc: widget._authCubit,
          listenWhen: (previous, current) =>
              previous != current &&
              !(previous is Authenticated && current is Authenticated),
          listener: (context, state) {
            if (state is Setup) _router.go("/setup");
            if (state is Onboarding) _router.go("/onboarding");
            if (state is Unauthenticated) _router.go("/signin");
            if (state is Unreachable) _router.go("/unreachable");
            if (state is Unsupported) _router.go("/unsupported");
            if (state is LoadingOnboard) _router.go("/");
            if (state is Loading) _router.go("/");
            if (state is Authenticated) _router.go("/household/1");
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
              }

              return MaterialApp.router(
                builder: (context, child) =>
                    AnnotatedRegion<SystemUiOverlayStyle>(
                  value: _getSystemUI(context, state),
                  child: child ?? const SizedBox(),
                ),
                onGenerateTitle: (BuildContext context) =>
                    AppLocalizations.of(context)!.appTitle,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales:
                    const [Locale('en')] + AppLocalizations.supportedLocales,
                theme: AppThemes.light(lightColorScheme),
                darkTheme: AppThemes.dark(darkColorScheme),
                themeMode: state.themeMode,
                color: AppColors.green,
                debugShowCheckedModeBanner: false,
                restorationScopeId: "com.tombursch.kitchenowl",
                routerConfig: _router,
              );
            }),
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
      _router.go("/household/1/recipes/scrape?url=\"${media.content!}\"");
    }
  }
}

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

// GoRouter configuration
final _router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  redirect: (BuildContext context, GoRouterState state) {
    final authState = BlocProvider.of<AuthCubit>(context).state;
    if (authState is Setup) return "/setup";
    if (authState is Onboarding) return "/onboarding";
    if (authState is Unauthenticated) return "/signin";
    if (authState is Unreachable) return "/unreachable";
    if (authState is Unsupported) return "/unsupported";
    if (authState is LoadingOnboard) return "/";
    if (authState is Loading) return "/";

    return null;
  },
  errorBuilder: (context, state) => const PageNotFound(),
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashPage(),
      redirect: (BuildContext context, GoRouterState state) {
        final authState = BlocProvider.of<AuthCubit>(context).state;
        if (authState is! LoadingOnboard && authState is! Loading) {
          return "/household";
        }

        return null;
      },
    ),
    GoRoute(
      path: '/setup',
      builder: (context, state) => const SetupPage(),
      redirect: (BuildContext context, GoRouterState state) {
        final authState = BlocProvider.of<AuthCubit>(context).state;

        return (authState is! Setup) ? "/" : null;
      },
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingPage(),
      redirect: (BuildContext context, GoRouterState state) {
        final authState = BlocProvider.of<AuthCubit>(context).state;

        return (authState is! Onboarding) ? "/" : null;
      },
    ),
    GoRoute(
      path: '/signin',
      builder: (context, state) => const LoginPage(),
      redirect: (BuildContext context, GoRouterState state) {
        final authState = BlocProvider.of<AuthCubit>(context).state;

        return (authState is! Unauthenticated) ? "/" : null;
      },
    ),
    GoRoute(
      path: '/unsupported',
      builder: (context, state) => const UnsupportedPage(),
      redirect: (BuildContext context, GoRouterState state) {
        final authState = BlocProvider.of<AuthCubit>(context).state;

        return (authState is! Unsupported) ? "/" : null;
      },
    ),
    GoRoute(
      path: '/unreachable',
      builder: (context, state) => const UnreachablePage(),
      redirect: (BuildContext context, GoRouterState state) {
        final authState = BlocProvider.of<AuthCubit>(context).state;

        return (authState is! Unreachable) ? "/" : null;
      },
    ),
    GoRoute(
      path: "/household",
      builder: (context, state) => const HouseholdListPage(),
      routes: [
        GoRoute(
          name: "household",
          path: ":id",
          builder: (context, state) => const SplashPage(),
          redirect: (context, state) {
            if (state.subloc == state.location) return "${state.subloc}/items";

            return null;
          },
          routes: [
            ShellRoute(
              builder: (context, state, child) => HouseholdPage(
                household: Household(
                  id: int.tryParse(state.params['id'] ?? '') ?? -1,
                ),
                child: child,
              ),
              routes: [
                GoRoute(
                  path: "items",
                  pageBuilder: (context, state) => FadeThroughTransitionPage(
                    key: state.pageKey,
                    name: state.name,
                    child: const ShoppinglistPage(),
                  ),
                ),
                GoRoute(
                  path: "recipes",
                  pageBuilder: (context, state) => FadeThroughTransitionPage(
                    key: state.pageKey,
                    name: state.name,
                    child: const RecipeListPage(),
                  ),
                  routes: [
                    GoRoute(
                      parentNavigatorKey: _rootNavigatorKey,
                      path: 'details/:recipeId',
                      builder: (context, state) => RecipePage(
                        recipe: (state.extra as Recipe?) ??
                            Recipe(
                              id: int.tryParse(state.params['recipeId'] ?? ''),
                            ),
                        household: Household(
                          id: int.tryParse(state.params['id'] ?? '') ?? -1,
                        ),
                        updateOnPlanningEdit:
                            state.queryParams['updateOnPlanningEdit'] ==
                                true.toString(),
                      ),
                    ),
                    GoRoute(
                      parentNavigatorKey: _rootNavigatorKey,
                      path: 'scrape',
                      builder: (context, state) => RecipeScraperPage(
                        url: state.queryParams['url']!,
                        household: Household(
                          id: int.tryParse(state.params['id'] ?? '') ?? -1,
                        ),
                      ),
                    ),
                  ],
                ),
                GoRoute(
                  path: "planner",
                  pageBuilder: (context, state) => FadeThroughTransitionPage(
                    key: state.pageKey,
                    name: state.name,
                    child: const PlannerPage(),
                  ),
                ),
                GoRoute(
                  path: "balances",
                  pageBuilder: (context, state) => FadeThroughTransitionPage(
                    key: state.pageKey,
                    name: state.name,
                    child: const ExpenseListPage(),
                  ),
                ),
                GoRoute(
                  path: "profile",
                  pageBuilder: (context, state) => FadeThroughTransitionPage(
                    key: state.pageKey,
                    name: state.name,
                    child: const ProfilePage(),
                  ),
                ),
              ],
            ),
            GoRoute(
              parentNavigatorKey: _rootNavigatorKey,
              path: 'expenses/:expenseId',
              builder: (context, state) => ExpensePage(
                household: (state.extra as List?)?[0] ??
                    Household(id: int.tryParse(state.params['id'] ?? '') ?? -1),
                expense: ((state.extra as List?)?[1] as Expense?) ??
                    Expense(
                      id: int.tryParse(state.params['expenseId'] ?? ''),
                      paidById: 0,
                    ),
              ),
            ),
          ],
        ),
      ],
    ),
    // GoRoute(
    //   path: '/recipes/:id',
    //   builder: (context, state) => RecipePage(
    //     recipe: (state.extra as Recipe?) ??
    //         Recipe(
    //           id: int.tryParse(state.params['id'] ?? ''),
    //         ),
    //   ),
    // ),
  ],
);
