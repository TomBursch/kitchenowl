import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/cubits/item_selection_cubit.dart';
import 'package:kitchenowl/models/item.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/models/recipe.dart';

class ItemSelectionPage extends StatefulWidget {
  final List<Recipe> recipes;
  final String? title;
  final String Function(Object) selectText;
  final Future<List<RecipeItem>> Function(List<RecipeItem>)? handleResult;

  const ItemSelectionPage({
    super.key,
    this.title,
    this.recipes = const [],
    required this.selectText,
    this.handleResult,
  });

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
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                ),
              SliverItemGridList(
                items: recipe.mandatoryItems,
                onPressed: (RecipeItem item) => cubit.toggleItem(recipe, item),
                selected: (item) => state.selectedItems[recipe]!.contains(item),
                onLongPressed:
                    const Nullable<void Function(RecipeItem)>.empty(),
              ),
              if (recipe.optionalItems.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverToBoxAdapter(
                    child: Text(
                      '${AppLocalizations.of(context)!.itemsOptional}:',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                ),
              SliverItemGridList(
                items: recipe.optionalItems,
                onPressed: (RecipeItem item) => cubit.toggleItem(recipe, item),
                selected: (item) => state.selectedItems[recipe]!.contains(item),
                onLongPressed:
                    const Nullable<void Function(RecipeItem)>.empty(),
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
                child: LoadingElevatedButton(
                  onPressed: state.getResult().isEmpty
                      ? null
                      : () async {
                          if (widget.handleResult != null) {
                            Navigator.of(context).pop(
                              await widget.handleResult!(cubit.getResult()),
                            );
                          } else {
                            Navigator.of(context).pop(cubit.getResult());
                          }
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
