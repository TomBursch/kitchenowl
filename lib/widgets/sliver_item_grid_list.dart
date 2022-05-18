import 'package:flutter/material.dart';
import 'package:kitchenowl/enums/update_enum.dart';
import 'package:kitchenowl/models/category.dart';
import 'package:kitchenowl/models/item.dart';
import 'package:kitchenowl/models/update_value.dart';
import 'package:kitchenowl/pages/item_page.dart';
import 'package:kitchenowl/widgets/shopping_item.dart';
import 'package:responsive_builder/responsive_builder.dart';

class SliverItemGridList extends StatelessWidget {
  final void Function()? onRefresh;
  final void Function(Item)? onPressed;
  final void Function(Item)? onLongPressed;
  final List<Item> items;
  final List<Category>? categories; // forwared to item page on long press
  final bool isList;
  final bool Function(Item)? selected;

  const SliverItemGridList({
    Key? key,
    this.onRefresh,
    this.onPressed,
    this.onLongPressed,
    this.items = const [],
    this.categories,
    this.isList = false,
    this.selected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final int crossAxisCount = getValueForScreenType<int>(
      context: context,
      mobile: 3,
      tablet: 6,
      desktop: 9,
    );

    final delegate = SliverChildBuilderDelegate(
      childCount: items.length,
      (context, i) => ShoppingItemWidget(
        key: ObjectKey(items[i]),
        item: items[i],
        selected: selected?.call(items[i]) ?? false,
        onPressed: onPressed,
        onLongPressed: onLongPressed ??
            (Item item) async {
              final res = await Navigator.of(context).push<UpdateValue<Item>>(
                MaterialPageRoute(
                  builder: (BuildContext context) => ItemPage(
                    item: item,
                    categories: categories ?? const [],
                  ),
                ),
              );
              if (onRefresh != null &&
                  res != null &&
                  (res.state == UpdateEnum.deleted ||
                      res.state == UpdateEnum.updated)) {
                onRefresh!();
              }
            },
      ),
    );

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: !isList
          ? SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
                childAspectRatio: 1,
              ),
              delegate: delegate,
            )
          : SliverList(delegate: delegate),
    );
  }
}
