import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:kitchenowl/cubits/household_cubit.dart';
import 'package:kitchenowl/cubits/planner_cubit.dart';
import 'package:kitchenowl/cubits/settings_cubit.dart';
import 'package:kitchenowl/cubits/shoppinglist_cubit.dart';
import 'package:kitchenowl/enums/update_enum.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/models/household.dart';
import 'package:kitchenowl/models/item.dart';
import 'package:kitchenowl/models/recipe.dart';
import 'package:kitchenowl/models/shoppinglist.dart';
import 'package:kitchenowl/pages/item_selection_page.dart';
import 'package:kitchenowl/widgets/recipe_card.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:tuple/tuple.dart';

DateTime toEndOfDay(DateTime dt) {
  return DateTime(dt.year, dt.month, dt.day, 23, 59, 59);
}
String formatDateAsWeekday(DateTime date, BuildContext context,
    {String default_format = 'EEEE'}) {
  DateTime today = DateTime.now();
  DateTime tomorrow = today.add(Duration(days: 1));
  DateTime yesterday = today.subtract(Duration(days: 1));

  // Check if the date is today or tomorrow
  if (date.year == today.year &&
      date.month == today.month &&
      date.day == today.day) {
    return AppLocalizations.of(context)!.today;
  } else if (date.year == tomorrow.year &&
      date.month == tomorrow.month &&
      date.day == tomorrow.day) {
    return AppLocalizations.of(context)!.tomorrow;
  } else if (date.year == yesterday.year && date.month == yesterday.month && date.day == yesterday.day) {
    return AppLocalizations.of(context)!.yesterday;
      
  } else {
    // Return the weekday name
    return DateFormat(default_format).format(date);
  }
}

String _formatDate(int daysToAdd, BuildContext context) {
  DateTime date = DateTime.now().add(Duration(days: daysToAdd));
  if (daysToAdd >= -1 && daysToAdd < 7) {
    return formatDateAsWeekday(date, context, default_format: 'E');
  } else {
    return DateFormat.yMMMd().format(date);
  }
}


int daysBetween(DateTime from, DateTime to) {
  // otherwise it's rounded
    from = DateTime(from.year, from.month, from.day);
    to = DateTime(to.year, to.month, to.day);
  return (to.difference(from).inHours / 24).round();
}

class PlannerPage extends StatefulWidget {
  const PlannerPage({super.key});

  @override
  _PlannerPageState createState() => _PlannerPageState();
}

class _PlannerPageState extends State<PlannerPage> {
  final TextEditingController searchController = TextEditingController();
  final ScrollController suggestedRecipesScrollController = ScrollController();

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
    final household = BlocProvider.of<HouseholdCubit>(context).state.household;

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
                            if (state.recipePlans.isNotEmpty &&
                                household.defaultShoppingList != null)
                              IconButton(
                                tooltip: AppLocalizations.of(context)!.itemsAdd,
                                onPressed: () =>
                                    _openItemSelectionPage(context, cubit),
                                icon: const Icon(
                                  Icons.add_shopping_cart_rounded,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (state.recipePlans.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Icon(Icons.no_food_rounded),
                            const SizedBox(height: 16),
                            Text(
                              AppLocalizations.of(context)!.plannerEmpty,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverLayoutBuilder(
                      builder: (context, constraints) => SliverToBoxAdapter(
                        child: Wrap(
                          crossAxisAlignment: WrapCrossAlignment.end,
                          alignment: WrapAlignment.start,
                          children: [
                            for (final plan in state.getPlannedWithoutDay())
                              KitchenOwlFractionallySizedBox(
                                widthFactor: (1 /
                                    DynamicStyling.itemCrossAxisCount(
                                      constraints.crossAxisExtent,
                                      context
                                          .read<SettingsCubit>()
                                          .state
                                          .gridSize,
                                    )),
                                child: AspectRatio(
                                  aspectRatio: 1,
                                  child: SelectableButtonCard(
                                    key: ValueKey(plan.recipe.id),
                                    title: plan.recipe.name,
                                    selected: true,
                                    description: plan.yields?.toString(),
                                    onPressed: () {
                                      cubit.remove(plan.recipe);
                                    },
                                    onLongPressed: () => _openRecipePage(
                                      context,
                                      cubit,
                                      plan.recipe,
                                      plan.yields,
                                    ),
                                  ),
                                ),
                              ),
                            for (final cookingDate in state.getUniqueCookingDays())
                              
                              for (final plan in state.getPlannedOfDate(cookingDate))
                                  
                                KitchenOwlFractionallySizedBox(
                                  widthFactor: (1 /
                                      DynamicStyling.itemCrossAxisCount(
                                        constraints.crossAxisExtent,
                                        context
                                            .read<SettingsCubit>()
                                            .state
                                            .gridSize,
                                      )),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      if (plan ==
                                          state.getPlannedOfDate(cookingDate)[0])
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 5),
                                          child: Text(
                                            '${_formatDate(daysBetween(DateTime.now(),cookingDate), context)}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyLarge,
                                          ),
                                        ),
                                      AspectRatio(
                                        aspectRatio: 1,
                                        child: SelectableButtonCard(
                                          key: ValueKey(
                                            plan.recipe.id,
                                          ),
                                          title: plan.recipe.name,
                                          description: plan.yields?.toString(),
                                          selected: true,
                                          onPressed: () {
                                            cubit.remove(
                                              plan.recipe,
                                              plan.cooking_date,
                                            );
                                          },
                                          onLongPressed: () => _openRecipePage(
                                            context,
                                            cubit,
                                            plan.recipe,
                                            plan.yields,
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
                          mobile: 365,
                          tablet: 405,
                          desktop: 405,
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
                  if (state.suggestedRecipes.isNotEmpty)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                      sliver: SliverToBoxAdapter(
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${AppLocalizations.of(context)!.recipesSuggested}:',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ),
                            LoadingIconButton(
                              onPressed: () async {
                                await cubit.refreshSuggestions();
                                suggestedRecipesScrollController.animateTo(
                                  0,
                                  duration: const Duration(milliseconds: 400),
                                  curve: Curves.easeIn,
                                );
                              },
                              icon: const Icon(Icons.shuffle_rounded),
                              tooltip: AppLocalizations.of(context)!.refresh,
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (state.suggestedRecipes.isNotEmpty)
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: getValueForScreenType(
                          context: context,
                          mobile: 365,
                          tablet: 405,
                          desktop: 405,
                        ),
                        child: ListView.builder(
                          controller: suggestedRecipesScrollController,
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
    Recipe recipe, [
    int? yields,
  ]) async {
    final household = BlocProvider.of<HouseholdCubit>(context).state.household;
    final res = await context.push<UpdateEnum>(
      Uri(
        path: "/household/${household.id}/recipes/details/${recipe.id}",
        queryParameters: {
          "updateOnPlanningEdit": true.toString(),
          if (yields != null) "selectedYields": yields.toString(),
        },
      ).toString(),
      extra: Tuple2<Household, Recipe>(household, recipe),
    );
    if (res == UpdateEnum.updated || res == UpdateEnum.deleted) {
      cubit.refresh();
    }
  }

  Future<void> _openItemSelectionPage(
    BuildContext context,
    PlannerCubit cubit,
  ) async {
    await Navigator.of(context, rootNavigator: true)
        .push<(ShoppingList?, List<RecipeItem>)>(
      MaterialPageRoute(
        builder: (ctx) => ItemSelectionPage(
          selectText: AppLocalizations.of(ctx)!.addNumberIngredients,
          plans: (cubit.state as LoadedPlannerCubitState).recipePlans,
          title: AppLocalizations.of(ctx)!.addItemTitle,
          shoppingLists: BlocProvider.of<ShoppinglistCubit>(context)
              .state
              .shoppinglists
              .values
              .toList(),
          handleResult: (list, res) async {
            list ??= BlocProvider.of<HouseholdCubit>(context)
                .state
                .household
                .defaultShoppingList;
            if (res.isNotEmpty && list != null) {
              await cubit.addItemsToList(
                list,
                res,
              );
            }

            return (list, res);
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
    final DateTime? cooking_date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 400)),
    );
    if (cooking_date != null) {
      await cubit.add(
        recipe,
        cooking_date.millisecondsSinceEpoch > 0 ? toEndOfDay(cooking_date) : null,
      );
    }
  }
}
