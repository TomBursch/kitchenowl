import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/cubits/item_selection_cubit.dart';
import 'package:kitchenowl/models/item.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/models/recipe.dart';
import 'package:kitchenowl/widgets/shopping_item.dart';
import 'package:responsive_builder/responsive_builder.dart';

class ItemSelectionPage extends StatefulWidget {
  final List<Recipe> recipes;
  final String? title;
  final String Function(Object) selectText;

  const ItemSelectionPage({
    Key? key,
    this.title,
    this.recipes = const [],
    required this.selectText,
  }) : super(key: key);

  @override
  _ItemSelectionPageState createState() => _ItemSelectionPageState();
}

class _ItemSelectionPageState extends State<ItemSelectionPage> {
  final TextEditingController searchController = TextEditingController();
  late ItemSelectionCubit cubit;

  @override
  void initState() {
    super.initState();
    cubit = ItemSelectionCubit(widget.recipes);
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
      body: BlocBuilder<ItemSelectionCubit, ItemSelectionState>(
        bloc: cubit,
        builder: (context, state) => CustomScrollView(
          slivers: [
            for (final recipe in widget.recipes) ...[
              if (recipe.items.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverToBoxAdapter(
                    child: Text(
                      '${recipe.name}:',
                      style: Theme.of(context).textTheme.headline5,
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
                      onPressed: (item) => cubit.toggleItem(recipe, item),
                      selected: state.selectedItems[recipe]!.contains(
                        recipe.mandatoryItems.elementAt(i),
                      ),
                      item: recipe.mandatoryItems.elementAt(i),
                    ),
                    childCount: recipe.mandatoryItems.length,
                  ),
                ),
              ),
              if (recipe.optionalItems.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverToBoxAdapter(
                    child: Text(
                      '${AppLocalizations.of(context)!.itemsOptional}:',
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
                      onPressed: (item) => cubit.toggleItem(recipe, item),
                      selected: state.selectedItems[recipe]!.contains(
                        recipe.optionalItems.elementAt(i),
                      ),
                      item: recipe.optionalItems.elementAt(i),
                    ),
                    childCount: recipe.optionalItems.length,
                  ),
                ),
              ),
              const SliverPadding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
                sliver: SliverToBoxAdapter(
                  child: Divider(),
                ),
              ),
            ],
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverToBoxAdapter(
                child: ElevatedButton(
                  onPressed: state.getResult().isEmpty
                      ? null
                      : () async {
                          Navigator.of(context).pop(cubit.getResult());
                        },
                  child: Text(
                    AppLocalizations.of(context)!.addNumberIngredients(
                      state.getResult().length,
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(height: MediaQuery.of(context).padding.bottom),
            ),
          ],
        ),
      ),
    );
  }
}
