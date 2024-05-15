import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';
import 'package:kitchenowl/app.dart';
import 'package:kitchenowl/cubits/recipe_cubit.dart';
import 'package:kitchenowl/enums/update_enum.dart';
import 'package:kitchenowl/helpers/recipe_item_markdown_extension.dart';
import 'package:kitchenowl/helpers/url_launcher.dart';
import 'package:kitchenowl/models/household.dart';
import 'package:kitchenowl/models/item.dart';
import 'package:kitchenowl/models/recipe.dart';
import 'package:kitchenowl/models/shoppinglist.dart';
import 'package:kitchenowl/pages/recipe_add_update_page.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/widgets/recipe_source_chip.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:kitchenowl/widgets/sliver_with_pinned_footer.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:responsive_builder/responsive_builder.dart';
import 'package:sliver_tools/sliver_tools.dart';

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
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) Navigator.of(context).pop(cubit.state.updateState);
      },
      child: BlocBuilder<RecipeCubit, RecipeState>(
        bloc: cubit,
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
                                color: Theme.of(context).colorScheme.onPrimary,
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
                      ),
                    if (state.recipe.cookTime > 0)
                      Text(
                        "${AppLocalizations.of(context)!.cookingTime}: ${state.recipe.cookTime} ${AppLocalizations.of(context)!.minutesAbbrev}",
                      ),
                    if (state.recipe.prepTime + state.recipe.cookTime > 0)
                      const SizedBox(height: 16),
                    MarkdownBody(
                      data: state.recipe.description,
                      shrinkWrap: true,
                      styleSheet: MarkdownStyleSheet.fromTheme(
                        Theme.of(context),
                      ).copyWith(
                        blockquoteDecoration: BoxDecoration(
                          color: Theme.of(context).cardTheme.color ??
                              Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(2.0),
                        ),
                      ),
                      imageBuilder: (uri, title, alt) => CachedNetworkImage(
                        imageUrl: uri.toString(),
                        placeholder: (context, url) =>
                            const CircularProgressIndicator(),
                        errorWidget: (context, url, error) =>
                            const Icon(Icons.error),
                      ),
                      onTapLink: (text, href, title) {
                        if (href != null && isValidUrl(href)) {
                          openUrl(context, href);
                        }
                      },
                      builders: <String, MarkdownElementBuilder>{
                        'recipeItem': RecipeItemMarkdownBuilder(
                          cubit: cubit,
                        ),
                      },
                      extensionSet: md.ExtensionSet(
                        md.ExtensionSet.gitHubWeb.blockSyntaxes,
                        md.ExtensionSet.gitHubWeb.inlineSyntaxes +
                            [
                              RecipeItemMarkdownSyntax(
                                state.recipe,
                              ),
                            ],
                      ),
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
                  if (widget.household != null &&
                      widget.household!.defaultShoppingList != null &&
                      state.recipe.items.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: BlocBuilder<RecipeCubit, RecipeState>(
                        bloc: cubit,
                        builder: (context, state) => Row(
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
                    ),
                  if (widget.household != null &&
                      (widget.household!.featurePlanner ?? false))
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
                                  title: AppLocalizations.of(context)!
                                      .addRecipeToPlannerShort,
                                  cancelText:
                                      AppLocalizations.of(context)!.cancel,
                                  options: weekdayMapping.entries
                                      .map(
                                        (e) => SelectDialogOption(
                                          e.key,
                                          DateFormat.E()
                                              .dateSymbols
                                              .STANDALONEWEEKDAYS[e.value % 7],
                                        ),
                                      )
                                      .toList(),
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
                    height: MediaQuery.of(context).padding.bottom,
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
                  SliverAppBar(
                    flexibleSpace: FlexibleImageSpaceBar(
                      title: state.recipe.name,
                      imageUrl: state.recipe.image,
                      imageHash: state.recipe.imageHash,
                    ),
                    leading: BackButton(
                      onPressed: () =>
                          Navigator.of(context).pop(cubit.state.updateState),
                    ),
                    expandedHeight: state.recipe.image?.isNotEmpty ?? false
                        ? (MediaQuery.of(context).size.height / 3.3)
                            .clamp(160, 350)
                        : null,
                    pinned: true,
                    actions: [
                      if (!App.isOffline && widget.household != null)
                        LoadingIconButton(
                          tooltip: AppLocalizations.of(context)!.recipeEdit,
                          onPressed: () async {
                            final res = await Navigator.of(context)
                                .push<UpdateEnum>(MaterialPageRoute(
                              builder: (context) => AddUpdateRecipePage(
                                household: widget.household!,
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
                                      height:
                                          MediaQuery.of(context).padding.bottom,
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
    );
  }
}
