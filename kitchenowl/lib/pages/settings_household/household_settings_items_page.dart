import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/cubits/household_add_update/household_settings_items_cubit.dart';
import 'package:kitchenowl/cubits/household_cubit.dart';
import 'package:kitchenowl/enums/shoppinglist_sorting.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/models/category.dart';
import 'package:kitchenowl/models/household.dart';
import 'package:kitchenowl/models/item.dart';
import 'package:kitchenowl/widgets/home_page/sliver_category_item_grid_list.dart';
import 'package:kitchenowl/widgets/item_popup_menu_button.dart';

class HouseholdSettingsItemsPage extends StatefulWidget {
  final Household household;

  const HouseholdSettingsItemsPage({
    super.key,
    required this.household,
  });

  @override
  State<HouseholdSettingsItemsPage> createState() =>
      _HouseholdSettingsItemsPageState();
}

class _HouseholdSettingsItemsPageState
    extends State<HouseholdSettingsItemsPage> {
  late HouseholdSettingsItemsCubit cubit;

  @override
  void initState() {
    super.initState();
    cubit = HouseholdSettingsItemsCubit(widget.household);
  }

  @override
  void dispose() {
    cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => HouseholdCubit(widget.household),
      child: Scaffold(
        body: BlocBuilder<HouseholdSettingsItemsCubit,
            HouseholdSettingsItemsState>(
          bloc: cubit,
          builder: (context, state) {
            dynamic body;

            if (state.sorting != ShoppinglistSorting.category ||
                state is LoadingHouseholdSettingsItemsState &&
                    state.items.isEmpty) {
              body = SliverItemGridList(
                isLoading: state is LoadingHouseholdSettingsItemsState,
                items: state.items,
                categories: state.categories,
                onRefresh: cubit.refresh,
                allRaised: true,
                extraOption: _itemPopmenuBuilder,
              );
            } else {
              List<Widget> grids = [];
              // add items from categories
              for (int i = 0; i < state.categories.length + 1; i++) {
                Category? category =
                    i < state.categories.length ? state.categories[i] : null;
                final List<Item> items =
                    state.items.where((e) => e.category == category).toList();
                if (items.isEmpty) continue;

                grids.add(SliverCategoryItemGridList(
                  name: category?.name ??
                      AppLocalizations.of(context)!.uncategorized,
                  isLoading: state is LoadingHouseholdSettingsItemsState,
                  categories: state.categories,
                  onRefresh: cubit.refresh,
                  allRaised: true,
                  items: items,
                  extraOption: _itemPopmenuBuilder,
                ));
              }
              body = grids;
            }

            return CustomScrollView(
              slivers: [
                SliverAppBar(
                  title: Text(AppLocalizations.of(context)!.items),
                  floating: true,
                ),
                SliverToBoxAdapter(
                  child: LeftRightWrap(
                    left: const SizedBox(),
                    right: Padding(
                      padding: const EdgeInsets.only(right: 16, bottom: 6),
                      child: TrailingIconTextButton(
                        onPressed: cubit.incrementSorting,
                        text: state.sorting == ShoppinglistSorting.alphabetical
                            ? AppLocalizations.of(context)!.sortingAlphabetical
                            : state.sorting == ShoppinglistSorting.algorithmic
                                ? AppLocalizations.of(context)!
                                    .sortingAlgorithmic
                                : AppLocalizations.of(context)!.category,
                        icon: const Icon(Icons.sort),
                      ),
                    ),
                  ),
                ),
                if (body is List) ...body,
                if (body is! List) body,
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _itemPopmenuBuilder(Item item) => ItemPopupMenuButton(
        item: item,
        household: widget.household,
        setIcon: (icon) => cubit.setIcon(item, icon),
        setName: (name) => cubit.setName(item, name),
        mergeItem: (other) => cubit.mergeItem(item, other),
        deleteItem: () => cubit.deleteItem(item),
      );
}
