import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:kitchenowl/app.dart';
import 'package:kitchenowl/cubits/recipe_cubit.dart';
import 'package:kitchenowl/cubits/settings_cubit.dart';
import 'package:kitchenowl/enums/update_enum.dart';
import 'package:kitchenowl/models/recipe.dart';
import 'package:kitchenowl/pages/recipe_add_update_page.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/widgets/shopping_item.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:url_launcher/url_launcher.dart';

class RecipePage extends StatefulWidget {
  final Recipe recipe;
  final bool updateOnPlanningEdit;

  const RecipePage({Key key, this.recipe, this.updateOnPlanningEdit = false})
      : super(key: key);

  @override
  _RecipePageState createState() => _RecipePageState();
}

class _RecipePageState extends State<RecipePage> {
  RecipeCubit cubit;

  @override
  void initState() {
    super.initState();
    cubit = RecipeCubit(widget.recipe);
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
    return BlocBuilder<RecipeCubit, RecipeState>(
        bloc: cubit,
        builder: (conext, state) => Scaffold(
              appBar: AppBar(
                title: Text(state.recipe.name),
                leading: BackButton(
                  onPressed: () =>
                      Navigator.of(context).pop(cubit.state.updateState),
                ),
                actions: [
                  if (!App.isOffline(context))
                    IconButton(
                      onPressed: () async {
                        final res = await Navigator.of(context)
                            .push<UpdateEnum>(MaterialPageRoute(
                                builder: (context) => AddUpdateRecipePage(
                                      recipe: state.recipe,
                                    )));
                        if (res == UpdateEnum.updated) {
                          cubit.setUpdateState(UpdateEnum.updated);
                          cubit.refresh();
                        }
                        if (res == UpdateEnum.deleted) {
                          Navigator.of(context).pop(UpdateEnum.deleted);
                        }
                      },
                      icon: const Icon(Icons.edit),
                    )
                ],
              ),
              body: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints.expand(width: 1600),
                  child: CustomScrollView(
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        sliver: SliverToBoxAdapter(
                          child: MarkdownBody(
                            data: state.recipe.description,
                            // imageBuilder: (uri, title, alt) => CachedNetworkImage(
                            //   imageUrl: uri.toString(),
                            //   placeholder: (context, url) => CircularProgressIndicator(),
                            //   errorWidget: (context, url, error) => Icon(Icons.error),
                            // ),
                            onTapLink: (text, href, title) async {
                              if (await canLaunch(href)) {
                                await launch(href);
                              }
                            },
                          ),
                        ),
                      ),
                      if (state.recipe.items
                          .where((e) => !e.optional)
                          .isNotEmpty)
                        SliverPadding(
                          padding: const EdgeInsets.all(16),
                          sliver: SliverToBoxAdapter(
                            child: Text(
                              AppLocalizations.of(context).items + ':',
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
                              onPressed: cubit.itemSelected,
                              selected: state.selectedItems.contains(state
                                  .recipe.items
                                  .where((e) => !e.optional)
                                  .elementAt(i)),
                              item: state.recipe.items
                                  .where((e) => !e.optional)
                                  .elementAt(i),
                            ),
                            childCount: state.recipe.items
                                .where((e) => !e.optional)
                                .length,
                          ),
                        ),
                      ),
                      if (state.recipe.items
                          .where((e) => e.optional)
                          .isNotEmpty)
                        SliverPadding(
                          padding: const EdgeInsets.all(16),
                          sliver: SliverToBoxAdapter(
                            child: Text(
                              AppLocalizations.of(context).itemsOptional + ':',
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
                              onPressed: cubit.itemSelected,
                              selected: state.selectedItems.contains(state
                                  .recipe.items
                                  .where((e) => e.optional)
                                  .elementAt(i)),
                              item: state.recipe.items
                                  .where((e) => e.optional)
                                  .elementAt(i),
                            ),
                            childCount: state.recipe.items
                                .where((e) => e.optional)
                                .length,
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.all(16),
                        sliver: SliverToBoxAdapter(
                          child: BlocBuilder<RecipeCubit, RecipeState>(
                            bloc: cubit,
                            builder: (conext, state) => ElevatedButton(
                              child: Text(AppLocalizations.of(context)
                                  .addNumberIngredients(
                                      state.selectedItems.length)),
                              onPressed: state.selectedItems.isEmpty
                                  ? null
                                  : () async {
                                      await cubit.addItemsToList();
                                      Navigator.of(context)
                                          .pop(UpdateEnum.unchanged);
                                    },
                            ),
                          ),
                        ),
                      ),
                      if (BlocProvider.of<SettingsCubit>(context)
                          .state
                          .serverSettings
                          .featurePlanner)
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          sliver: SliverToBoxAdapter(
                            child: ElevatedButton(
                              child: Text(AppLocalizations.of(context)
                                  .addRecipeToPlanner),
                              onPressed: () async {
                                await cubit.addRecipeToPlanner();
                                Navigator.of(context).pop(
                                    widget.updateOnPlanningEdit
                                        ? UpdateEnum.updated
                                        : UpdateEnum.unchanged);
                              },
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ));
  }
}
