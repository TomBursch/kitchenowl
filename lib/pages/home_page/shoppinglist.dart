import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/cubits/shoppinglist_cubit.dart';
import 'package:kitchenowl/models/item.dart';
import 'package:kitchenowl/pages/item_page.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/widgets/home_page/shopping_item.dart';

class ShoppinglistPage extends StatefulWidget {
  ShoppinglistPage({Key key}) : super(key: key);

  @override
  _ShoppinglistPageState createState() => _ShoppinglistPageState();
}

class _ShoppinglistPageState extends State<ShoppinglistPage> {
  final TextEditingController searchController = TextEditingController();
  final ShoppinglistCubit cubit = ShoppinglistCubit();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    cubit.close();
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final int crossAxisCount =
        ((MediaQuery.of(context).size.width / 1080).clamp(0, 1) * 6 + 3)
            .round();
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
                  child: TextField(
                    controller: searchController,
                    onChanged: (s) => cubit.search(s),
                    textInputAction: TextInputAction.done,
                    onEditingComplete: () {
                      cubit.search('');
                    },
                    onSubmitted: (text) {
                      final state = cubit.state;
                      if (state is SearchShoppinglistCubitState) {
                        if (!(state.result.first is ShoppinglistItem))
                          cubit.add(state.result.first.name);
                      } else {
                        FocusScope.of(context).unfocus();
                      }
                    },
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.search),
                      suffix: IconButton(
                        onPressed: () {
                          if (searchController.text.isNotEmpty) {
                            cubit.search('');
                          }
                          FocusScope.of(context).unfocus();
                        },
                        icon: Icon(
                          Icons.close,
                          color: Colors.grey,
                        ),
                      ),
                      labelText: AppLocalizations.of(context).searchHint,
                    ),
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
