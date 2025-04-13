import 'package:azlistview_plus/azlistview_plus.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/cubits/recipe_list_cubit.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/widgets/choice_scroll.dart';
import 'package:kitchenowl/widgets/recipe_card.dart';
import 'package:kitchenowl/widgets/recipe_item.dart';

class RecipeListPage extends StatefulWidget {
  const RecipeListPage({super.key});

  @override
  _RecipeListPageState createState() => _RecipeListPageState();
}

class _RecipeListPageState extends State<RecipeListPage> {
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    searchController.text = BlocProvider.of<RecipeListCubit>(context).query;
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = BlocProvider.of<RecipeListCubit>(context);

    return SafeArea(
      child: Column(
        children: [
          SizedBox(
            height: 70,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
              child: BlocListener<RecipeListCubit, RecipeListState>(
                bloc: cubit,
                listener: (context, state) {
                  if (state is! SearchRecipeListState) {
                    if (searchController.text.isNotEmpty) {
                      searchController.clear();
                    }
                  }
                },
                child: SearchTextField(
                  controller: searchController,
                  clearOnSubmit: false,
                  onSearch: (s) => cubit.search(s),
                  textInputAction: TextInputAction.search,
                ),
              ),
            ),
          ),
          Expanded(
            child: BlocBuilder<RecipeListCubit, RecipeListState>(
              bloc: cubit,
              builder: (context, state) {
                Widget header = Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: TrailingIconTextButton(
                    onPressed: cubit.toggleView,
                    text: state.listView
                        ? AppLocalizations.of(context)!.sortingAlphabetical
                        : AppLocalizations.of(context)!.grid,
                    icon: Icon(state.listView
                        ? Icons.view_agenda_rounded
                        : Icons.grid_view_rounded),
                  ),
                );
                if (state is! ListRecipeListState ||
                    state.tags.isEmpty ||
                    state is SearchRecipeListState) {
                  header = Align(
                    alignment: Alignment.topRight,
                    child: header,
                  );
                } else {
                  header = Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: LeftRightWrap(
                        crossAxisSpacing: 6,
                        left: ChoiceScroll(
                            children: state.tags
                                .sorted((a, b) =>
                                    (state is FilteredListRecipeListState)
                                        ? state.selectedTags
                                            .contains(a)
                                            .hashCode
                                            .compareTo(state.selectedTags
                                                .contains(b)
                                                .hashCode)
                                        : 0)
                                .map((tag) {
                          return Padding(
                            key: ValueKey(tag.id),
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: FilterChip(
                              label: Text(
                                tag.name,
                                style: TextStyle(
                                  color: (state
                                              is FilteredListRecipeListState) &&
                                          state.selectedTags.contains(tag)
                                      ? Theme.of(context).colorScheme.onPrimary
                                      : null,
                                ),
                              ),
                              selected:
                                  (state is FilteredListRecipeListState) &&
                                      state.selectedTags.contains(tag),
                              selectedColor:
                                  Theme.of(context).colorScheme.secondary,
                              onSelected: (bool selected) =>
                                  cubit.tagSelected(tag, selected),
                            ),
                          );
                        }).toList()),
                        right: header,
                      ),
                    ),
                  );
                }

                if (state is! ListRecipeListState) {
                  return Column(
                    children: [
                      header,
                      const Padding(
                        padding: EdgeInsets.only(left: 28, right: 12),
                        child: ShimmerCard(
                            trailing: Icon(Icons.arrow_right_rounded)),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(left: 28, right: 12),
                        child: ShimmerCard(
                            trailing: Icon(Icons.arrow_right_rounded)),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(left: 28, right: 12),
                        child: ShimmerCard(
                            trailing: Icon(Icons.arrow_right_rounded)),
                      ),
                    ],
                  );
                }
                final recipes = state.recipes;

                if (recipes.isEmpty) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      header,
                      const Spacer(),
                      const Icon(Icons.no_food_rounded),
                      const SizedBox(height: 16),
                      Text(state is SearchRecipeListState ||
                              state is FilteredListRecipeListState
                          ? AppLocalizations.of(context)!.recipeEmptySearch
                          : AppLocalizations.of(context)!.recipeEmpty),
                      const Spacer(),
                    ],
                  );
                }

                Widget child;
                if (state.listView) {
                  child = AzListView(
                    itemCount: recipes.length + 1,
                    data: <ISuspensionBean>[
                          _HeaderBean(recipes.first.getSuspensionTag())
                        ] +
                        recipes,
                    indexBarData: SuspensionUtil.getTagIndexList(recipes),
                    indexBarAlignment: Alignment.centerLeft,
                    indexBarOptions: IndexBarOptions(
                      needRebuild: true,
                      selectTextStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                      selectItemDecoration: const BoxDecoration(),
                      indexHintWidth: 50,
                      indexHintHeight: 50,
                      indexHintDecoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withAlpha(0xFF),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black54,
                            offset: Offset(1, 1),
                            blurRadius: 6,
                            spreadRadius: -2,
                          ),
                        ],
                      ),
                      indexHintTextStyle: TextStyle(
                        fontSize: 20,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                      indexHintAlignment: Alignment.centerLeft,
                    ),
                    hapticFeedback: true,
                    itemBuilder: (context, i) {
                      if (i == 0) return header;
                      i--;
                      return Padding(
                        key: Key(recipes[i].name),
                        padding: const EdgeInsets.only(left: 32, right: 16),
                        child: RecipeItemWidget(
                          recipe: recipes[i],
                          onUpdated: cubit.refresh,
                        ),
                      );
                    },
                  );
                } else {
                  child = CustomScrollView(
                    primary: true,
                    slivers: [
                      SliverToBoxAdapter(child: header),
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        sliver: SliverGrid.builder(
                          itemCount: recipes.length,
                          gridDelegate:
                              const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 350,
                            childAspectRatio: 0.8,
                          ),
                          itemBuilder: (context, i) => RecipeCard(
                            key: Key(recipes[i].name),
                            recipe: recipes[i],
                            onUpdated: cubit.refresh,
                          ),
                        ),
                      ),
                    ],
                  );
                }

                return RefreshIndicator(
                  onRefresh: cubit.refresh,
                  child: child,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderBean implements ISuspensionBean {
  String suspensionTag;

  _HeaderBean(this.suspensionTag);

  @override
  bool get isShowSuspension => true;

  @override
  String getSuspensionTag() => suspensionTag;

  @override
  set isShowSuspension(bool _isShowSuspension) {}
}
