import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/cubits/household_cubit.dart';
import 'package:kitchenowl/enums/update_enum.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/models/category.dart';
import 'package:kitchenowl/models/household.dart';
import 'package:kitchenowl/models/item.dart';
import 'package:kitchenowl/models/shoppinglist.dart';
import 'package:kitchenowl/models/update_value.dart';
import 'package:kitchenowl/pages/item_page.dart';
import 'package:kitchenowl/widgets/shopping_item.dart';

class SliverItemGridList<T extends Item> extends StatelessWidget {
  final void Function()? onRefresh;
  final void Function(T)? onPressed;
  final Nullable<void Function(T)>? onLongPressed;
  final List<T> items;
  final List<Category>? categories; // forwarded to item page on long press
  final ShoppingList? shoppingList; // forwarded to item page on long press
  final Household?
      household; // forwarded to item page on long press for offline functionality
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
    this.household,
    this.shoppingList,
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
            (context, i) => SizedBox(
              child: ShoppingItemWidget<T>(
                key: ObjectKey(items[i]),
                item: items[i],
                selected: selected?.call(items[i]) ?? false,
                gridStyle: !isList,
                onPressed: onPressed,
                onLongPressed: (onLongPressed ??
                        Nullable((Item item) async {
                          final res =
                              await Navigator.of(context, rootNavigator: true)
                                  .push<UpdateValue<Item>>(
                            MaterialPageRoute(
                              builder: (ctx) => BlocProvider.value(
                                value: BlocProvider.of<HouseholdCubit>(context),
                                child: ItemPage(
                                  item: item,
                                  household: household,
                                  shoppingList: shoppingList,
                                  categories: categories ?? const [],
                                  isDescriptionEditable: isDescriptionEditable,
                                ),
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
            ),
          );

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: !isList
          ? SliverLayoutBuilder(
              builder: (context, constraints) => SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount:
                      (constraints.crossAxisExtent ~/ 115).clamp(1, 9),
                  childAspectRatio: 1,
                ),
                delegate: delegate,
              ),
            )
          : SliverList(delegate: delegate),
    );
  }
}
