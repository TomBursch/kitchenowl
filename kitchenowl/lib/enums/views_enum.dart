import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/app.dart';
import 'package:kitchenowl/cubits/auth_cubit.dart';
import 'package:kitchenowl/cubits/household_cubit.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/models/household.dart';
import 'package:kitchenowl/widgets/expense_create_fab.dart';
import 'package:kitchenowl/widgets/recipe_create_fab.dart';
import 'package:kitchenowl/widgets/shopping_list_fab.dart';

// Note: loyaltyCards is not a navigation view - accessed via FAB on shopping list page
enum ViewsEnum {
  items,
  recipes,
  planner,
  balances,
  more;

  String toLocalizedString(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return [
      loc.shoppingList,
      loc.recipes,
      loc.mealPlanner,
      loc.balances,
      loc.more,
    ][index];
  }

  String toLocalizedShortString(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return [
      loc.list,
      loc.recipes,
      loc.planner,
      loc.balances,
      loc.more,
    ][index];
  }

  Widget? toIconWidget(BuildContext context) {
    if (this == ViewsEnum.more) {
      Household? household = context.read<HouseholdCubit>().state.household;
      if (!App.isOffline && household.image != null)
        return CircleAvatar(
          radius: 16,
          foregroundImage: getImageProvider(
            context,
            household.image!,
          ),
        );
    }
    return null;
  }

  IconData toIcon(BuildContext context) {
    return [
      Icons.shopping_bag_outlined,
      Icons.receipt_outlined,
      Icons.calendar_today_outlined,
      Icons.account_balance_outlined,
      App.isOffline ? Icons.cloud_off_rounded : Icons.house_rounded,
    ][index];
  }

  IconData toSelectedIcon(BuildContext context) {
    return [
      Icons.shopping_bag_rounded,
      Icons.receipt_rounded,
      Icons.calendar_today_rounded,
      Icons.account_balance_rounded,
      App.isOffline ? Icons.cloud_off_rounded : Icons.house_rounded,
    ][index];
  }

  bool isOptional() {
    return const [
      false,
      false,
      true,
      true,
      false,
    ][index];
  }

  Widget? floatingActionButton(BuildContext context) {
    switch (this) {
      case ViewsEnum.recipes:
        return !BlocProvider.of<AuthCubit>(context, listen: true)
                .state
                .isOffline
            ? RecipeCreateFab()
            : null;
      case ViewsEnum.balances:
        return !BlocProvider.of<AuthCubit>(context, listen: true)
                .state
                .isOffline
            ? const ExpenseCreateFab()
            : null;
      case ViewsEnum.items:
        return const ShoppingListFab();
      default:
        return null;
    }
  }

  bool isViewActive(Household household) {
    if (this == ViewsEnum.planner) {
      return household.featurePlanner ?? true;
    }
    if (this == ViewsEnum.balances) {
      return household.featureExpenses ?? true;
    }

    return true;
  }

  /// Adds all missing views
  static List<ViewsEnum> addMissing(Iterable<ViewsEnum> iterable) {
    final l = iterable.toList();
    l.addAll(ViewsEnum.values.where((e) => !iterable.contains(e)));

    return l;
  }

  static ViewsEnum? parse(String str) {
    switch (str) {
      case 'items':
        return ViewsEnum.items;
      case 'recipes':
        return ViewsEnum.recipes;
      case 'planner':
        return ViewsEnum.planner;
      case 'balances':
        return ViewsEnum.balances;
      case 'profile':
      case 'more':
        return ViewsEnum.more;
      default:
        return null;
    }
  }

  String toRouteName() {
    return name;
  }

  @override
  String toString() {
    return name;
  }
}
