import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/cubits/household_cubit.dart';
import 'package:kitchenowl/cubits/shoppinglist_cubit.dart';
import 'package:kitchenowl/enums/update_enum.dart';
import 'package:kitchenowl/helpers/build_context_extension.dart';
import 'package:kitchenowl/helpers/url_launcher.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/models/category.dart';
import 'package:kitchenowl/models/item.dart';
import 'package:kitchenowl/models/shoppinglist.dart';
import 'package:kitchenowl/models/update_value.dart';
import 'package:kitchenowl/pages/item_page.dart';
import 'package:kitchenowl/widgets/shopping_item.dart';

/// A Sliver Grid or List depending on the shopping list style
class SliverItemGridList<T extends Item> extends StatelessWidget {
  final void Function()? onRefresh;
  final Nullable<void Function(T)>? onPressed;
  final Nullable<void Function(T)>? onLongPressed;
  final List<T> items;
  final List<Category>? categories; // forwarded to item page on long press
  final ShoppingList? shoppingList; // forwarded to item page on long press
  final bool Function(T)? selected;
  final bool isLoading;
  final Widget Function(T)? extraOption;
  final ShoppingListStyle shoppingListStyle;

  const SliverItemGridList({
    super.key,
    this.onRefresh,
    this.onPressed,
    this.onLongPressed,
    this.items = const [],
    this.categories,
    this.shoppingList,
    this.selected,
    this.isLoading = false,
    this.extraOption,
    this.shoppingListStyle = const ShoppingListStyle(),
  });

  @override
  Widget build(BuildContext context) {
    if (!isLoading && items.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox(height: 0));
    }

    final delegate = SliverChildBuilderDelegate(
      childCount: items.length + (isLoading ? 1 : 0),
      (context, i) => i >= items.length
          ? ShimmerShoppingItemWidget(
              key: ValueKey(i),
              gridStyle: !shoppingListStyle.isList,
            )
          : ShoppingItemWidget<T>(
              key: ObjectKey(items[i]),
              item: items[i],
              selected: selected?.call(items[i]) ?? false,
              gridStyle: !shoppingListStyle.isList,
              listStyle: shoppingListStyle.listStyle,
              onPressed:
                  (onPressed ?? Nullable((item) => openMenu(context, item)))
                      .value,
              raised: shoppingListStyle.allRaised,
              onLongPressed:
                  (onLongPressed ?? Nullable((item) => openMenu(context, item)))
                      .value,
              extraOption: extraOption?.call(items[i]),
            ),
    );

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: !shoppingListStyle.isList
          ? SliverLayoutBuilder(
              builder: (context, constraints) => SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: DynamicStyling.itemCrossAxisCount(
                    constraints.crossAxisExtent,
                    shoppingListStyle.gridSize,
                  ),
                  childAspectRatio: 1,
                ),
                delegate: delegate,
              ),
            )
          : SliverList(delegate: delegate),
    );
  }

  Future<void> openMenu(BuildContext context, Item item) async {
    final url =
        item is ItemWithDescription ? extractSingleUrl(item.description) : null;
    if (url == null) return _openItemPage(context, item);

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      useRootNavigator: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: Text(AppLocalizations.of(ctx)!.edit),
              onTap: () {
                Navigator.of(ctx).pop();
                _openItemPage(context, item);
              },
            ),
            ListTile(
              leading: const Icon(Icons.open_in_new_rounded),
              title: Text(AppLocalizations.of(ctx)!.openUrl),
              onTap: () {
                Navigator.of(ctx).pop();
                openUrl(context, url);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _openItemPage(BuildContext context, Item item) async {
    final res = await Navigator.of(context, rootNavigator: true)
        .push<UpdateValue<Item>>(
      MaterialPageRoute(builder: (ctx) {
        Widget page = ItemPage(
          item: item,
          shoppingList: shoppingList,
          categories: categories ?? const [],
          advancedView: shoppingListStyle.advancedItemView,
        );
        final householdCubit = context.readOrNull<HouseholdCubit>();
        if (householdCubit != null)
          page = BlocProvider.value(
            value: householdCubit,
            child: page,
          );

        final shoppinglistCubit = context.readOrNull<ShoppinglistCubit>();
        if (shoppinglistCubit != null)
          page = BlocProvider.value(
            value: shoppinglistCubit,
            child: page,
          );
        return page;
      }),
    );
    if (onRefresh != null &&
        res != null &&
        (res.state == UpdateEnum.deleted || res.state == UpdateEnum.updated)) {
      onRefresh!();
    }
  }
}
