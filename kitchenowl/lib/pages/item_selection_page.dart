import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/cubits/item_selection_cubit.dart';
import 'package:kitchenowl/models/item.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/models/planner.dart';
import 'package:kitchenowl/models/shoppinglist.dart';

class ItemSelectionPage extends StatefulWidget {
  final List<RecipePlan> plans;
  final List<ShoppingList> shoppingLists;
  final String? title;
  final String Function(Object) selectText;
  final Future<(ShoppingList?, List<RecipeItem>)?> Function(
      ShoppingList?, List<RecipeItem>)? handleResult;

  const ItemSelectionPage({
    super.key,
    this.title,
    this.plans = const [],
    required this.selectText,
    this.handleResult,
    this.shoppingLists = const [],
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
    cubit = ItemSelectionCubit(widget.plans);
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
            for (final plan in widget.plans) ...[
              if (plan.recipe.items.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverToBoxAdapter(
                    child: Text(
                      '${plan.recipe.name}${plan.yields != null ? " (${plan.yields} ${AppLocalizations.of(context)!.yields})" : ""}:',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                ),
              SliverItemGridList(
                items: plan.recipeWithYields.mandatoryItems,
                onPressed:
                    Nullable((RecipeItem item) => cubit.toggleItem(plan, item)),
                selected: (item) => state.selectedItems[plan]!.contains(item),
                onLongPressed:
                    const Nullable<void Function(RecipeItem)>.empty(),
              ),
              if (plan.recipe.optionalItems.isNotEmpty)
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
                items: plan.recipeWithYields.optionalItems,
                onPressed:
                    Nullable((RecipeItem item) => cubit.toggleItem(plan, item)),
                selected: (item) => state.selectedItems[plan]!.contains(item),
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
                child: Row(
                  children: [
                    Expanded(
                      child: LoadingElevatedButton(
                        onPressed: state.getResult().isEmpty
                            ? null
                            : () async {
                                if (widget.handleResult != null) {
                                  Navigator.of(context).pop(
                                    await widget.handleResult!(
                                        null, cubit.getResult()),
                                  );
                                } else {
                                  Navigator.of(context)
                                      .pop((null, cubit.getResult()));
                                }
                              },
                        child: Text(
                          AppLocalizations.of(context)!.addNumberIngredients(
                            state.getResult().length,
                          ),
                        ),
                      ),
                    ),
                    if (widget.shoppingLists.length > 1)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: LoadingElevatedButton(
                          onPressed: state.getResult().isEmpty
                              ? null
                              : () async {
                                  ShoppingList? list =
                                      await showDialog<ShoppingList>(
                                    context: context,
                                    builder: (context) => SelectDialog(
                                      title: AppLocalizations.of(context)!
                                          .addNumberIngredients(
                                              state.selectedItems.length),
                                      cancelText:
                                          AppLocalizations.of(context)!.cancel,
                                      options: widget.shoppingLists
                                          .map(
                                            (e) => SelectDialogOption(
                                              e,
                                              e.name,
                                            ),
                                          )
                                          .toList(),
                                    ),
                                  );
                                  if (list != null) {
                                    if (widget.handleResult != null) {
                                      Navigator.of(context).pop(
                                        await widget.handleResult!(
                                            list, cubit.getResult()),
                                      );
                                    } else {
                                      Navigator.of(context)
                                          .pop((list, cubit.getResult()));
                                    }
                                  }
                                },
                          child: const Icon(Icons.shopping_bag_rounded),
                        ),
                      ),
                  ],
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
