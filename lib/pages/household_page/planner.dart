import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:kitchenowl/cubits/planner_cubit.dart';
import 'package:kitchenowl/cubits/settings_cubit.dart';
import 'package:kitchenowl/enums/update_enum.dart';
import 'package:kitchenowl/enums/views_enum.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/models/item.dart';
import 'package:kitchenowl/models/recipe.dart';
import 'package:kitchenowl/pages/item_selection_page.dart';
import 'package:kitchenowl/pages/recipe_page.dart';
import 'package:kitchenowl/widgets/recipe_card.dart';
import 'package:responsive_builder/responsive_builder.dart';

import 'home_page_item.dart';

class PlannerPage extends StatefulWidget with HomePageItem {
  const PlannerPage({Key? key}) : super(key: key);

  @override
  _PlannerPageState createState() => _PlannerPageState();

  @override
  ViewsEnum type() => ViewsEnum.planner;

  @override
  void onSelected(BuildContext context, bool alreadySelected) {
    BlocProvider.of<PlannerCubit>(context).refresh();
  }

  @override
  bool isActive(BuildContext context) => false;
}

class _PlannerPageState extends State<PlannerPage> {
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
    final cubit = BlocProvider.of<PlannerCubit>(context);

    final weekdayMapping = {
      0: DateTime.monday,
      1: DateTime.tuesday,
      2: DateTime.wednesday,
      3: DateTime.thursday,
      4: DateTime.friday,
      5: DateTime.saturday,
      6: DateTime.sunday,
    };

    return SafeArea(
      child: Scrollbar(
        child: RefreshIndicator(
          onRefresh: cubit.refresh,
          child: BlocBuilder<PlannerCubit, PlannerCubitState>(
            bloc: cubit,
            builder: (context, state) {
              if (state is! LoadedPlannerCubitState) {
                return CustomScrollView(
                  primary: true,
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      sliver: SliverToBoxAdapter(
                        child: Container(
                          height: 80,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            AppLocalizations.of(context)!.plannerTitle,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                        ),
                      ),
                    ),
                    const SliverItemGridList(
                      isLoading: true,
                    ),
                  ],
                );
              }

              return CustomScrollView(
                primary: true,
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverToBoxAdapter(
                      child: Container(
                        height: 80,
                        alignment: Alignment.centerLeft,
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                AppLocalizations.of(context)!.plannerTitle,
                                style:
                                    Theme.of(context).textTheme.headlineSmall,
                              ),
                            ),
                            if (state.plannedRecipes.isNotEmpty)
                              InkWell(
                                borderRadius: BorderRadius.circular(50),
                                child:
                                    const Icon(Icons.add_shopping_cart_rounded),
                                onTap: () =>
                                    _openItemSelectionPage(context, cubit),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (state.plannedRecipes.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Icon(Icons.no_food_rounded),
                            const SizedBox(height: 16),
                            Text(AppLocalizations.of(context)!.plannerEmpty),
                          ],
                        ),
                      ),
                    ),
                  SliverLayoutBuilder(
                    builder: (context, constraints) => SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverToBoxAdapter(
                        child: Wrap(
                          crossAxisAlignment: WrapCrossAlignment.end,
                          alignment: WrapAlignment.start,
                          children: [
                            for (final recipe in state.getPlannedWithoutDay())
                              KitchenOwlFractionallySizedBox(
                                widthFactor: (1 /
                                    (constraints.crossAxisExtent ~/ 135)
                                        .clamp(1, 9)),
                                child: AspectRatio(
                                  aspectRatio: 1,
                                  child: SelectableButtonCard(
                                    key: Key(recipe.name),
                                    title: recipe.name,
                                    selected: true,
                                    onPressed: () {
                                      cubit.remove(recipe);
                                    },
                                    onLongPressed: () => _openRecipePage(
                                      context,
                                      cubit,
                                      recipe,
                                    ),
                                  ),
                                ),
                              ),
                            for (int day = 0; day < 7; day++)
                              for (final recipe in state.getPlannedOfDay(day))
                                KitchenOwlFractionallySizedBox(
                                  widthFactor: (1 /
                                      (constraints.crossAxisExtent ~/ 135)
                                          .clamp(1, 9)),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      if (recipe ==
                                          state.getPlannedOfDay(day)[0])
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 5),
                                          child: Text(
                                            '${DateFormat.E().dateSymbols.STANDALONEWEEKDAYS[weekdayMapping[day]! % 7]}:',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyLarge,
                                          ),
                                        ),
                                      AspectRatio(
                                        aspectRatio: 1,
                                        child: SelectableButtonCard(
                                          key: Key(
                                            recipe.name,
                                          ),
                                          title: recipe.name,
                                          selected: true,
                                          onPressed: () {
                                            cubit.remove(
                                              recipe,
                                              day,
                                            );
                                          },
                                          onLongPressed: () => _openRecipePage(
                                            context,
                                            cubit,
                                            recipe,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (state.recentRecipes.isNotEmpty) ...[
                    SliverPadding(
                      padding: const EdgeInsets.all(16),
                      sliver: SliverToBoxAdapter(
                        child: Text(
                          '${AppLocalizations.of(context)!.recipesRecent}:',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: getValueForScreenType(
                          context: context,
                          mobile: 375,
                          tablet: 415,
                          desktop: 415,
                        ),
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemBuilder: (context, i) => RecipeCard(
                            recipe: state.recentRecipes[i],
                            onLongPressed: () =>
                                cubit.add(state.recentRecipes[i]),
                            onAddToDate: () => _addRecipeToSpecificDay(
                              context,
                              cubit,
                              state.recentRecipes[i],
                            ),
                            onPressed: () => _openRecipePage(
                              context,
                              cubit,
                              state.recentRecipes[i],
                            ),
                          ),
                          itemCount: state.recentRecipes.length,
                          scrollDirection: Axis.horizontal,
                        ),
                      ),
                    ),
                  ],
                  if (state.suggestedRecipes.isNotEmpty) ...[
                    SliverPadding(
                      padding: const EdgeInsets.all(16),
                      sliver: SliverToBoxAdapter(
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${AppLocalizations.of(context)!.recipesSuggested}:',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ),
                            InkWell(
                              borderRadius: BorderRadius.circular(50),
                              onTap: cubit.refreshSuggestions,
                              child: const Icon(Icons.refresh),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: getValueForScreenType(
                          context: context,
                          mobile: 375,
                          tablet: 415,
                          desktop: 415,
                        ),
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemBuilder: (context, i) => RecipeCard(
                            recipe: state.suggestedRecipes[i],
                            onLongPressed: () =>
                                cubit.add(state.suggestedRecipes[i]),
                            onAddToDate: () => _addRecipeToSpecificDay(
                              context,
                              cubit,
                              state.suggestedRecipes[i],
                            ),
                            onPressed: () => _openRecipePage(
                              context,
                              cubit,
                              state.suggestedRecipes[i],
                            ),
                          ),
                          itemCount: state.suggestedRecipes.length,
                          scrollDirection: Axis.horizontal,
                        ),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _openRecipePage(
    BuildContext context,
    PlannerCubit cubit,
    Recipe recipe,
  ) async {
    final res = await Navigator.of(context).push<UpdateEnum>(
      MaterialPageRoute(
        builder: (context) => RecipePage(
          recipe: recipe,
          updateOnPlanningEdit: true,
        ),
      ),
    );
    if (res == UpdateEnum.updated || res == UpdateEnum.deleted) {
      cubit.refresh();
    }
  }

  Future<void> _openItemSelectionPage(
    BuildContext context,
    PlannerCubit cubit,
  ) async {
    await Navigator.of(context).push<List<RecipeItem>>(
      MaterialPageRoute(
        builder: (context) => ItemSelectionPage(
          selectText: AppLocalizations.of(context)!.addNumberIngredients,
          recipes: (cubit.state as LoadedPlannerCubitState).plannedRecipes,
          title: AppLocalizations.of(context)!.addItemTitle,
          handleResult: (res) async {
            if (res.isNotEmpty) {
              await cubit.addItemsToList(res);
            }

            return res;
          },
        ),
      ),
    );
  }

  Future<void> _addRecipeToSpecificDay(
    BuildContext context,
    PlannerCubit cubit,
    Recipe recipe,
  ) async {
    final weekdayMapping = {
      0: DateTime.monday,
      1: DateTime.tuesday,
      2: DateTime.wednesday,
      3: DateTime.thursday,
      4: DateTime.friday,
      5: DateTime.saturday,
      6: DateTime.sunday,
    };
    int? day = await showDialog<int>(
      context: context,
      builder: (context) => SelectDialog(
        title: AppLocalizations.of(context)!.addRecipeToPlanner,
        cancelText: AppLocalizations.of(context)!.cancel,
        options: weekdayMapping.entries
            .map(
              (e) => SelectDialogOption(
                e.key,
                DateFormat.E().dateSymbols.STANDALONEWEEKDAYS[e.value % 7],
              ),
            )
            .toList(),
      ),
    );
    if (day != null) {
      await cubit.add(
        recipe,
        day >= 0 ? day : null,
      );
    }
  }
}
