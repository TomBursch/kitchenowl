import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/models/household.dart';
import 'package:kitchenowl/models/recipe.dart';
import 'package:kitchenowl/models/tag.dart';
import 'package:kitchenowl/services/storage/storage.dart';
import 'package:kitchenowl/services/transaction_handler.dart';
import 'package:kitchenowl/services/transactions/recipe.dart';
import 'package:kitchenowl/services/transactions/tag.dart';

class RecipeListCubit extends Cubit<RecipeListState> {
  final Household household;
  List<Recipe> recipeList = [];
  Future<void>? _refreshThread;
  String? _refreshCurrentQuery;

  RecipeListCubit(this.household) : super(const LoadingRecipeListState()) {
    PreferenceStorage.getInstance().readBool(key: 'recipeListView').then((i) {
      if (i != null && state.listView != i) {
        toggleView(false);
      }
    });
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
          ListRecipeListState(
            recipes: _state.allRecipes,
            tags: _state.tags,
            listView: state.listView,
          ),
        );
      } else {
        emit(_state.copyWith(
          listView: state.listView,
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

  Future<void> refresh([String? query]) {
    final state = this.state;
    if (state is SearchRecipeListState) {
      query = query ?? state.query;
    }
    if (_refreshThread != null && query != _refreshCurrentQuery) {
      _refreshCurrentQuery = query;
      _refreshThread = _refresh(query);
    }
    if (_refreshThread == null) {
      _refreshCurrentQuery = query;
      _refreshThread = _refresh(query);
    }

    return _refreshThread!;
  }

  Future<void> _refresh([String? query, bool runOffline = false]) async {
    late ListRecipeListState _state;
    if (state is ListRecipeListState &&
        state is! SearchRecipeListState &&
        state is! FilteredListRecipeListState &&
        (state as ListRecipeListState).recipes.isEmpty) {
      emit(LoadingRecipeListState(listView: state.listView));
    }

    if (query != null && query.isNotEmpty) {
      final tags = TransactionHandler.getInstance()
          .runTransaction(TransactionTagGetAll(household: household));
      final recipes = TransactionHandler.getInstance()
          .runTransaction(TransactionRecipeSearchRecipes(
        household: household,
        query: query,
      ));

      _state = SearchRecipeListState(
        query: query,
        recipes: await recipes,
        tags: await tags,
        listView: state.listView,
      );
    } else {
      if (!runOffline && state is SearchRecipeListState) _refresh(query, true);
      final tags = TransactionHandler.getInstance().runTransaction(
        TransactionTagGetAll(household: household),
        forceOffline: runOffline,
      );
      recipeList = await TransactionHandler.getInstance().runTransaction(
        TransactionRecipeGetRecipes(household: household),
        forceOffline: runOffline,
      );
      Set<Tag> filter = const {};
      if (state is FilteredListRecipeListState && (query == null)) {
        filter = (state as FilteredListRecipeListState).selectedTags;
      }
      _state = filter.isNotEmpty
          ? FilteredListRecipeListState(
              recipes: _getFilteredRecipesCopy(recipeList, filter),
              tags: await tags,
              selectedTags: filter,
              allRecipes: recipeList,
              listView: state.listView,
            )
          : ListRecipeListState(
              recipes: recipeList,
              tags: await tags,
              listView: state.listView,
            );
    }
    if (query == _refreshCurrentQuery) {
      emit(_state);
      _refreshThread = null;
    }
  }

  List<Recipe> _getFilteredRecipesCopy(
    List<Recipe> allRecipes,
    Set<Tag> filter,
  ) =>
      List<Recipe>.from(
        allRecipes.where((e) => e.tags.containsAll(filter)),
      );

  void toggleView([bool savePreference = true]) {
    if (savePreference) {
      PreferenceStorage.getInstance()
          .writeBool(key: 'recipeListView', value: !state.listView);
    }
    emit(state.copyWith(listView: !state.listView));
  }
}

abstract class RecipeListState extends Equatable {
  final bool listView;
  const RecipeListState({this.listView = true});

  @override
  List<Object?> get props => [listView];

  RecipeListState copyWith({bool? listView});
}

class LoadingRecipeListState extends RecipeListState {
  const LoadingRecipeListState({super.listView});

  @override
  RecipeListState copyWith({bool? listView}) {
    return LoadingRecipeListState(listView: listView ?? this.listView);
  }
}

class ListRecipeListState extends RecipeListState {
  final List<Recipe> recipes;
  final Set<Tag> tags;

  const ListRecipeListState({
    this.recipes = const [],
    this.tags = const {},
    super.listView,
  });

  @override
  List<Object?> get props => super.props + <Object?>[tags] + recipes;

  @override
  RecipeListState copyWith({bool? listView}) {
    return ListRecipeListState(
      listView: listView ?? this.listView,
      recipes: recipes,
      tags: tags,
    );
  }
}

class FilteredListRecipeListState extends ListRecipeListState {
  final Set<Tag> selectedTags;
  final List<Recipe> allRecipes;

  const FilteredListRecipeListState({
    this.selectedTags = const {},
    this.allRecipes = const [],
    super.recipes = const [],
    super.tags = const {},
    super.listView,
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
        listView: state.listView,
      );

  @override
  FilteredListRecipeListState copyWith({
    bool? listView,
    List<Recipe>? recipes,
    Set<Tag>? tags,
    Set<Tag>? selectedTags,
  }) =>
      FilteredListRecipeListState(
        listView: listView ?? this.listView,
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
    super.listView,
  });

  @override
  List<Object?> get props => super.props + [query];

  @override
  RecipeListState copyWith({bool? listView}) {
    return SearchRecipeListState(
      listView: listView ?? this.listView,
      query: query,
      recipes: recipes,
      tags: tags,
    );
  }
}
