import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/cubits/household_cubit.dart';
import 'package:kitchenowl/cubits/settings_cubit.dart';
import 'package:kitchenowl/enums/update_enum.dart';
import 'package:kitchenowl/helpers/build_context_extension.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/models/category.dart';
import 'package:kitchenowl/models/item.dart';
import 'package:kitchenowl/models/shoppinglist.dart';
import 'package:kitchenowl/models/update_value.dart';
import 'package:kitchenowl/pages/item_page.dart';
import 'package:kitchenowl/widgets/shopping_item.dart';

class SliverItemGridList<T extends Item> extends StatelessWidget {
  final void Function()? onRefresh;
  final Nullable<void Function(T)>? onPressed;
  final Nullable<void Function(T)>? onLongPressed;
  final List<T> items;
  final List<Category>? categories; // forwarded to item page on long press
  final ShoppingList? shoppingList; // forwarded to item page on long press
  final bool Function(T)? selected;
  final bool isLoading;
  final bool? isList;
  final bool? allRaised;
  final Widget Function(T)? extraOption;

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
    this.isList,
    this.allRaised,
    this.extraOption,
  });

  @override
  Widget build(BuildContext context) {
    final isList =
        this.isList ?? context.read<SettingsCubit>().state.shoppingListListView;

    if (!isLoading && items.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox(height: 0));
    }

    final delegate = SliverChildBuilderDelegate(
      childCount: items.length + (isLoading ? 1 : 0),
      (context, i) => i >= items.length
          ? ShimmerShoppingItemWidget(
              key: ValueKey(i),
              gridStyle: !isList,
            )
          : ShoppingItemWidget<T>(
              key: ObjectKey(items[i]),
              item: items[i],
              selected: selected?.call(items[i]) ?? false,
              gridStyle: !isList,
              onPressed:
                  (onPressed ?? Nullable((item) => openMenu(context, item)))
                      .value,
              raised: allRaised,
              onLongPressed:
                  (onLongPressed ?? Nullable((item) => openMenu(context, item)))
                      .value,
              extraOption: extraOption?.call(items[i]),
            ),
    );

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: !isList
          ? SliverLayoutBuilder(
              builder: (context, constraints) => SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: DynamicStyling.itemCrossAxisCount(
                    constraints.crossAxisExtent,
                    context.read<SettingsCubit>().state.gridSize,
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
    final res = await Navigator.of(context, rootNavigator: true)
        .push<UpdateValue<Item>>(
      MaterialPageRoute(builder: (ctx) {
        Widget page = ItemPage(
          item: item,
          shoppingList: shoppingList,
          categories: categories ?? const [],
        );
        final householdCubit = context.readOrNull<HouseholdCubit>();
        if (householdCubit != null)
          page = BlocProvider.value(
            value: householdCubit,
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
