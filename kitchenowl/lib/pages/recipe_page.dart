import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:kitchenowl/app.dart';
import 'package:kitchenowl/cubits/recipe_cubit.dart';
import 'package:kitchenowl/enums/update_enum.dart';
import 'package:kitchenowl/helpers/share.dart';
import 'package:kitchenowl/models/household.dart';
import 'package:kitchenowl/models/item.dart';
import 'package:kitchenowl/models/recipe.dart';
import 'package:kitchenowl/models/shoppinglist.dart';
import 'package:kitchenowl/pages/recipe_add_update_page.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/widgets/recipe_markdown_body.dart';
import 'package:kitchenowl/widgets/recipe_source_chip.dart';
import 'package:kitchenowl/widgets/sliver_with_pinned_footer.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:sliver_tools/sliver_tools.dart';
import 'package:tuple/tuple.dart';

int db_weekday(int shift) {
  // subtract 1 because DateTime.weekday goes from 1 to 7. Kitchenowl-db from 0 to 6
  return DateTime.now().add(Duration(days: shift)).weekday - 1;
}

String formatDateAsWeekday(DateTime date, BuildContext context,
    {String default_format = 'EEEE'}) {
  DateTime today = DateTime.now();
  DateTime tomorrow = today.add(Duration(days: 1));

  // Check if the date is today or tomorrow
  if (date.year == today.year &&
      date.month == today.month &&
      date.day == today.day) {
    return AppLocalizations.of(context)!.today;
  } else if (date.year == tomorrow.year &&
      date.month == tomorrow.month &&
      date.day == tomorrow.day) {
    return AppLocalizations.of(context)!.tomorrow;
  } else {
    // Return the weekday name
    return DateFormat(default_format).format(date);
  }
}

class RecipePage extends StatefulWidget {
  final Household? household;
  final Recipe recipe;
  final bool updateOnPlanningEdit;
  final int? selectedYields;

  const RecipePage({
    super.key,
    required this.recipe,
    this.household,
    this.updateOnPlanningEdit = false,
    this.selectedYields,
  });

  @override
  _RecipePageState createState() => _RecipePageState();
}

class _RecipePageState extends State<RecipePage> {
  late RecipeCubit cubit;

  @override
  void initState() {
    super.initState();
    cubit = RecipeCubit(
      widget.household,
      widget.recipe,
      widget.selectedYields,
    );
  }

  @override
  void dispose() {
    cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: cubit.state.updateState == UpdateEnum.unchanged,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) Navigator.of(context).pop(cubit.state.updateState);
      },
      child: BlocProvider.value(
        value: cubit,
        child: BlocConsumer<RecipeCubit, RecipeState>(
          bloc: cubit,
          listenWhen: (previous, current) => current is RecipeErrorState,
          listener: (context, state) {
            if (state is RecipeErrorState) {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                context.go("/");
              }
            }
          },
          builder: (context, state) {
            final left = <Widget>[
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate(
                    [
                      Wrap(
                        runSpacing: 8,
                        spacing: 5,
                        children: [
                          if (state.recipe.source.isNotEmpty)
                            RecipeSourceChip(
                              source: state.recipe.source,
                            ),
                          if ((state.recipe.time) > 0)
                            Chip(
                              avatar: Icon(
                                Icons.alarm_rounded,
                                color: Theme.of(context).colorScheme.onPrimary,
                              ),
                              label: Text(
                                "${state.recipe.time} ${AppLocalizations.of(context)!.minutesAbbrev}",
                                style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.onPrimary,
                                ),
                              ),
                              backgroundColor:
                                  Theme.of(context).colorScheme.primary,
                              elevation: 3,
                            ),
                          ...state.recipe.tags.map((e) => Chip(
                                key: Key(e.name),
                                label: Text(e.name),
                              )),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (state.recipe.prepTime > 0)
                        Text(
                          "${AppLocalizations.of(context)!.preparationTime}: ${state.recipe.prepTime} ${AppLocalizations.of(context)!.minutesAbbrev}",
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                      if (state.recipe.cookTime > 0)
                        Text(
                          "${AppLocalizations.of(context)!.cookingTime}: ${state.recipe.cookTime} ${AppLocalizations.of(context)!.minutesAbbrev}",
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                      if (state.recipe.prepTime + state.recipe.cookTime > 0)
                        const SizedBox(height: 16),
                      RecipeMarkdownBody(
                        recipe: state.recipe,
                      ),
                    ],
                  ),
                ),
              ),
            ];

            final right = SliverWithPinnedFooter(
              sliver: SliverMainAxisGroup(slivers: [
                if (state.recipe.yields > 0)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    sliver: SliverToBoxAdapter(
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              AppLocalizations.of(context)!.yields,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          NumberSelector(
                            value: state.selectedYields,
                            setValue: cubit.setSelectedYields,
                            defaultValue: state.recipe.yields,
                            lowerBound: 1,
                          ),
                        ],
                      ),
                    ),
                  ),
                if (state.recipe.items.where((e) => !e.optional).isNotEmpty)
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverToBoxAdapter(
                      child: Text(
                        '${AppLocalizations.of(context)!.ingredients}:',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                  ),
                if (state.recipe.items.where((e) => !e.optional).isNotEmpty)
                  SliverItemGridList(
                    items: state.dynamicRecipe.items
                        .where((e) => !e.optional)
                        .toList(),
                    selected: (item) => state.selectedItems.contains(item.name),
                    onPressed: Nullable(cubit.itemSelected),
                    onLongPressed:
                        const Nullable<void Function(RecipeItem)>.empty(),
                  ),
                if (state.recipe.items.where((e) => e.optional).isNotEmpty)
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverToBoxAdapter(
                      child: Text(
                        '${AppLocalizations.of(context)!.ingredientsOptional}:',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                  ),
                if (state.recipe.items.where((e) => e.optional).isNotEmpty)
                  SliverItemGridList(
                    items: state.dynamicRecipe.items
                        .where((e) => e.optional)
                        .toList(),
                    selected: (item) => state.selectedItems.contains(item.name),
                    onPressed: Nullable(cubit.itemSelected),
                    onLongPressed:
                        const Nullable<void Function(RecipeItem)>.empty(),
                  ),
              ]),
              footer: Container(
                color: Theme.of(context).colorScheme.surface,
                child: Column(
                  children: [
                    if (state.isOwningHousehold(state) &&
                        state.household!.defaultShoppingList != null &&
                        state.recipe.items.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Expanded(
                              child: LoadingElevatedButton(
                                onPressed: state.selectedItems.isEmpty
                                    ? null
                                    : cubit.addItemsToList,
                                child: Text(
                                  AppLocalizations.of(context)!
                                      .addNumberIngredients(
                                    state.selectedItems.length,
                                  ),
                                ),
                              ),
                            ),
                            if (state.shoppingLists.length > 1)
                              Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: LoadingElevatedButton(
                                  onPressed: state.selectedItems.isEmpty
                                      ? null
                                      : () async {
                                          ShoppingList? list =
                                              await showDialog<ShoppingList>(
                                            context: context,
                                            builder: (context) => SelectDialog(
                                              title:
                                                  AppLocalizations.of(context)!
                                                      .addNumberIngredients(
                                                          state.selectedItems
                                                              .length),
                                              cancelText:
                                                  AppLocalizations.of(context)!
                                                      .cancel,
                                              options: state.shoppingLists
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
                                            await cubit.addItemsToList(list);
                                          }
                                        },
                                  child: const Icon(Icons.shopping_bag_rounded),
                                ),
                              ),
                          ],
                        ),
                      ),
                    if (!App.isOffline &&
                        !state.isOwningHousehold(state) &&
                        state.household != null)
                      Container(
                        padding: const EdgeInsets.all(16),
                        width: double.infinity,
                        child: LoadingElevatedButton(
                          onPressed: () async {
                            if (state.household!.language == null ||
                                state.household!.language !=
                                    state.recipe.household?.language) {
                              final res = await context.push(Uri(
                                path:
                                    "/household/${state.household!.id}/recipes/scrape",
                                queryParameters: {
                                  "url":
                                      "kitchenowl:///recipe/${state.recipe.id}"
                                },
                              ).toString());
                              if (mounted &&
                                  res != null &&
                                  res == UpdateEnum.updated) {
                                Navigator.of(context).pop(UpdateEnum.updated);
                              }
                            } else {
                              final res = await cubit.addRecipeToHousehold();
                              if (mounted && res?.id != null) {
                                context.go(
                                  "/household/${state.household!.id}/recipes/details/${res!.id!}",
                                  extra: Tuple2(state.household!, res),
                                );
                              }
                            }
                          },
                          child: Text(
                            AppLocalizations.of(context)!
                                .recipeAddToHousehold(state.household!.name),
                          ),
                        ),
                      ),
                    if (state.isOwningHousehold(state) &&
                        (state.household!.featurePlanner ?? false))
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: LoadingElevatedButton(
                                child: Text(
                                  state.selectedYields != state.recipe.yields
                                      ? AppLocalizations.of(context)!
                                          .addRecipeToPlanner(
                                          state.selectedYields,
                                        )
                                      : AppLocalizations.of(context)!
                                          .addRecipeToPlannerShort,
                                ),
                                onPressed: () async {
                                  await cubit.addRecipeToPlanner(
                                    updateOnAdd: widget.updateOnPlanningEdit,
                                  );
                                  if (!mounted) return;
                                  Navigator.of(context).pop(
                                    widget.updateOnPlanningEdit
                                        ? UpdateEnum.updated
                                        : UpdateEnum.unchanged,
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            LoadingElevatedButton(
                              child: const Icon(Icons.calendar_month_rounded),
                              onPressed: () async {
                                int? day = await showDialog<int>(
                                  context: context,
                                  builder: (context) => SelectDialog(
                                    title: AppLocalizations.of(context)!
                                        .addRecipeToPlannerShort,
                                    cancelText:
                                        AppLocalizations.of(context)!.cancel,
                                    options: List.generate(7, (index) {
                                      return SelectDialogOption(
                                          db_weekday(index),
                                          formatDateAsWeekday(
                                              DateTime.now()
                                                  .add(Duration(days: index)),
                                              context));
                                    }),
                                  ),
                                );
                                if (day != null) {
                                  await cubit.addRecipeToPlanner(
                                    day: day >= 0 ? day : null,
                                    updateOnAdd: widget.updateOnPlanningEdit,
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    SizedBox(
                      height: MediaQuery.paddingOf(context).bottom,
                    ),
                  ],
                ),
              ),
            );

            return Scaffold(
              body: Align(
                alignment: Alignment.topCenter,
                child: CustomScrollView(
                  primary: true,
                  slivers: [
                    SliverImageAppBar(
                      title: state.recipe.name,
                      imageUrl: state.recipe.image,
                      imageHash: state.recipe.imageHash,
                      popValue: () => cubit.state.updateState,
                      actions: (isCollapsed) => [
                        if (state.recipe.public)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: LoadingIconButton(
                              tooltip: AppLocalizations.of(context)!.share,
                              variant: state.recipe.image == null ||
                                      state.recipe.image!.isEmpty ||
                                      isCollapsed
                                  ? LoadingIconButtonVariant.standard
                                  : LoadingIconButtonVariant.filledTonal,
                              onPressed: () async {
                                final uri = Uri.tryParse(App.currentServer +
                                    '/recipe/${widget.recipe.id}');
                                if (uri == null) return;

                                Share.shareUri(context, uri);
                              },
                              icon: Icon(Icons.adaptive.share_rounded),
                            ),
                          ),
                        if (!App.isOffline && state.isOwningHousehold(state))
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: LoadingIconButton(
                              tooltip: AppLocalizations.of(context)!.recipeEdit,
                              variant: state.recipe.image == null ||
                                      state.recipe.image!.isEmpty ||
                                      isCollapsed
                                  ? LoadingIconButtonVariant.standard
                                  : LoadingIconButtonVariant.filledTonal,
                              onPressed: () async {
                                final res = await Navigator.of(context)
                                    .push<UpdateEnum>(MaterialPageRoute(
                                  builder: (context) => AddUpdateRecipePage(
                                    household: state.household!,
                                    recipe: state.recipe,
                                  ),
                                ));
                                if (res == UpdateEnum.updated) {
                                  cubit.setUpdateState(UpdateEnum.updated);
                                  await cubit.refresh();
                                }
                                if (res == UpdateEnum.deleted) {
                                  if (!mounted) return;
                                  Navigator.of(context).pop(UpdateEnum.deleted);
                                }
                              },
                              icon: const Icon(Icons.edit),
                            ),
                          ),
                      ],
                    ),
                    SliverCrossAxisConstrained(
                      maxCrossAxisExtent: 1600,
                      child: getValueForScreenType<Widget>(
                        context: context,
                        mobile: SliverMainAxisGroup(
                          slivers: left + [right],
                        ),
                        tablet: SliverCrossAxisGroup(
                          slivers: [
                            SliverMainAxisGroup(
                              slivers: left +
                                  [
                                    SliverToBoxAdapter(
                                      child: SizedBox(
                                        height: MediaQuery.paddingOf(context)
                                            .bottom,
                                      ),
                                    ),
                                  ],
                            ),
                            right,
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
