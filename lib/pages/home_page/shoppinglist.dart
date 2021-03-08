import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/cubits/shoppinglist_cubit.dart';
import 'package:kitchenowl/models/item.dart';
import 'package:kitchenowl/pages/item_page.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/widgets/search_text_field.dart';
import 'package:kitchenowl/widgets/shopping_item.dart';
import 'package:responsive_builder/responsive_builder.dart';

class ShoppinglistPage extends StatefulWidget {
  ShoppinglistPage({Key key}) : super(key: key);

  @override
  _ShoppinglistPageState createState() => _ShoppinglistPageState();
}

class _ShoppinglistPageState extends State<ShoppinglistPage> {
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
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
    return BlocProvider<ShoppinglistCubit>(
      create: (context) => ShoppinglistCubit(),
      lazy: false,
      child: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 80,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: BlocListener<ShoppinglistCubit, ShoppinglistCubitState>(
                  cubit: cubit,
                  listener: (context, state) {
                    if (!(state is SearchShoppinglistCubitState)) {
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
                        if (!(state.result.first is ShoppinglistItem))
                          cubit.add(state.result.first.name);
                      } else {
                        FocusScope.of(context).unfocus();
                      }
                    },
                  ),
                ),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: cubit.refresh,
                child: BlocBuilder<ShoppinglistCubit, ShoppinglistCubitState>(
                    cubit: cubit,
                    builder: (context, state) {
                      if (state is SearchShoppinglistCubitState)
                        return GridView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            crossAxisSpacing: 3,
                            mainAxisSpacing: 4,
                          ),
                          itemCount: state.result.length,
                          itemBuilder: (context, i) => ShoppingItemWidget(
                            item: state.result[i],
                            selected: state.result[i] is ShoppinglistItem,
                            onPressed: (item) {
                              if (item is ShoppinglistItem)
                                cubit.remove(item);
                              else
                                cubit.add(item.name);
                            },
                            onLongPressed: (item) => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (BuildContext context) => ItemPage(
                                  item: item,
                                ),
                              ),
                            ),
                          ),
                        );
                      return CustomScrollView(
                        slivers: [
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
                                  item: state.listItems[i],
                                  selected: true,
                                  onPressed: (item) {
                                    if (item is ShoppinglistItem)
                                      cubit.remove(item);
                                    else
                                      cubit.add(item.name);
                                  },
                                  onLongPressed: (item) =>
                                      Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (BuildContext context) =>
                                          ItemPage(
                                        item: item,
                                      ),
                                    ),
                                  ),
                                ),
                                childCount: state.listItems.length,
                              ),
                            ),
                          ),
                          SliverPadding(
                            padding: const EdgeInsets.all(16),
                            sliver: SliverToBoxAdapter(
                              child: Text(
                                AppLocalizations.of(context).itemsRecent + ':',
                                style: Theme.of(context).textTheme.headline6,
                              ),
                            ),
                          ),
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
                                  item: state.recentItems[i],
                                  onPressed: (item) => cubit.add(item.name),
                                ),
                                childCount: state.recentItems.length,
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
