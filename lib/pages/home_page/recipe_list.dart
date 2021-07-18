import 'package:alphabet_scroll_view/alphabet_scroll_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/cubits/auth_cubit.dart';
import 'package:kitchenowl/cubits/recipe_list_cubit.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/widgets/recipe_item.dart';
import 'package:kitchenowl/widgets/search_text_field.dart';

class RecipeListPage extends StatefulWidget {
  RecipeListPage({Key key}) : super(key: key);

  @override
  _RecipeListPageState createState() => _RecipeListPageState();
}

class _RecipeListPageState extends State<RecipeListPage> {
  final List<Widget> favouriteList = [];
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    searchController.text =
        BlocProvider.of<RecipeListCubit>(context)?.query ?? "";
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
            height: 80,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: BlocListener<RecipeListCubit, ListRecipeCubitState>(
                bloc: cubit,
                listener: (context, state) {
                  if (!(state is SearchRecipeCubitState)) {
                    if (searchController.text.isNotEmpty) {
                      searchController.clear();
                    }
                  }
                },
                child: SearchTextField(
                  controller: searchController,
                  onSearch: (s) => cubit.search(s),
                  textInputAction: TextInputAction.search,
                  onSubmitted: () => FocusScope.of(context).unfocus(),
                ),
              ),
            ),
          ),
          Expanded(
            child: BlocBuilder<RecipeListCubit, ListRecipeCubitState>(
                bloc: cubit,
                builder: (context, state) {
                  if (BlocProvider.of<AuthCubit>(context).state
                      is AuthenticatedOffline) {
                    return Center(
                        child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(AppLocalizations.of(context).offlineMessage),
                        const SizedBox(width: 5),
                        Icon(Icons.cloud_off_rounded)
                      ],
                    ));
                  }
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
                            style: TextStyle(fontSize: 20, color: Colors.white),
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
