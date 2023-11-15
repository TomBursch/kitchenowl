import 'package:animations/animations.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:kitchenowl/cubits/auth_cubit.dart';
import 'package:kitchenowl/enums/expenselist_sorting.dart';
import 'package:kitchenowl/helpers/fade_through_transition_page.dart';
import 'package:kitchenowl/helpers/shared_axis_transition_page.dart';
import 'package:kitchenowl/models/expense.dart';
import 'package:kitchenowl/models/household.dart';
import 'package:kitchenowl/models/recipe.dart';
import 'package:kitchenowl/pages/email_confirm_page.dart';
import 'package:kitchenowl/pages/expense_overview_page.dart';
import 'package:kitchenowl/pages/expense_page.dart';
import 'package:kitchenowl/pages/household_page/_export.dart';
import 'package:kitchenowl/pages/household_list_page.dart';
import 'package:kitchenowl/pages/login_page.dart';
import 'package:kitchenowl/pages/login_redirect_page.dart';
import 'package:kitchenowl/pages/onboarding_page.dart';
import 'package:kitchenowl/pages/page_not_found.dart';
import 'package:kitchenowl/pages/password_forgot_page.dart';
import 'package:kitchenowl/pages/password_reset_page.dart';
import 'package:kitchenowl/pages/recipe_page.dart';
import 'package:kitchenowl/pages/recipe_scraper_page.dart';
import 'package:kitchenowl/pages/settings_page.dart';
import 'package:kitchenowl/pages/settings_user_page.dart';
import 'package:kitchenowl/pages/setup_page.dart';
import 'package:kitchenowl/pages/signup_page.dart';
import 'package:kitchenowl/pages/splash_page.dart';
import 'package:kitchenowl/pages/unreachable_page.dart';
import 'package:kitchenowl/pages/household_page.dart';
import 'package:kitchenowl/pages/unsupported_page.dart';
import 'package:kitchenowl/services/storage/storage.dart';
import 'package:tuple/tuple.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final RouteObserver<ModalRoute> routeObserver = RouteObserver<ModalRoute>();

Uri? initialLocation;

const List<String> publicRoutes = [
  "/register",
  "/signin",
  "/signin/redirect",
  "/confirm-email",
  "/reset-password",
  "/forgot-password",
];

// GoRouter configuration
final router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  redirect: (BuildContext context, GoRouterState state) {
    final authState = BlocProvider.of<AuthCubit>(context).state;
    initialLocation ??= state.uri;
    if (authState is Setup) return "/setup";
    if (authState is Onboarding) return "/onboarding";
    if (authState is Unauthenticated &&
        !publicRoutes.contains(state.uri.path)) {
      return "/signin";
    }
    if (authState is Unreachable) return "/unreachable";
    if (authState is Unsupported) return "/unsupported";
    if (authState is Loading) return "/";

    return null;
  },
  errorBuilder: (context, state) => const PageNotFound(),
  observers: [routeObserver],
  routes: [
    GoRoute(
      path: '/',
      pageBuilder: (context, state) => SharedAxisTransitionPage(
        key: state.pageKey,
        name: state.name,
        transitionType: SharedAxisTransitionType.scaled,
        child: const SplashPage(),
      ),
      redirect: (BuildContext context, GoRouterState state) {
        final authState = BlocProvider.of<AuthCubit>(context).state;
        if (authState is! Loading) {
          return "/household";
        }

        return null;
      },
    ),
    GoRoute(
      path: '/setup',
      pageBuilder: (context, state) => SharedAxisTransitionPage(
        key: state.pageKey,
        name: state.name,
        child: const SetupPage(),
      ),
      redirect: (BuildContext context, GoRouterState state) {
        final authState = BlocProvider.of<AuthCubit>(context).state;

        return (authState is! Setup) ? "/" : null;
      },
    ),
    GoRoute(
      path: '/onboarding',
      pageBuilder: (context, state) => SharedAxisTransitionPage(
        key: state.pageKey,
        name: state.name,
        child: const OnboardingPage(),
      ),
      redirect: (BuildContext context, GoRouterState state) {
        final authState = BlocProvider.of<AuthCubit>(context).state;

        return (authState is! Onboarding) ? "/" : null;
      },
    ),
    GoRoute(
      path: '/signin',
      pageBuilder: (context, state) => SharedAxisTransitionPage(
        key: state.pageKey,
        name: state.name,
        child: const LoginPage(),
      ),
      redirect: (BuildContext context, GoRouterState state) {
        final authState = BlocProvider.of<AuthCubit>(context).state;

        return (authState is! Unauthenticated) ? "/" : null;
      },
      routes: [
        GoRoute(
          path: 'redirect',
          pageBuilder: (context, state) => SharedAxisTransitionPage(
            key: state.pageKey,
            name: state.name,
            child: LoginRedirectPage(
              key: ValueKey(state.uri.queryParameters["state"]),
              state: state.uri.queryParameters["state"],
              code: state.uri.queryParameters["code"],
            ),
          ),
        ),
      ],
    ),
    GoRoute(
      path: '/register',
      pageBuilder: (context, state) => SharedAxisTransitionPage(
        key: state.pageKey,
        name: state.name,
        child: const SignupPage(),
      ),
      redirect: (BuildContext context, GoRouterState state) {
        final authState = BlocProvider.of<AuthCubit>(context).state;

        return (authState is! Unauthenticated) ? "/" : null;
      },
    ),
    GoRoute(
      path: '/unsupported',
      pageBuilder: (context, state) => SharedAxisTransitionPage(
        key: state.pageKey,
        name: state.name,
        transitionType: SharedAxisTransitionType.scaled,
        child: const UnsupportedPage(),
      ),
      redirect: (BuildContext context, GoRouterState state) {
        final authState = BlocProvider.of<AuthCubit>(context).state;

        return (authState is! Unsupported) ? "/" : null;
      },
    ),
    GoRoute(
      path: '/unreachable',
      pageBuilder: (context, state) => SharedAxisTransitionPage(
        key: state.pageKey,
        name: state.name,
        transitionType: SharedAxisTransitionType.scaled,
        child: const UnreachablePage(),
      ),
      redirect: (BuildContext context, GoRouterState state) {
        final authState = BlocProvider.of<AuthCubit>(context).state;

        return (authState is! Unreachable) ? "/" : null;
      },
    ),
    GoRoute(
      path: "/household",
      pageBuilder: (context, state) => SharedAxisTransitionPage(
        key: state.pageKey,
        name: state.name,
        transitionType: SharedAxisTransitionType.scaled,
        child: const HouseholdListPage(),
      ),
      redirect: (context, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '');
        if (id != null) {
          PreferenceStorage.getInstance().writeInt(
            key: 'lastHouseholdId',
            value: id,
          );
        } else {
          PreferenceStorage.getInstance().delete(
            key: 'lastHouseholdId',
          );
        }

        return null;
      },
      routes: [
        GoRoute(
          name: "household",
          path: ":id",
          builder: (context, state) => const SplashPage(),
          redirect: (context, state) {
            if (state.matchedLocation == state.uri.path) {
              return "${state.matchedLocation}/${(state.extra as Household?)?.viewOrdering?.firstOrNull.toString() ?? "items"}";
            }

            return null;
          },
          routes: [
            ShellRoute(
              builder: (context, state, child) => HouseholdPage(
                household: ((state.extra is Household?)
                        ? (state.extra as Household?)
                        : null) ??
                    Household(
                      id: int.tryParse(state.pathParameters['id'] ?? '') ?? -1,
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
                      builder: (context, state) {
                        final extra =
                            (state.extra as Tuple2<Household, Recipe>?);

                        return RecipePage(
                          recipe: extra?.item2 ??
                              Recipe(
                                id: int.tryParse(
                                  state.pathParameters['recipeId'] ?? '',
                                ),
                              ),
                          household: extra?.item1 ??
                              Household(
                                id: int.tryParse(
                                      state.pathParameters['id'] ?? '',
                                    ) ??
                                    -1,
                              ),
                          updateOnPlanningEdit: state.uri
                                  .queryParameters['updateOnPlanningEdit'] ==
                              true.toString(),
                          selectedYields: int.tryParse(
                            state.uri.queryParameters['selectedYields'] ?? "",
                          ),
                        );
                      },
                    ),
                    GoRoute(
                      parentNavigatorKey: _rootNavigatorKey,
                      path: 'scrape',
                      builder: (context, state) => RecipeScraperPage(
                        url: state.uri.queryParameters['url']!,
                        household: Household(
                          id: int.tryParse(state.pathParameters['id'] ?? '') ??
                              -1,
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
                  routes: [
                    GoRoute(
                      parentNavigatorKey: _rootNavigatorKey,
                      path: 'overview',
                      builder: (context, state) => ExpenseOverviewPage(
                        household: Household(
                          id: int.tryParse(state.pathParameters['id'] ?? '') ??
                              -1,
                        ),
                        initialSorting: state.extra as ExpenselistSorting? ??
                            ExpenselistSorting.all,
                      ),
                    ),
                  ],
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
                household: (state.extra as Tuple2<Household, Expense>?)
                        ?.item1 ??
                    Household(
                      id: int.tryParse(state.pathParameters['id'] ?? '') ?? -1,
                    ),
                expense: (state.extra as Tuple2<Household, Expense>?)?.item2 ??
                    Expense(
                      id: int.tryParse(state.pathParameters['expenseId'] ?? ''),
                      paidById: 0,
                    ),
              ),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/settings',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => SettingsPage(
        household: state.extra as Household?,
      ),
      routes: [
        GoRoute(
          path: 'account',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => const SettingsUserPage(),
        ),
      ],
    ),
    GoRoute(
      path: '/confirm-email',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => EmailConfirmPage(
        key: ValueKey(state.uri.queryParameters["t"]),
        token: state.uri.queryParameters["t"],
      ),
    ),
    GoRoute(
      path: '/reset-password',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => PasswordResetPage(
        key: ValueKey(state.uri.queryParameters["t"]),
        token: state.uri.queryParameters["t"],
      ),
    ),
    GoRoute(
      path: '/forgot-password',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => SharedAxisTransitionPage(
        key: state.pageKey,
        name: state.name,
        child: const PasswordForgotPage(),
      ),
    ),
  ],
);
