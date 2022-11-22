import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/cubits/auth_cubit.dart';
import 'package:kitchenowl/cubits/expense_list_cubit.dart';
import 'package:kitchenowl/cubits/planner_cubit.dart';
import 'package:kitchenowl/cubits/recipe_list_cubit.dart';
import 'package:kitchenowl/cubits/settings_cubit.dart';
import 'package:kitchenowl/cubits/shoppinglist_cubit.dart';
import 'package:kitchenowl/pages/home_page/_export.dart';
import 'package:responsive_builder/responsive_builder.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ShoppinglistCubit shoppingListCubit = ShoppinglistCubit();
  final RecipeListCubit recipeListCubit = RecipeListCubit();
  final PlannerCubit plannerCubit = PlannerCubit();
  final ExpenseListCubit expenseCubit = ExpenseListCubit();

  late List<HomePageItem> pages;
  int _selectedIndex = 0;
  int offset = 0;

  @override
  void initState() {
    super.initState();
    pages = [
      const ShoppinglistPage(),
      const RecipeListPage(),
      const PlannerPage(),
      ExpenseListPage(),
      const ProfilePage(),
    ];
  }

  @override
  void dispose() {
    shoppingListCubit.close();
    recipeListCubit.close();
    plannerCubit.close();
    expenseCubit.close();
    super.dispose();
  }

  void _onItemTapped(BuildContext context, HomePageItem page, int i) {
    page.onSelected(context, _selectedIndex == i);
    setState(() {
      _selectedIndex = i;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: shoppingListCubit),
        BlocProvider.value(value: recipeListCubit),
        BlocProvider.value(value: plannerCubit),
        BlocProvider.value(value: expenseCubit),
      ],
      child: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          return BlocConsumer<SettingsCubit, SettingsState>(
            listenWhen: (prev, curr) =>
                prev.serverSettings != curr.serverSettings,
            listener: (context, state) {
              final _offset =
                  (state.serverSettings.featurePlanner ?? false ? 0 : 1) +
                      (state.serverSettings.featureExpenses ?? false ? 0 : 1);
              _selectedIndex = (_selectedIndex *
                      (pages.length - _offset) /
                      (pages.length - offset))
                  .clamp(0, pages.length - _offset)
                  .round();

              offset = _offset;
            },
            builder: (context, state) {
              final _pages = pages.where((e) => e.isActive(context)).toList();

              Widget body = PageTransitionSwitcher(
                transitionBuilder: (
                  Widget child,
                  Animation<double> animation,
                  Animation<double> secondaryAnimation,
                ) {
                  return FadeThroughTransition(
                    animation: animation,
                    secondaryAnimation: secondaryAnimation,
                    child: child,
                  );
                },
                child: Align(
                  key: ValueKey<int>(_selectedIndex),
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints.expand(width: 1600),
                    child: _pages[_selectedIndex],
                  ),
                ),
              );

              final bool useBottomNavigationBar = getValueForScreenType<bool>(
                context: context,
                mobile: true,
                tablet: false,
                desktop: false,
              );

              if (!useBottomNavigationBar) {
                final bool extendedRail = getValueForScreenType<bool>(
                  context: context,
                  mobile: false,
                  tablet: false,
                  desktop: true,
                );
                body = Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SafeArea(
                      child: NavigationRail(
                        extended: extendedRail,
                        destinations: _pages
                            .map((e) => NavigationRailDestination(
                                  icon: Icon(e.icon(context)),
                                  label: Text(e.label(context)),
                                ))
                            .toList(),
                        selectedIndex: _selectedIndex,
                        onDestinationSelected: (i) =>
                            _onItemTapped(context, _pages[i], i),
                      ),
                    ),
                    Expanded(child: body),
                  ],
                );
              }

              return Scaffold(
                body: body,
                floatingActionButton:
                    _pages[_selectedIndex].floatingActionButton(context),
                bottomNavigationBar: useBottomNavigationBar
                    ? NavigationBar(
                        labelBehavior:
                            NavigationDestinationLabelBehavior.onlyShowSelected,
                        destinations: _pages
                            .where((e) => e.isActive(context))
                            .map((e) => NavigationDestination(
                                  icon: Icon(e.icon(context)),
                                  label: e.label(context),
                                ))
                            .toList(),
                        selectedIndex: _selectedIndex,
                        onDestinationSelected: (i) =>
                            _onItemTapped(context, _pages[i], i),
                      )
                    : null,
              );
            },
          );
        },
      ),
    );
  }
}
