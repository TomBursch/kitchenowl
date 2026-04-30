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
  final String Function(int) selectText;
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
  bool _hidePastPlans = true;

  @override
  void initState() {
    super.initState();
    cubit = ItemSelectionCubit(widget.plans);
  }

  @override
  void dispose() {
    if (mounted) {
      cubit.close();
    }
    
    super.dispose();
  }

  List<RecipeItem> _getFilteredResult() {
    final filteredPlans = _get_filteredPlans();
    final allResults = cubit.getResult();

    return allResults.where((item) {
      return filteredPlans.any((plan) => 
        plan.recipeWithYields.mandatoryItems.contains(item) || 
        plan.recipeWithYields.optionalItems.contains(item)
      );
    }).toList();
  }

  List<RecipePlan> _get_filteredPlans() {
    if (!_hidePastPlans) return widget.plans;

    final now = DateTime.now();
    return widget.plans
        .where((plan) => plan.cookingDate == null || plan.cookingDate!.isAfter(now))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredPlans = _get_filteredPlans();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title ?? AppLocalizations.of(context)!.itemsAdd),
        actions: [
          IconButton(
            icon: Icon(_hidePastPlans ? Icons.visibility_off_rounded : Icons.visibility_rounded), 
            tooltip: _hidePastPlans ? AppLocalizations.of(context)!.showPastPlans : AppLocalizations.of(context)!.hidePastPlans ,
            onPressed: () {
            setState(() {
              _hidePastPlans = !_hidePastPlans;
            });
          }),
        ],
      ),
      body: BlocBuilder<ItemSelectionCubit, ItemSelectionState>(
        bloc: cubit,
        builder: (context, state) => CustomScrollView(
          slivers: [
            for (final plan in filteredPlans) ...[
              if (plan.recipe.items.isNotEmpty)
                SliverToBoxAdapter(
                  child: CheckboxListTile(
                    title: Text(
                      '${plan.recipe.name}${plan.yields != null ? " (${plan.yields} ${AppLocalizations.of(context)!.yields})" : ""}:',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    value: state.selectedItems[plan]!
                        .containsAll(plan.recipeWithYields.mandatoryItems),
                    onChanged: (newValue) {
                      if (!(newValue ?? false)) {
                        cubit.remove(plan);
                      } else {
                        cubit.add(plan);
                      }
                    },
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
                                        null, _getFilteredResult()),
                                  );
                                } else {
                                  Navigator.of(context)
                                      .pop((null, _getFilteredResult()));
                                }
                              },
                        child: Text(
                          AppLocalizations.of(context)!.addNumberIngredients(
                            _getFilteredResult().length,
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
                                              _getFilteredResult().length),
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
                                            list, _getFilteredResult()),
                                      );
                                    } else {
                                      Navigator.of(context)
                                          .pop((list, _getFilteredResult()));
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
              child: SizedBox(height: MediaQuery.paddingOf(context).bottom),
            ),
          ],
        ),
      ),
    );
  }
}
