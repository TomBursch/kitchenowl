import 'package:animations/animations.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/app.dart';
import 'package:kitchenowl/cubits/shoppinglist_cubit.dart';
import 'package:kitchenowl/enums/shoppinglist_sorting.dart';
import 'package:kitchenowl/models/item.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/widgets/choice_scroll.dart';
import 'package:kitchenowl/widgets/shopping_list/shopping_list_choice_chip.dart';
import 'package:kitchenowl/widgets/shopping_list/sliver_shopinglist_item_view.dart';

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
                    } else {
                      cubit.search(searchController.text);
                    }
                  },
                ),
              ),
            ),
          ),
          Expanded(
            child: BlocBuilder<ShoppinglistCubit, ShoppinglistCubitState>(
              bloc: cubit,
              builder: (context, state) => PageTransitionSwitcher(
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
                child: (state is SearchShoppinglistCubitState)
                    ? RefreshIndicator(
                        onRefresh: cubit.refresh,
                        child: CustomScrollView(
                          primary: true,
                          slivers: [
                            SliverItemGridList(
                              items: state.result,
                              categories: state.categories,
                              shoppingList: state.selectedShoppinglist,
                              onRefresh: () => cubit.refresh(),
                              selected: (item) =>
                                  item is ShoppinglistItem &&
                                  (App.settings.shoppingListTapToRemove ||
                                      !state.selectedListItems.contains(item)),
                              isLoading: state is LoadingShoppinglistCubitState,
                              onPressed: Nullable((Item item) {
                                if (item is ShoppinglistItem) {
                                  if (App.settings.shoppingListTapToRemove) {
                                    cubit.remove(item);
                                  } else {
                                    cubit.selectItem(item);
                                  }
                                } else {
                                  cubit.add(item);
                                }
                              }),
                            ),
                          ],
                        ),
                      )
                    : NestedScrollView(
                        headerSliverBuilder: (context, innerBoxIsScrolled) => [
                          SliverToBoxAdapter(
                            child: LeftRightWrap(
                              left: (state.shoppinglists.length < 2)
                                  ? const SizedBox()
                                  : ChoiceScroll(
                                      children: state.shoppinglists.values
                                          .sorted((a, b) => b.items.length
                                              .compareTo(a.items.length))
                                          .map(
                                            (shoppinglist) =>
                                                ShoppingListChoiceChip(
                                              shoppingList: shoppinglist,
                                              selected: shoppinglist.id ==
                                                  state.selectedShoppinglistId,
                                              onSelected: (bool selected) {
                                                if (selected) {
                                                  cubit.setShoppingList(
                                                    shoppinglist,
                                                  );
                                                }
                                              },
                                            ),
                                          )
                                          .toList(),
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
                                  state.selectedShoppinglistId),
                              slivers: [
                                SliverShopinglistItemView(
                                  categories: state.categories,
                                  isLoading:
                                      state is LoadingShoppinglistCubitState,
                                  selectedListItems: state.selectedListItems,
                                  sorting: state.sorting,
                                  shoppingList: state.selectedShoppinglist,
                                  onPressed: Nullable((Item item) {
                                    if (item is ShoppinglistItem) {
                                      if (App
                                          .settings.shoppingListTapToRemove) {
                                        cubit.remove(item);
                                      } else {
                                        cubit.selectItem(item);
                                      }
                                    } else {
                                      cubit.add(item);
                                    }
                                  }),
                                  onRecentPressed: Nullable(cubit.add),
                                  onRefresh: cubit.refresh,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
