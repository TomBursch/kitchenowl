import 'package:flutter/material.dart';
import 'package:kitchenowl/app.dart';
import 'package:kitchenowl/enums/shoppinglist_sorting.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/models/category.dart';
import 'package:kitchenowl/models/item.dart';
import 'package:kitchenowl/models/shoppinglist.dart';
import 'package:kitchenowl/widgets/home_page/sliver_category_item_grid_list.dart';

class SliverShopinglistItemView extends StatelessWidget {
  final ShoppingList? shoppingList;
  final List<Category> categories;
  final void Function()? onRefresh;
  final Nullable<void Function(ShoppinglistItem)>? onPressed;

  /// When set and the list is rendered as a list (not grid), each shopping
  /// list item row shows a leading checkbox; tapping it invokes this
  /// callback (typically removing the item from the list).
  final Nullable<void Function(ShoppinglistItem)>? onCheckboxPressed;
  final Nullable<void Function(ItemWithDescription)>? onRecentPressed;
  final ShoppinglistSorting sorting;
  final bool isLoading;
  final List<ShoppinglistItem> selectedListItems;
  final ShoppingListStyle shoppingListStyle;

  const SliverShopinglistItemView({
    super.key,
    this.shoppingList,
    required this.categories,
    this.onRefresh,
    this.onPressed,
    this.onCheckboxPressed,
    this.onRecentPressed,
    required this.sorting,
    required this.isLoading,
    required this.selectedListItems,
    this.shoppingListStyle = const ShoppingListStyle(),
  });

  @override
  Widget build(BuildContext context) {
    dynamic main;
    if (sorting != ShoppinglistSorting.category ||
        isLoading && (shoppingList?.items.isEmpty ?? false)) {
      main = SliverItemGridList<ShoppinglistItem>(
        items: shoppingList?.items ?? [],
        categories: categories,
        shoppingList: shoppingList,
        selected: (item) =>
            App.settings.shoppingListTapToRemove &&
                !App.settings.shoppingListListView ||
            !App.settings.shoppingListTapToRemove &&
                App.settings.shoppingListListView ^
                    !selectedListItems.contains(item),
        isLoading: isLoading,
        onRefresh: onRefresh,
        onPressed: onPressed,
        onCheckboxPressed: onCheckboxPressed,
        shoppingListStyle: shoppingListStyle,
      );
    } else {
      List<Widget> grids = [];
      // add items from categories
      for (int i = 0; i < categories.length + 1; i++) {
        Category? category = i < categories.length ? categories[i] : null;
        final List<ShoppinglistItem> items =
            shoppingList?.items.where((e) => e.category == category).toList() ??
                [];
        if (items.isEmpty) continue;

        grids.add(SliverCategoryItemGridList<ShoppinglistItem>(
          name: category?.name ?? AppLocalizations.of(context)!.uncategorized,
          items: items,
          categories: categories,
          shoppingList: shoppingList,
          selected: (item) =>
              App.settings.shoppingListTapToRemove &&
                  !App.settings.shoppingListListView ||
              !App.settings.shoppingListTapToRemove &&
                  App.settings.shoppingListListView ^
                      !selectedListItems.contains(item),
          isLoading: isLoading,
          onRefresh: onRefresh,
          onPressed: onPressed,
          onCheckboxPressed: onCheckboxPressed,
          shoppingListStyle: shoppingListStyle,
        ));
      }
      main = grids;
    }
    return SliverMainAxisGroup(slivers: [
      if (main is List) ...main,
      if (main is! List) main,
      if (((shoppingList?.recentItems.isNotEmpty ?? false) &&
              (App.settings.recentItemsCount > 0)) ||
          isLoading)
        SliverCategoryItemGridList<ItemWithDescription>(
          name: '${AppLocalizations.of(context)!.itemsRecent}:',
          items: shoppingList?.recentItems
                  .take(App.settings.recentItemsCount)
                  .toList() ??
              [],
          onPressed: onRecentPressed,
          categories: categories,
          shoppingList: shoppingList,
          onRefresh: onRefresh,
          isLoading: isLoading,
          shoppingListStyle: shoppingListStyle,
          splitByCategories: App.settings.recentItemsCategorize &&
              !(sorting != ShoppinglistSorting.category ||
                  isLoading && (shoppingList?.items.isEmpty ?? false)),
        ),
    ]);
  }
}
