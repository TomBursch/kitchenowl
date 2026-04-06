import 'package:animations/animations.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/app.dart';
import 'package:kitchenowl/cubits/settings_cubit.dart';
import 'package:kitchenowl/cubits/inventory_cubit.dart';
import 'package:kitchenowl/enums/inventory_sorting.dart';
import 'package:kitchenowl/models/item.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/widgets/choice_scroll.dart';
import 'package:kitchenowl/widgets/shopping_list/shopping_list_choice_chip.dart';
import 'package:kitchenowl/widgets/shopping_list/sliver_shopinglist_item_view.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

  @override
  _InventoryPageState createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    searchController.text = BlocProvider.of<InventoryCubit>(context).query;
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = BlocProvider.of<InventoryCubit>(context);

    return SafeArea(
      child: Column(
        children: [
          SizedBox(
            height: 70,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
              child: BlocListener<InventoryCubit, InventoryCubitState>(
                bloc: cubit,
                listener: (context, state) {
                  if (state is! SearchInventoryCubitState &&
                      state is! LoadingInventoryCubitState) {
                    if (searchController.text.isNotEmpty) {
                      searchController.clear();
                    }
                  }
                },
                child: SearchTextField(
                  controller: searchController,
                  onSearch: (s) => cubit.search(s),
                  onSubmitted: () {
                    final state = cubit.state;
                    if (state is SearchInventoryCubitState) {
                      if (state.result.first is! InventoryItem) {
                        cubit.add(state.result.first);
                      }
                    } else {
                      cubit.search(searchController.text);
                    }
                  },
                ),
              ),
            ),
          ),
          Expanded(
            child: BlocBuilder<InventoryCubit, InventoryCubitState>(
              bloc: cubit,
              builder: (context, state) {
                final header = LeftRightWrap(
                  left: (state.inventories.length < 2)
                      ? const SizedBox()
                      // : ChoiceScroll(
                      //     children: state.inventories.values
                      //         .sorted((a, b) =>
                      //             b.items.length.compareTo(a.items.length))
                      //         .map(
                      //           (inventory) => ShoppingListChoiceChip(
                      //             shoppingList: inventory,
                      //             selected:
                      //                 inventory.id == state.selectedInventoryId,
                      //             onSelected: (bool selected) {
                      //               if (selected) {
                      //                 cubit.setInventory(
                      //                   inventory,
                      //                 );
                      //               }
                      //             },
                      //           ),
                      //         )
                      //         .toList(),
                      //   ),
                      : const SizedBox(),
                  right: Padding(
                    padding: const EdgeInsets.only(right: 16, bottom: 6),
                    child: TrailingIconTextButton(
                      onPressed: cubit.incrementSorting,
                      text: state.sorting == InventorySorting.alphabetical
                          ? AppLocalizations.of(context)!.sortingAlphabetical
                          : state.sorting == InventorySorting.algorithmic
                              ? AppLocalizations.of(context)!.sortingAlgorithmic
                              : AppLocalizations.of(context)!.category,
                      icon: const Icon(Icons.sort),
                    ),
                  ),
                );

                if (state is! SearchInventoryCubitState &&
                    state is! LoadingInventoryCubitState &&
                    (state.selectedInventory?.items.isEmpty ?? true) &&
                    ((state.selectedInventory?.recentItems.isEmpty ?? true) ||
                        (App.settings.recentItemsCount == 0))) {
                  return Column(
                    children: [
                      header,
                      const Spacer(),
                      const Icon(Icons.remove_shopping_cart_rounded),
                      const SizedBox(height: 16),
                      Text(
                        AppLocalizations.of(context)!.shoppingListEmpty,
                        textAlign: TextAlign.center,
                      ),
                      const Spacer(),
                    ],
                  );
                }
                return BlocBuilder<SettingsCubit, SettingsState>(
                  buildWhen: (previous, current) =>
                      previous.shoppingListListView !=
                          current.shoppingListListView ||
                      previous.listStyle != current.listStyle ||
                      previous.gridSize != current.gridSize,
                  builder: (context, settingsState) => PageTransitionSwitcher(
                    transitionBuilder: (
                      Widget child,
                      Animation<double> animation,
                      Animation<double> secondaryAnimation,
                    ) {
                      return SharedAxisTransition(
                        animation: animation,
                        secondaryAnimation: secondaryAnimation,
                        transitionType: SharedAxisTransitionType.vertical,
                        child: child,
                      );
                    },
                    child: (state is SearchInventoryCubitState)
                        ? RefreshIndicator(
                            onRefresh: cubit.refresh,
                            child: CustomScrollView(
                              primary: true,
                              slivers: [
                                // SliverItemGridList(
                                //   shoppingListStyle: ShoppingListStyle(
                                //     listStyle: settingsState.listStyle,
                                //     isList: settingsState.shoppingListListView,
                                //     gridSize: settingsState.gridSize,
                                //   ),
                                //   items: state.result,
                                //   categories: state.categories,
                                //   inventory: state.selectedInventory,
                                //   onRefresh: () => cubit.refresh(),
                                //   selected: (item) =>
                                //       item is InventoryItem &&
                                //       (App.settings.shoppingListTapToRemove ||
                                //           !state.selectedListItems
                                //               .contains(item)),
                                //   isLoading:
                                //       state is LoadingInventoryCubitState,
                                //   onPressed: Nullable((Item item) {
                                //     if (item is InventoryItem) {
                                //       if (App
                                //           .settings.shoppingListTapToRemove) {
                                //         cubit.remove(item);
                                //       } else {
                                //         cubit.selectItem(item);
                                //       }
                                //     } else {
                                //       cubit.add(item);
                                //     }
                                //   }),
                                // ),
                              ],
                            ),
                          )
                        : NestedScrollView(
                            headerSliverBuilder:
                                (context, innerBoxIsScrolled) => [
                              SliverToBoxAdapter(child: header),
                            ],
                            body: RefreshIndicator(
                              onRefresh: cubit.refresh,
                              displacement: 0,
                              child: PageTransitionSwitcher(
                                transitionBuilder: (
                                  Widget child,
                                  Animation<double> animation,
                                  Animation<double> secondaryAnimation,
                                ) {
                                  return SharedAxisTransition(
                                    animation: animation,
                                    secondaryAnimation: secondaryAnimation,
                                    transitionType:
                                        SharedAxisTransitionType.vertical,
                                    child: child,
                                  );
                                },
                                child: CustomScrollView(
                                  key: PageStorageKey<int?>(
                                      state.selectedInventoryId),
                                  slivers: [
                                    // SliverShopinglistItemView(
                                    //   shoppingListStyle: ShoppingListStyle(
                                    //     listStyle: settingsState.listStyle,
                                    //     isList:
                                    //         settingsState.shoppingListListView,
                                    //     gridSize: settingsState.gridSize,
                                    //   ),
                                    //   categories: state.categories,
                                    //   isLoading:
                                    //       state is LoadingInventoryCubitState,
                                    //   selectedListItems:
                                    //       state.selectedListItems,
                                    //   sorting: state.sorting,
                                    //   inventory: state.selectedInventory,
                                    //   onPressed: Nullable((Item item) {
                                    //     if (item is InventoryItem) {
                                    //       if (App.settings
                                    //           .shoppingListTapToRemove) {
                                    //         cubit.remove(item);
                                    //       } else {
                                    //         cubit.selectItem(item);
                                    //       }
                                    //     } else {
                                    //       cubit.add(item);
                                    //     }
                                    //   }),
                                    //   onRecentPressed: Nullable(cubit.add),
                                    //   onRefresh: cubit.refresh,
                                    // ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
