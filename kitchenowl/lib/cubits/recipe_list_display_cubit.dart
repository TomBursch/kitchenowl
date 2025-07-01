import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/models/recipe.dart';

typedef LoadMoreRecipes = Future<List<Recipe>?> Function(int page);

class RecipeListDisplayCubit extends Cubit<RecipeListDisplayState> {
  final LoadMoreRecipes? moreRecipes;
  final int pageSize;

  RecipeListDisplayCubit({
    this.moreRecipes,
    List<Recipe>? initialRecipes = const [],
    this.pageSize = 10,
  }) : super(RecipeListDisplayState(
          recipes: initialRecipes ?? const [],
          loadedPages: initialRecipes == null
              ? 0
              : (initialRecipes.length / pageSize).floor(),
        )) {
    if (initialRecipes == null) {
      loadMore();
    }
  }

  Future<void> loadMore() async {
    if (state.allLoaded || moreRecipes == null) return;

    final newRecipes = moreRecipes!(state.loadedPages);

    late List<Recipe> recipes;
    if (state.loadedPages == 0 && state.recipes.isNotEmpty) {
      recipes = List.from((await newRecipes) ?? state.recipes);
    } else {
      recipes = List.from(state.recipes + (await newRecipes ?? []));
    }

    emit(RecipeListDisplayState(
      recipes: recipes,
      allLoaded: (await newRecipes ?? []).length < pageSize,
      loadedPages: state.loadedPages + 1,
    ));
  }

  Future<void> refresh() async {
    if (moreRecipes == null) return;

    emit(RecipeListDisplayState());

    loadMore();
  }
}

class RecipeListDisplayState extends Equatable {
  final List<Recipe> recipes;
  final int loadedPages;
  final bool allLoaded;

  const RecipeListDisplayState({
    this.recipes = const [],
    this.allLoaded = false,
    this.loadedPages = 0,
  });

  @override
  List<Object?> get props => [recipes, loadedPages, allLoaded];
}
