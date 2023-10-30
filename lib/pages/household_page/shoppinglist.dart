import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/app.dart';
import 'package:kitchenowl/cubits/household_cubit.dart';
import 'package:kitchenowl/cubits/shoppinglist_cubit.dart';
import 'package:kitchenowl/enums/shoppinglist_sorting.dart';
import 'package:kitchenowl/models/category.dart';
import 'package:kitchenowl/models/item.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/widgets/choice_scroll.dart';
import 'package:kitchenowl/widgets/home_page/sliver_category_item_grid_list.dart';

class ShoppinglistPage extends StatefulWidget {
  const ShoppinglistPage({super.key});

  @override
  _ShoppinglistPageState createState() => _ShoppinglistPageState();
}

class _ShoppinglistPageState extends State<ShoppinglistPage> {
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    searchController.text = BlocProvider.of<ShoppinglistCubit>(context).query;
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = BlocProvider.of<ShoppinglistCubit>(context);

    return SafeArea(
      child: Column(
        children: [
          SizedBox(
            height: 70,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
              child: BlocListener<ShoppinglistCubit, ShoppinglistCubitState>(
                bloc: cubit,
                listener: (context, state) {
                  if (state is! SearchShoppinglistCubitState &&
                      state is! LoadingShoppinglistCubitState) {
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
                    if (state is SearchShoppinglistCubitState) {
                      if (state.result.first is! ShoppinglistItem) {
                        cubit.add(state.result.first);
                      }
                    }
                  },
                ),
              ),
            ),
          ),
          Expanded(
            child: Scrollbar(
              child: RefreshIndicator(
                onRefresh: cubit.refresh,
                child: BlocBuilder<ShoppinglistCubit, ShoppinglistCubitState>(
                  bloc: cubit,
                  builder: (context, state) {
                    if (state is SearchShoppinglistCubitState) {
                      return CustomScrollView(
                        primary: true,
                        slivers: [
                          SliverItemGridList(
                            items: state.result,
                            categories: state.categories,
                            shoppingList: state.selectedShoppinglist,
                            household: BlocProvider.of<HouseholdCubit>(context)
                                .state
                                .household,
                            onRefresh: cubit.refresh,
                            selected: (item) =>
                                item is ShoppinglistItem &&
                                (App.settings.shoppingListTapToRemove ||
                                    !state.selectedListItems.contains(item)),
                            isLoading: state is LoadingShoppinglistCubitState,
                            onPressed: (Item item) {
                              if (item is ShoppinglistItem) {
                                if (App.settings.shoppingListTapToRemove) {
                                  cubit.remove(item);
                                } else {
                                  cubit.selectItem(item);
                                }
                              } else {
                                cubit.add(item);
                              }
                            },
                          ),
                        ],
                      );
                    }

                    dynamic body;

                    if (state.sorting != ShoppinglistSorting.category ||
                        state is LoadingShoppinglistCubitState &&
                            state.listItems.isEmpty) {
                      body = SliverItemGridList(
                        items: state.listItems,
                        categories: state.categories,
                        shoppingList: state.selectedShoppinglist,
                        household: BlocProvider.of<HouseholdCubit>(context)
                            .state
                            .household,
                        selected: (item) =>
                            App.settings.shoppingListTapToRemove &&
                                !App.settings.shoppingListListView ||
                            !App.settings.shoppingListTapToRemove &&
                                App.settings.shoppingListListView ^
                                    !state.selectedListItems.contains(item),
                        isLoading: state is LoadingShoppinglistCubitState,
                        onRefresh: cubit.refresh,
                        onPressed: (Item item) {
                          if (item is ShoppinglistItem) {
                            if (App.settings.shoppingListTapToRemove) {
                              cubit.remove(item);
                            } else {
                              cubit.selectItem(item);
                            }
                          } else {
                            cubit.add(item);
                          }
                        },
                      );
                    } else {
                      List<Widget> grids = [];
                      // add items from categories
                      for (int i = 0; i < state.categories.length + 1; i++) {
                        Category? category = i < state.categories.length
                            ? state.categories[i]
                            : null;
                        final List<ShoppinglistItem> items = state.listItems
                            .where((e) => e.category == category)
                            .toList();
                        if (items.isEmpty) continue;

                        grids.add(SliverCategoryItemGridList(
                          name: category?.name ??
                              AppLocalizations.of(context)!.uncategorized,
                          items: items,
                          categories: state.categories,
                          shoppingList: state.selectedShoppinglist,
                          selected: (item) =>
                              App.settings.shoppingListTapToRemove &&
                                  !App.settings.shoppingListListView ||
                              !App.settings.shoppingListTapToRemove &&
                                  App.settings.shoppingListListView ^
                                      !state.selectedListItems.contains(item),
                          isLoading: state is LoadingShoppinglistCubitState,
                          onRefresh: cubit.refresh,
                          onPressed: (Item item) {
                            if (item is ShoppinglistItem) {
                              if (App.settings.shoppingListTapToRemove) {
                                cubit.remove(item);
                              } else {
                                cubit.selectItem(item);
                              }
                            } else {
                              cubit.add(item);
                            }
                          },
                        ));
                      }
                      body = grids;
                    }

                    return CustomScrollView(
                      primary: true,
                      slivers: [
                        SliverToBoxAdapter(
                          child: LeftRightWrap(
                            left: (state.shoppinglists.length < 2)
                                ? const SizedBox()
                                : ChoiceScroll(
                                    children:
                                        state.shoppinglists.map((shoppinglist) {
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 4,
                                        ),
                                        child: ChoiceChip(
                                          showCheckmark: false,
                                          label: Text(
                                            shoppinglist.name,
                                            style: TextStyle(
                                              color: shoppinglist.id ==
                                                      state
                                                          .selectedShoppinglist!
                                                          .id
                                                  ? Theme.of(context)
                                                      .colorScheme
                                                      .onPrimary
                                                  : null,
                                            ),
                                          ),
                                          selected: shoppinglist.id ==
                                              state.selectedShoppinglist!.id,
                                          selectedColor: Theme.of(context)
                                              .colorScheme
                                              .secondary,
                                          onSelected: (bool selected) {
                                            if (selected) {
                                              cubit.setShoppingList(
                                                shoppinglist,
                                              );
                                            }
                                          },
                                        ),
                                      );
                                    }).toList(),
                                  ),
                            right: Padding(
                              padding:
                                  const EdgeInsets.only(right: 16, bottom: 6),
                              child: TrailingIconTextButton(
                                onPressed: cubit.incrementSorting,
                                text: state.sorting ==
                                        ShoppinglistSorting.alphabetical
                                    ? AppLocalizations.of(context)!
                                        .sortingAlphabetical
                                    : state.sorting ==
                                            ShoppinglistSorting.algorithmic
                                        ? AppLocalizations.of(context)!
                                            .sortingAlgorithmic
                                        : AppLocalizations.of(context)!
                                            .category,
                                icon: const Icon(Icons.sort),
                              ),
                            ),
                          ),
                        ),
                        if (body is List) ...body,
                        if (body is! List) body,
                        if ((state.recentItems.isNotEmpty ||
                            state is LoadingShoppinglistCubitState))
                          SliverCategoryItemGridList(
                            name:
                                '${AppLocalizations.of(context)!.itemsRecent}:',
                            items: state.recentItems,
                            onPressed: cubit.add,
                            categories: state.categories,
                            shoppingList: state.selectedShoppinglist,
                            onRefresh: cubit.refresh,
                            isDescriptionEditable: false,
                            isLoading: state is LoadingShoppinglistCubitState,
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
