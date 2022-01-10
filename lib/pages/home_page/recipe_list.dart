import 'package:alphabet_scroll_view/alphabet_scroll_view.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/cubits/recipe_list_cubit.dart';
import 'package:kitchenowl/widgets/recipe_item.dart';
import 'package:kitchenowl/widgets/search_text_field.dart';

class RecipeListPage extends StatefulWidget {
  const RecipeListPage({Key? key}) : super(key: key);

  @override
  _RecipeListPageState createState() => _RecipeListPageState();
}

class _RecipeListPageState extends State<RecipeListPage> {
  final List<Widget> favouriteList = [];
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
              child: BlocListener<RecipeListCubit, ListRecipeCubitState>(
                bloc: cubit,
                listener: (context, state) {
                  if (state is! SearchRecipeCubitState) {
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
                  onSubmitted: () => FocusScope.of(context).unfocus(),
                ),
              ),
            ),
          ),
          BlocBuilder<RecipeListCubit, ListRecipeCubitState>(
              bloc: cubit,
              builder: (context, state) {
                if (state.tags.isEmpty || state is SearchRecipeCubitState) {
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
                                  label: Text(tag.name),
                                  selected:
                                      (state is FilteredListRecipeCubitState) &&
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
              }),
          Expanded(
            child: BlocBuilder<RecipeListCubit, ListRecipeCubitState>(
                bloc: cubit,
                buildWhen: (previous, current) =>
                    !listEquals(previous.recipes, current.recipes),
                builder: (context, state) {
                  final recipes = state.recipes;
                  return Scrollbar(
                    child: RefreshIndicator(
                      onRefresh: cubit.refresh,
                      child: AlphabetScrollView(
                        list: recipes.map((e) => AlphaModel(e.name)).toList(),
                        alignment: LetterAlignment.left,
                        // isAlphabetsFiltered: state is SearchRecipeCubitState,
                        overlayWidget: (value) => Container(
                          height: 50,
                          width: 50,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Theme.of(context).primaryColor,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            value.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 20,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        itemExtent: 65,
                        itemBuilder: (context, index, name) {
                          return Padding(
                            padding: const EdgeInsets.only(left: 32, right: 16),
                            child: RecipeItemWidget(
                              recipe: recipes[index],
                              onUpdated: cubit.refresh,
                            ),
                          );
                        },
                        selectedTextStyle:
                            const TextStyle(fontWeight: FontWeight.bold),
                        unselectedTextStyle: const TextStyle(),
                      ),
                    ),
                  );
                }),
          ),
        ],
      ),
    );
  }
}
