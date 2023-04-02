import 'package:flutter/material.dart';
import 'package:kitchenowl/app.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/models/household.dart';
import 'package:kitchenowl/widgets/expense_create_fab.dart';
import 'package:kitchenowl/widgets/recipe_create_fab.dart';

enum ViewsEnum {
  items,
  recipes,
  planner,
  balances,
  profile;

  String toLocalizedString(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return [
      loc.shoppingList,
      loc.recipes,
      loc.mealPlanner,
      loc.balances,
      loc.profile,
    ][index];
  }

  IconData toIcon(BuildContext context) {
    return [
      Icons.shopping_bag_outlined,
      Icons.receipt,
      Icons.calendar_today_rounded,
      Icons.account_balance_rounded,
      App.isOffline ? Icons.cloud_off_rounded : Icons.person,
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
        return !App.isOffline ? RecipeCreateFab() : null;
      case ViewsEnum.balances:
        return !App.isOffline ? const ExpenseCreateFab() : null;
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
        return ViewsEnum.profile;
      default:
        return null;
    }
  }

  @override
  String toString() {
    return name;
  }
}
