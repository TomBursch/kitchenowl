import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/cubits/item_selection_cubit.dart';
import 'package:kitchenowl/models/item.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/widgets/shopping_item.dart';
import 'package:responsive_builder/responsive_builder.dart';

class ItemSelectionPage<T extends Item> extends StatefulWidget {
  final List<T> items;
  final String? title;
  final String Function(Object) selectText;

  const ItemSelectionPage({
    Key? key,
    this.title,
    this.items = const [],
    required this.selectText,
  }) : super(key: key);

  @override
  _ItemSelectionPageState<T> createState() => _ItemSelectionPageState<T>();
}

class _ItemSelectionPageState<T extends Item>
    extends State<ItemSelectionPage<T>> {
  final TextEditingController searchController = TextEditingController();
  late ItemSelectionCubit<T> cubit;

  @override
  void initState() {
    super.initState();
    cubit = ItemSelectionCubit<T>(widget.items);
  }

  @override
  void dispose() {
    cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final int crossAxisCount = getValueForScreenType<int>(
      context: context,
      mobile: 3,
      tablet: 6,
      desktop: 9,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title ?? AppLocalizations.of(context)!.itemsAdd),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: BlocBuilder<ItemSelectionCubit<T>, ItemSelectionState<T>>(
          bloc: cubit,
          builder: (context, state) => CustomScrollView(
            slivers: [
              if (state.items.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverToBoxAdapter(
                    child: Text(
                      AppLocalizations.of(context)!.items + ':',
                      style: Theme.of(context).textTheme.headline6,
                    ),
                  ),
                ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: 4,
                    crossAxisSpacing: 4,
                    childAspectRatio: 1,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => ShoppingItemWidget<T>(
                      onPressed: cubit.toggleItem,
                      selected: state.selectedItems.contains(
                        state.items.elementAt(i),
                      ),
                      item: state.items.elementAt(i),
                    ),
                    childCount: state.items.length,
                  ),
                ),
              ),
              if (state.optionalItems.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverToBoxAdapter(
                    child: Text(
                      AppLocalizations.of(context)!.itemsOptional + ':',
                      style: Theme.of(context).textTheme.headline6,
                    ),
                  ),
                ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: 4,
                    crossAxisSpacing: 4,
                    childAspectRatio: 1,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => ShoppingItemWidget<RecipeItem>(
                      onPressed: (e) => cubit.toggleItem(e as T),
                      selected: state.selectedItems
                          .contains(state.optionalItems.elementAt(i)),
                      item: state.optionalItems.elementAt(i),
                    ),
                    childCount: state.optionalItems.length,
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverToBoxAdapter(
                  child: ElevatedButton(
                    child: Text(
                      AppLocalizations.of(context)!.addNumberIngredients(
                        state.selectedItems.length,
                      ),
                    ),
                    onPressed: state.selectedItems.isEmpty
                        ? null
                        : () async {
                            Navigator.of(context).pop(cubit.getResult());
                          },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
