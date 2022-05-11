import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/app.dart';
import 'package:kitchenowl/cubits/shoppinglist_cubit.dart';
import 'package:kitchenowl/enums/update_enum.dart';
import 'package:kitchenowl/models/item.dart';
import 'package:kitchenowl/models/update_value.dart';
import 'package:kitchenowl/pages/item_page.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/widgets/shopping_item.dart';
import 'package:responsive_builder/responsive_builder.dart';

class ShoppinglistPage extends StatefulWidget {
  const ShoppinglistPage({Key? key}) : super(key: key);

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
    final int crossAxisCount = getValueForScreenType<int>(
      context: context,
      mobile: 3,
      tablet: 6,
      desktop: 9,
    );
    final isOffline = App.isOffline;

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
                  if (state is! SearchShoppinglistCubitState) {
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
                        cubit.add(
                          state.result.first.name,
                          (state.result.first is ItemWithDescription)
                              ? (state.result.first as ItemWithDescription)
                                  .description
                              : null,
                        );
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
                      return GridView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 3,
                          mainAxisSpacing: 4,
                        ),
                        itemCount: state.result.length,
                        itemBuilder: (context, i) => ShoppingItemWidget(
                          item: state.result[i],
                          selected: state.result[i] is ShoppinglistItem,
                          onPressed: (Item item) {
                            if (item is ShoppinglistItem) {
                              cubit.remove(item);
                            } else {
                              cubit.add(
                                item.name,
                                (item is ItemWithDescription)
                                    ? item.description
                                    : null,
                              );
                            }
                          },
                          onLongPressed: (Item item) async {
                            final res = await Navigator.of(context)
                                .push<UpdateValue<Item>>(
                              MaterialPageRoute(
                                builder: (BuildContext context) => ItemPage(
                                  item: item,
                                ),
                              ),
                            );
                            if (res != null &&
                                (res.state == UpdateEnum.deleted ||
                                    res.state == UpdateEnum.updated)) {
                              cubit.refresh();
                            }
                          },
                        ),
                      );
                    }

                    dynamic body = SliverChildBuilderDelegate(
                      (context, i) => ShoppingItemWidget(
                        key: ObjectKey(state.listItems[i]),
                        item: state.listItems[i],
                        selected: true,
                        gridStyle: state.style == ShoppinglistStyle.grid,
                        onPressed: (Item item) {
                          if (item is ShoppinglistItem) {
                            cubit.remove(item);
                          } else {
                            cubit.add(item.name);
                          }
                        },
                        onLongPressed: (ShoppinglistItem item) async {
                          final res = await Navigator.of(context)
                              .push<UpdateValue<Item>>(
                            MaterialPageRoute(
                              builder: (BuildContext context) =>
                                  ItemPage(item: item),
                            ),
                          );
                          if (res != null &&
                              (res.state == UpdateEnum.deleted ||
                                  res.state == UpdateEnum.updated)) {
                            cubit.refresh();
                          }
                        },
                      ),
                      childCount: state.listItems.length,
                    );

                    body = state.style == ShoppinglistStyle.grid
                        ? SliverGrid(
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              mainAxisSpacing: 4,
                              crossAxisSpacing: 4,
                              childAspectRatio: 1,
                            ),
                            delegate: body,
                          )
                        : SliverList(delegate: body);

                    body = SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: body,
                    );

                    return CustomScrollView(
                      slivers: [
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                          sliver: SliverToBoxAdapter(
                            child: Row(
                              children: [
                                // TextButton(
                                //   onPressed: cubit.incrementStyle,
                                //   child: Padding(
                                //     padding: const EdgeInsets.only(
                                //       right: 4,
                                //       left: 1,
                                //     ),
                                //     child: Row(
                                //       mainAxisSize: MainAxisSize.min,
                                //       children: [
                                //         Icon(state.style ==
                                //                 ShoppinglistStyle.grid
                                //             ? Icons.grid_view_rounded
                                //             : Icons.view_list_rounded),
                                //         const SizedBox(width: 4),
                                //         Text(state.style ==
                                //                 ShoppinglistStyle.grid
                                //             ? AppLocalizations.of(context)!.grid
                                //             : AppLocalizations.of(context)!
                                //                 .list),
                                //       ],
                                //     ),
                                //   ),
                                // ),
                                const Spacer(),
                                TextButton(
                                  onPressed: cubit.incrementSorting,
                                  child: Padding(
                                    padding: const EdgeInsets.only(
                                      left: 4,
                                      right: 1,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(state.sorting ==
                                                ShoppinglistSorting.alphabetical
                                            ? AppLocalizations.of(context)!
                                                .sortingAlphabetical
                                            : state.sorting ==
                                                    ShoppinglistSorting
                                                        .algorithmic
                                                ? AppLocalizations.of(context)!
                                                    .sortingAlgorithmic
                                                : AppLocalizations.of(context)!
                                                    .category),
                                        const SizedBox(width: 4),
                                        const Icon(Icons.sort),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        body,
                        if (!isOffline)
                          SliverPadding(
                            padding: const EdgeInsets.all(16),
                            sliver: SliverToBoxAdapter(
                              child: Text(
                                '${AppLocalizations.of(context)!.itemsRecent}:',
                                style: Theme.of(context).textTheme.headline6,
                              ),
                            ),
                          ),
                        if (!isOffline)
                          SliverPadding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            sliver: SliverGrid(
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                mainAxisSpacing: 4,
                                crossAxisSpacing: 4,
                                childAspectRatio: 1,
                              ),
                              delegate: SliverChildBuilderDelegate(
                                (context, i) => ShoppingItemWidget(
                                  key: ObjectKey(state.recentItems[i]),
                                  item: state.recentItems[i],
                                  onPressed: (Item item) =>
                                      cubit.add(item.name),
                                  onLongPressed: (Item item) async {
                                    final res = await Navigator.of(context)
                                        .push<UpdateValue<Item>>(
                                      MaterialPageRoute(
                                        builder: (BuildContext context) =>
                                            ItemPage(
                                          item: item,
                                        ),
                                      ),
                                    );
                                    if (res != null &&
                                        (res.state == UpdateEnum.deleted ||
                                            res.state == UpdateEnum.updated)) {
                                      cubit.refresh();
                                    }
                                  },
                                ),
                                childCount: state.recentItems.length,
                              ),
                            ),
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
