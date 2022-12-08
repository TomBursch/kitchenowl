import 'package:flutter/material.dart';
import 'package:kitchenowl/kitchenowl.dart';

enum ViewsEnum {
  shoppingList,
  recipes,
  mealPlanner,
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

  IconData toIcon() {
    return const [
      Icons.shopping_bag_outlined,
      Icons.receipt,
      Icons.calendar_today_rounded,
      Icons.account_balance_rounded,
      Icons.person,
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

  /// Adds all missing views
  static List<ViewsEnum> addMissing(Iterable<ViewsEnum> iterable) {
    final l = iterable.toList();
    l.addAll(ViewsEnum.values.where((e) => !iterable.contains(e)));

    return l;
  }

  static ViewsEnum? parse(String str) {
    switch (str) {
      case 'shoppingList':
        return ViewsEnum.shoppingList;
      case 'recipes':
        return ViewsEnum.recipes;
      case 'mealPlanner':
        return ViewsEnum.mealPlanner;
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
