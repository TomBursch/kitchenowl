import 'package:flutter/material.dart';
import 'package:kitchenowl/enums/update_enum.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/models/category.dart';
import 'package:kitchenowl/models/item.dart';
import 'package:kitchenowl/models/update_value.dart';
import 'package:kitchenowl/pages/item_page.dart';
import 'package:kitchenowl/widgets/shopping_item.dart';
import 'package:responsive_builder/responsive_builder.dart';

class SliverItemGridList<T extends Item> extends StatelessWidget {
  final void Function()? onRefresh;
  final void Function(T)? onPressed;
  final Nullable<void Function(T)>? onLongPressed;
  final List<T> items;
  final List<Category>? categories; // forwared to item page on long press
  final bool isList;
  final bool Function(T)? selected;
  final bool isLoading;
  final bool isDescriptionEditable;

  const SliverItemGridList({
    super.key,
    this.onRefresh,
    this.onPressed,
    this.onLongPressed,
    this.items = const [],
    this.categories,
    this.isList = false,
    this.selected,
    this.isLoading = false,
    this.isDescriptionEditable = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!isLoading && items.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox(height: 0));
    }

    final int crossAxisCount = getValueForScreenType<int>(
      context: context,
      mobile: 3,
      tablet: 6,
      desktop: 9,
    );

    final delegate = isLoading
        ? SliverChildBuilderDelegate(
            childCount: 1,
            (context, i) => ShimmerShoppingItemWidget(
              key: ValueKey(i),
              gridStyle: !isList,
            ),
          )
        : SliverChildBuilderDelegate(
            childCount: items.length,
            (context, i) => ShoppingItemWidget<T>(
              key: ObjectKey(items[i]),
              item: items[i],
              selected: selected?.call(items[i]) ?? false,
              gridStyle: !isList,
              onPressed: onPressed,
              onLongPressed: (onLongPressed ??
                      Nullable((Item item) async {
                        final res =
                            await Navigator.of(context).push<UpdateValue<Item>>(
                          MaterialPageRoute(
                            builder: (BuildContext context) => ItemPage(
                              item: item,
                              categories: categories ?? const [],
                              isDescriptionEditable: isDescriptionEditable,
                            ),
                          ),
                        );
                        if (onRefresh != null &&
                            res != null &&
                            (res.state == UpdateEnum.deleted ||
                                res.state == UpdateEnum.updated)) {
                          onRefresh!();
                        }
                      }))
                  .value,
            ),
          );

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: !isList
          ? SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                childAspectRatio: 1,
              ),
              delegate: delegate,
            )
          : SliverList(delegate: delegate),
    );
  }
}
