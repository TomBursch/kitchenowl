import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/models/recipe.dart';
import 'package:kitchenowl/models/tag.dart';
import 'package:kitchenowl/services/transaction_handler.dart';
import 'package:kitchenowl/services/transactions/recipe.dart';
import 'package:kitchenowl/services/transactions/tag.dart';

class RecipeListCubit extends Cubit<RecipeListState> {
  List<Recipe> recipeList = [];
  bool _refreshLock = false;
  String? _refreshCurrentQuery;

  RecipeListCubit() : super(const LoadingRecipeListState()) {
    refresh();
  }

  String get query => (state is SearchRecipeListState)
      ? (state as SearchRecipeListState).query
      : "";

  Future<void> search(String query) {
    return refresh(query);
  }

  void tagSelected(Tag tag, bool selected) {
    if (state is FilteredListRecipeListState) {
      final _state = state as FilteredListRecipeListState;
      final selectedTags = Set<Tag>.from(_state.selectedTags);
      if (selected) {
        selectedTags.add(tag);
      } else {
        selectedTags.removeWhere((e) => e.id == tag.id);
      }
      if (selectedTags.isEmpty) {
        emit(
          ListRecipeListState(recipes: _state.allRecipes, tags: _state.tags),
        );
      } else {
        emit(_state.copyWith(
          selectedTags: selectedTags,
          recipes: _getFilteredRecipesCopy(
            _state.allRecipes,
            selectedTags,
          ),
        ));
      }
    } else if (selected) {
      emit(FilteredListRecipeListState.fromState(
        state as ListRecipeListState,
        tag,
      ));
    }
  }

  Future<void> refresh([String? query]) async {
    final state = this.state;
    if (state is SearchRecipeListState) {
      query = query ?? state.query;
    }
    if (_refreshLock && query == _refreshCurrentQuery) return;
    _refreshLock = true;
    _refreshCurrentQuery = query;
    late ListRecipeListState _state;
    if (state is ListRecipeListState &&
        state is! SearchRecipeListState &&
        state is! FilteredListRecipeListState &&
        state.recipes.isEmpty) {
      emit(const LoadingRecipeListState());
    }

    if (query != null && query.isNotEmpty) {
      final tags = TransactionHandler.getInstance()
          .runTransaction(TransactionTagGetAll());
      final items = TransactionHandler.getInstance()
          .runTransaction(TransactionRecipeSearchRecipes(query: query));

      _state = SearchRecipeListState(
        query: query,
        recipes: await items,
        tags: await tags,
      );
    } else {
      final tags = TransactionHandler.getInstance()
          .runTransaction(TransactionTagGetAll());
      recipeList = await TransactionHandler.getInstance()
          .runTransaction(TransactionRecipeGetRecipes());
      Set<Tag> filter = const {};
      if (state is FilteredListRecipeListState && (query == null)) {
        filter = state.selectedTags;
      }
      _state = filter.isNotEmpty
          ? FilteredListRecipeListState(
              recipes: _getFilteredRecipesCopy(recipeList, filter),
              tags: await tags,
              selectedTags: filter,
              allRecipes: recipeList,
            )
          : ListRecipeListState(recipes: recipeList, tags: await tags);
    }
    if (query == _refreshCurrentQuery) {
      emit(_state);
      _refreshLock = false;
    }
  }

  List<Recipe> _getFilteredRecipesCopy(
    List<Recipe> allRecipes,
    Set<Tag> filter,
  ) =>
      List<Recipe>.from(
        allRecipes.where((e) => e.tags.containsAll(filter)),
      );
}

abstract class RecipeListState extends Equatable {
  const RecipeListState();
}

class LoadingRecipeListState extends RecipeListState {
  const LoadingRecipeListState();
  @override
  List<Object?> get props => const [];
}

class ListRecipeListState extends RecipeListState {
  final List<Recipe> recipes;
  final Set<Tag> tags;

  const ListRecipeListState({this.recipes = const [], this.tags = const {}});

  @override
  List<Object?> get props => <Object?>[tags] + recipes;
}

class FilteredListRecipeListState extends ListRecipeListState {
  final Set<Tag> selectedTags;
  final List<Recipe> allRecipes;

  const FilteredListRecipeListState({
    this.selectedTags = const {},
    this.allRecipes = const [],
    super.recipes = const [],
    super.tags = const {},
  });

  factory FilteredListRecipeListState.fromState(
    ListRecipeListState state,
    Tag selectedTag,
  ) =>
      FilteredListRecipeListState(
        recipes: List<Recipe>.from(
          state.recipes.where((e) => e.tags.contains(selectedTag)),
        ),
        allRecipes: state.recipes,
        tags: state.tags,
        selectedTags: {selectedTag},
      );

  FilteredListRecipeListState copyWith({
    List<Recipe>? recipes,
    Set<Tag>? tags,
    Set<Tag>? selectedTags,
  }) =>
      FilteredListRecipeListState(
        recipes: recipes ?? this.recipes,
        tags: tags ?? this.tags,
        selectedTags: selectedTags ?? this.selectedTags,
        allRecipes: allRecipes,
      );

  @override
  List<Object?> get props => super.props + [selectedTags];
}

class SearchRecipeListState extends ListRecipeListState {
  final String query;

  const SearchRecipeListState({
    required this.query,
    super.recipes = const [],
    super.tags = const {},
  });

  @override
  List<Object?> get props => super.props + [query];
}
