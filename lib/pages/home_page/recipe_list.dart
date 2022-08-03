import 'package:azlistview/azlistview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/cubits/recipe_list_cubit.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/widgets/recipe_item.dart';
import 'package:responsive_builder/responsive_builder.dart';

class RecipeListPage extends StatefulWidget {
  const RecipeListPage({Key? key}) : super(key: key);

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

    final bool useBottomNavigationBar = getValueForScreenType<bool>(
      context: context,
      mobile: true,
      tablet: false,
      desktop: false,
    );

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
          BlocBuilder<RecipeListCubit, RecipeListState>(
            bloc: cubit,
            builder: (context, state) {
              if (state is! ListRecipeListState ||
                  state.tags.isEmpty ||
                  state is SearchRecipeListState) {
                return const SizedBox();
              }

              return Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    controller: ScrollController(),
                    child: Row(
                      children: const <Widget>[SizedBox(width: 12)] +
                          state.tags.map((tag) {
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4),
                              child: FilterChip(
                                label: Text(
                                  tag.name,
                                  style: TextStyle(
                                    color:
                                        (state is FilteredListRecipeListState) &&
                                                state.selectedTags.contains(tag)
                                            ? Theme.of(context)
                                                .colorScheme
                                                .onPrimary
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
                          }).toList()
                        ..add(const SizedBox(width: 12)),
                    ),
                  ),
                ),
              );
            },
          ),
          Expanded(
            child: BlocBuilder<RecipeListCubit, RecipeListState>(
              bloc: cubit,
              buildWhen: (previous, current) =>
                  previous is! ListRecipeListState ||
                  current is! ListRecipeListState ||
                  !listEquals(previous.recipes, current.recipes),
              builder: (context, state) {
                if (state is! ListRecipeListState) {
                  return Padding(
                    padding: const EdgeInsets.only(left: 28, right: 12),
                    child: Column(
                      children: const [
                        ShimmerCard(),
                        ShimmerCard(),
                        ShimmerCard(),
                      ],
                    ),
                  );
                }
                final recipes = state.recipes;

                if (recipes.isEmpty) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Icon(Icons.no_food_rounded),
                      const SizedBox(height: 16),
                      Text(state is SearchRecipeListState
                          ? AppLocalizations.of(context)!.recipeEmptySearch
                          : AppLocalizations.of(context)!.recipeEmpty),
                    ],
                  );
                }

                return Scrollbar(
                  child: RefreshIndicator(
                    onRefresh: cubit.refresh,
                    child: AzListView(
                      itemCount: recipes.length,
                      data: recipes,
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
                              .withOpacity(1),
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
                        indexHintOffset:
                            Offset(useBottomNavigationBar ? 0 : 216, 0),
                      ),
                      hapticFeedback: true,
                      itemBuilder: (context, i) {
                        return Padding(
                          key: Key(recipes[i].name),
                          padding: const EdgeInsets.only(left: 32, right: 16),
                          child: RecipeItemWidget(
                            recipe: recipes[i],
                            onUpdated: cubit.refresh,
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
