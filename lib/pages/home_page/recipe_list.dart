import 'package:alphabet_scroll_view/alphabet_scroll_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/cubits/recipe_list_cubit.dart';
import 'package:kitchenowl/enums/update_enum.dart';
import 'package:kitchenowl/models/recipe.dart';
import 'package:kitchenowl/pages/recipe_page.dart';
import 'package:kitchenowl/services/api/api_service.dart';
import 'package:kitchenowl/kitchenowl.dart';

class RecipeListPage extends StatefulWidget {
  RecipeListPage({Key key}) : super(key: key);

  @override
  _RecipeListPageState createState() => _RecipeListPageState();
}

class _RecipeListPageState extends State<RecipeListPage> {
  final List<Widget> favouriteList = [];
  final TextEditingController searchController = TextEditingController();
  final RecipeListCubit cubit = RecipeListCubit();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          SizedBox(
            height: 80,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: BlocListener<RecipeListCubit, ListRecipeCubitState>(
                cubit: cubit,
                listener: (context, state) {
                  if (!(state is SearchRecipeCubitState)) {
                    if (searchController.text.isNotEmpty) {
                      searchController.clear();
                    }
                  }
                },
                child: TextField(
                  key: ValueKey<String>('SearchTextField'),
                  controller: searchController,
                  onChanged: (s) => cubit.search(s),
                  textInputAction: TextInputAction.search,
                  onSubmitted: (text) => FocusScope.of(context).unfocus(),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.search),
                    suffix: IconButton(
                      onPressed: () {
                        if (searchController.text.isNotEmpty) {
                          cubit.search('');
                        }
                        FocusScope.of(context).unfocus();
                      },
                      icon: Icon(
                        Icons.close,
                        color: Colors.grey,
                      ),
                    ),
                    labelText: AppLocalizations.of(context).searchHint,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: cubit.refresh,
              child: BlocBuilder<RecipeListCubit, ListRecipeCubitState>(
                  cubit: cubit,
                  builder: (context, state) {
                    final recipes = state.recipes;
                    return AlphabetScrollView(
                      list: recipes.map((e) => AlphaModel(e.name)).toList(),
                      alignment: LetterAlignment.left,
                      // isAlphabetsFiltered: state is SearchRecipeCubitState,
                      waterMark: (value) => Container(
                        height: 50,
                        width: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Theme.of(context).primaryColor,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          value.toUpperCase(),
                          style: TextStyle(fontSize: 20, color: Colors.white),
                        ),
                      ),
                      itemExtent: 65,
                      itemBuilder: (context, index, name) {
                        return Padding(
                          padding: const EdgeInsets.only(left: 32, right: 16),
                          child: Card(
                            child: ListTile(
                              title: Text(recipes[index].name),
                              trailing: Icon(Icons.arrow_right_rounded),
                              onTap: () async {
                                final recipe = await ApiService.getInstance()
                                    .getRecipe(recipes[index]);
                                final res = await Navigator.of(context)
                                    .push<UpdateEnum>(MaterialPageRoute(
                                        builder: (context) => RecipePage(
                                              recipe: recipe ?? recipes[index],
                                            )));
                                if (res == UpdateEnum.updated ||
                                    res == UpdateEnum.deleted) cubit.refresh();
                              },
                            ),
                          ),
                        );
                      },
                    );
                  }),
            ),
          ),
        ],
      ),
    );
  }
}
