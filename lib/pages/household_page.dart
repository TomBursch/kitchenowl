import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:kitchenowl/cubits/auth_cubit.dart';
import 'package:kitchenowl/cubits/expense_list_cubit.dart';
import 'package:kitchenowl/cubits/planner_cubit.dart';
import 'package:kitchenowl/cubits/recipe_list_cubit.dart';
import 'package:kitchenowl/cubits/shoppinglist_cubit.dart';
import 'package:kitchenowl/enums/views_enum.dart';
import 'package:kitchenowl/models/household.dart';
import 'package:responsive_builder/responsive_builder.dart';

class HouseholdPage extends StatefulWidget {
  final Household household;
  final Widget child;
  const HouseholdPage({
    super.key,
    required this.household,
    required this.child,
  });

  @override
  _HouseholdPageState createState() => _HouseholdPageState();
}

class _HouseholdPageState extends State<HouseholdPage> {
  static const int _bottomAppBarSize = 5;

  late final ShoppinglistCubit shoppingListCubit;
  late final RecipeListCubit recipeListCubit;
  late final PlannerCubit plannerCubit;
  late final ExpenseListCubit expenseCubit;

  @override
  void initState() {
    super.initState();
    shoppingListCubit = ShoppinglistCubit(widget.household);
    recipeListCubit = RecipeListCubit(widget.household);
    plannerCubit = PlannerCubit(widget.household);
    expenseCubit = ExpenseListCubit(widget.household);
  }

  @override
  void dispose() {
    shoppingListCubit.close();
    recipeListCubit.close();
    plannerCubit.close();
    expenseCubit.close();
    super.dispose();
  }

  void _onItemTapped(BuildContext context, ViewsEnum page) {
    context.go("/household/${widget.household.id}/${page.toString()}");
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
          List<ViewsEnum> pages = ViewsEnum.values;
          int _selectedIndex = pages.indexWhere(
            (e) => GoRouter.of(context).location.contains(e.toString()),
          );

          final bool useBottomNavigationBar = getValueForScreenType<bool>(
            context: context,
            mobile: true,
            tablet: false,
            desktop: false,
          );

          Widget body = Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints.expand(width: 1600),
              child: widget.child,
            ),
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
                    destinations: pages
                        .map((e) => NavigationRailDestination(
                              icon: Icon(e.toIcon(context)),
                              label: Text(e.toLocalizedString(context)),
                            ))
                        .toList(),
                    selectedIndex: _selectedIndex,
                    onDestinationSelected: (i) =>
                        _onItemTapped(context, pages[i]),
                  ),
                ),
                Expanded(child: body),
              ],
            );
          }

          return Scaffold(
            body: body,
            floatingActionButton:
                pages[_selectedIndex].floatingActionButton(context),
            bottomNavigationBar: useBottomNavigationBar
                ? NavigationBar(
                    labelBehavior:
                        NavigationDestinationLabelBehavior.onlyShowSelected,
                    destinations: pages
                        .map((e) => NavigationDestination(
                              icon: Icon(e.toIcon(context)),
                              label: e.toLocalizedString(context),
                            ))
                        .toList(),
                    selectedIndex: 0,
                    onDestinationSelected: (i) =>
                        _onItemTapped(context, pages[i]),
                  )
                : null,
          );
        },
      ),
    );
  }
}
