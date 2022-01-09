import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/models/recipe.dart';
import 'package:kitchenowl/models/tag.dart';
import 'package:kitchenowl/services/transaction_handler.dart';
import 'package:kitchenowl/services/transactions/recipe.dart';
import 'package:kitchenowl/services/transactions/tag.dart';

class RecipeListCubit extends Cubit<ListRecipeCubitState> {
  List<Recipe> recipeList = [];

  RecipeListCubit() : super(const ListRecipeCubitState()) {
    refresh();
  }

  String get query => (state is SearchRecipeCubitState)
      ? (state as SearchRecipeCubitState).query
      : "";

  Future<void> search(String query) {
    return refresh(query);
  }

  void tagSelected(Tag tag, bool selected) {
    if (state is FilteredListRecipeCubitState) {
      final _state = state as FilteredListRecipeCubitState;
      final selectedTags = Set<Tag>.from(_state.selectedTags);
      if (selected) {
        selectedTags.add(tag);
      } else {
        selectedTags.removeWhere((e) => e.id == tag.id);
      }
      if (selectedTags.isEmpty) {
        emit(
            ListRecipeCubitState(recipes: _state.allRecipes, tags: state.tags));
      } else {
        emit(_state.copyWith(
            selectedTags: selectedTags,
            recipes: _getFilteredRecipesCopy(
              _state.allRecipes,
              selectedTags,
            )));
      }
    } else if (selected) {
      emit(FilteredListRecipeCubitState.fromState(state, tag));
    }
  }

  Future<void> refresh([String? query]) async {
    if (state is SearchRecipeCubitState) {
      query = query ?? (state as SearchRecipeCubitState).query;
    }

    if (query != null && query.isNotEmpty) {
      final items = (await TransactionHandler.getInstance()
          .runTransaction(TransactionRecipeSearchRecipes(query: query)));
      emit(SearchRecipeCubitState(
          query: query, recipes: items, tags: state.tags));
    } else {
      Set<Tag> filter = const {};
      if (state is FilteredListRecipeCubitState && (query == null)) {
        filter = (state as FilteredListRecipeCubitState).selectedTags;
      }

      recipeList = await TransactionHandler.getInstance()
          .runTransaction(TransactionRecipeGetRecipes());
      final tags = await TransactionHandler.getInstance()
          .runTransaction(TransactionTagGetAll());
      if (filter.isNotEmpty) {
        emit(FilteredListRecipeCubitState(
          recipes: _getFilteredRecipesCopy(recipeList, filter),
          tags: tags,
          selectedTags: filter,
          allRecipes: recipeList,
        ));
      } else {
        emit(ListRecipeCubitState(recipes: recipeList, tags: tags));
      }
    }
  }

  List<Recipe> _getFilteredRecipesCopy(
          List<Recipe> allRecipes, Set<Tag> filter) =>
      List<Recipe>.from(
          allRecipes.where((e) => e.tags.any((tag) => filter.contains(tag))));
}

class ListRecipeCubitState extends Equatable {
  final List<Recipe> recipes;
  final Set<Tag> tags;

  const ListRecipeCubitState({this.recipes = const [], this.tags = const {}});

  @override
  List<Object?> get props => <Object?>[tags] + recipes;
}

class FilteredListRecipeCubitState extends ListRecipeCubitState {
  final Set<Tag> selectedTags;
  final List<Recipe> allRecipes;

  const FilteredListRecipeCubitState({
    this.selectedTags = const {},
    this.allRecipes = const [],
    List<Recipe> recipes = const [],
    Set<Tag> tags = const {},
  }) : super(recipes: recipes, tags: tags);

  factory FilteredListRecipeCubitState.fromState(
    ListRecipeCubitState state,
    Tag selectedTag,
  ) =>
      FilteredListRecipeCubitState(
        recipes: List<Recipe>.from(
            state.recipes.where((e) => e.tags.contains(selectedTag))),
        allRecipes: state.recipes,
        tags: state.tags,
        selectedTags: {selectedTag},
      );

  FilteredListRecipeCubitState copyWith({
    List<Recipe>? recipes,
    Set<Tag>? tags,
    Set<Tag>? selectedTags,
  }) =>
      FilteredListRecipeCubitState(
        recipes: recipes ?? this.recipes,
        tags: tags ?? this.tags,
        selectedTags: selectedTags ?? this.selectedTags,
        allRecipes: allRecipes,
      );

  @override
  List<Object?> get props => super.props + [selectedTags];
}

class SearchRecipeCubitState extends ListRecipeCubitState {
  final String query;

  const SearchRecipeCubitState({
    required this.query,
    List<Recipe> recipes = const [],
    Set<Tag> tags = const {},
  }) : super(recipes: recipes, tags: tags);

  @override
  List<Object?> get props => super.props + [query];
}
