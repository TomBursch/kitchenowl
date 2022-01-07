import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/models/recipe.dart';
import 'package:kitchenowl/models/tag.dart';
import 'package:kitchenowl/services/transaction_handler.dart';
import 'package:kitchenowl/services/transactions/recipe.dart';
import 'package:kitchenowl/services/transactions/tag.dart';

class RecipeListCubit extends Cubit<ListRecipeCubitState> {
  List<Recipe> shoppinglist = [];

  RecipeListCubit() : super(const ListRecipeCubitState()) {
    refresh();
  }

  String get query => (state != null && state is SearchRecipeCubitState)
      ? (state as SearchRecipeCubitState).query
      : "";

  Future<void> search(String query) {
    return refresh(query);
  }

  Future<void> tagSelected(Tag tag, bool selected) {
    if (state is FilteredListRecipeCubitState) {
      final _state = state as FilteredListRecipeCubitState;
      final l = List<Tag>.from(_state.selectedTags);
      if (selected) {
        l.add(tag);
      } else {
        l.removeWhere((e) => e.id == tag.id);
      }
      emit(_state.copyWith(selectedTags: l));
    } else if (selected) {
      emit(FilteredListRecipeCubitState.fromState(state, [tag]));
    }
    return refresh();
  }

  Future<void> refresh([String query]) async {
    List<Tag> filter = const [];
    if (state is SearchRecipeCubitState) {
      query = query ?? (state as SearchRecipeCubitState).query;
    }
    if (state is FilteredListRecipeCubitState) {
      filter = (state as FilteredListRecipeCubitState).selectedTags;
    }
    if (query != null && query.isNotEmpty) {
      final items = (await TransactionHandler.getInstance()
              .runTransaction(TransactionRecipeSearchRecipes(query: query))) ??
          [];
      emit(SearchRecipeCubitState(
          query: query, recipes: items, tags: state.tags));
    } else if (filter.isNotEmpty) {
      shoppinglist = await TransactionHandler.getInstance().runTransaction(
              TransactionRecipeGetRecipesFiltered(filter: filter)) ??
          const [];
      final tags = await TransactionHandler.getInstance()
              .runTransaction(TransactionTagGetAll()) ??
          const [];
      emit(FilteredListRecipeCubitState(
        recipes: shoppinglist,
        tags: tags,
        selectedTags: filter,
      ));
    } else {
      shoppinglist = await TransactionHandler.getInstance()
              .runTransaction(TransactionRecipeGetRecipes()) ??
          const [];
      final tags = await TransactionHandler.getInstance()
              .runTransaction(TransactionTagGetAll()) ??
          const [];
      emit(ListRecipeCubitState(recipes: shoppinglist, tags: tags));
    }
  }
}

class ListRecipeCubitState extends Equatable {
  final List<Recipe> recipes;
  final List<Tag> tags;

  const ListRecipeCubitState({this.recipes = const [], this.tags = const []});

  @override
  List<Object> get props => <Object>[tags] + recipes;
}

class FilteredListRecipeCubitState extends ListRecipeCubitState {
  final List<Tag> selectedTags;

  const FilteredListRecipeCubitState({
    this.selectedTags,
    List<Recipe> recipes = const [],
    List<Tag> tags = const [],
  }) : super(recipes: recipes, tags: tags);

  factory FilteredListRecipeCubitState.fromState(
          ListRecipeCubitState state, List<Tag> selectedTags) =>
      FilteredListRecipeCubitState(
        recipes: state.recipes,
        tags: state.tags,
        selectedTags: selectedTags,
      );

  FilteredListRecipeCubitState copyWith({
    List<Recipe> recipes,
    List<Tag> tags,
    List<Tag> selectedTags,
  }) =>
      FilteredListRecipeCubitState(
        recipes: recipes ?? this.recipes,
        tags: tags ?? this.tags,
        selectedTags: selectedTags ?? this.selectedTags,
      );

  @override
  List<Object> get props => super.props + [selectedTags];
}

class SearchRecipeCubitState extends ListRecipeCubitState {
  final String query;

  const SearchRecipeCubitState(
      {this.query, List<Recipe> recipes = const [], List<Tag> tags = const []})
      : super(recipes: recipes, tags: tags);

  @override
  List<Object> get props => super.props + [query];
}
