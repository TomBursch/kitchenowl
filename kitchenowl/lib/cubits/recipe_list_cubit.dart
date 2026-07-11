import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/models/household.dart';
import 'package:kitchenowl/models/recipe.dart';
import 'package:kitchenowl/models/tag.dart';
import 'package:kitchenowl/services/api/api_service.dart';
import 'package:kitchenowl/services/recipe_sync_service.dart';
import 'package:kitchenowl/services/storage/storage.dart';
import 'package:kitchenowl/services/storage/mem_storage.dart';
import 'package:kitchenowl/services/transaction_handler.dart';
import 'package:kitchenowl/services/transactions/recipe.dart';
import 'package:kitchenowl/services/transactions/tag.dart';

class RecipeListCubit extends Cubit<RecipeListState> {
  final Household household;
  List<Recipe> recipeList = [];
  Future<void>? _refreshThread;
  String? _refreshCurrentQuery;

  static const int _perPage = 50;

  RecipeListCubit(this.household) : super(const LoadingRecipeListState()) {
    PreferenceStorage.getInstance().readBool(key: 'recipeListView').then((i) {
      if (i != null && state.listView != i) {
        toggleView(false);
      }
    });
    _initialLoad();
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
    if (_refreshThread == null || query != _refreshCurrentQuery) {
      _refreshCurrentQuery = query;
      _refreshThread = _refresh(query);
    }

    return _refreshThread!;
  }

  Future<void> loadMore() async {
    final currentState = state;
    if (currentState is! ListRecipeListState) return;
    if (!currentState.hasMore) return;
    if (currentState.isLoadingMore) return;
    // search/filter states don't paginate
    if (currentState is SearchRecipeListState) return;
    if (currentState is FilteredListRecipeListState) return;

    final nextPage = currentState.currentPage + 1;
    emit(currentState.copyWith(isLoadingMore: true));

    try {
      final result = await ApiService.getInstance().getRecipesPaginated(
        household,
        page: nextPage,
        perPage: _perPage,
      );
      if (result == null) {
        if (!isClosed && state is ListRecipeListState) {
          emit((state as ListRecipeListState).copyWith(isLoadingMore: false));
        }
        return;
      }

      final merged = List<Recipe>.from(recipeList)..addAll(result.items);
      recipeList = merged;

      final tags = await TransactionHandler.getInstance().runTransaction(
        TransactionTagGetAll(household: household),
        forceOffline: true,
      );

      if (!isClosed) {
        emit(ListRecipeListState(
          recipes: merged,
          tags: tags,
          listView: state.listView,
          hasMore: result.hasMore,
          currentPage: nextPage,
        ));
      }
    } catch (_) {
      // restore previous state without loading indicator
      if (!isClosed && state is ListRecipeListState) {
        emit((state as ListRecipeListState).copyWith(isLoadingMore: false));
      }
    }
  }

  Future<void> _initialLoad() async {
    // On web skip local cache — rely on network only
    if (kIsWeb) return;

    final tags = TransactionHandler.getInstance().runTransaction(
      TransactionTagGetAll(household: household),
      forceOffline: true,
    );
    recipeList = await TransactionHandler.getInstance().runTransaction(
      TransactionRecipeGetRecipes(household: household),
      forceOffline: true,
    );

    if (state is LoadingRecipeListState && recipeList.isNotEmpty) {
      emit(ListRecipeListState(
        recipes: recipeList,
        tags: await tags,
        listView: state.listView,
      ));
    }
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

      try {
        final tags = TransactionHandler.getInstance().runTransaction(
          TransactionTagGetAll(household: household),
          forceOffline: runOffline,
        );

        if (runOffline) {
          recipeList = await TransactionHandler.getInstance().runTransaction(
            TransactionRecipeGetRecipes(household: household),
            forceOffline: true,
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
        } else {
          // Load first page from network
          final result = await ApiService.getInstance().getRecipesPaginated(
            household,
            page: 0,
            perPage: _perPage,
          );
          if (result == null) {
            if (query == _refreshCurrentQuery && !isClosed) {
              // Only show error page when there's nothing cached to display
              if (recipeList.isEmpty) {
                emit(ErrorRecipeListState(listView: state.listView));
              }
              _refreshThread = null;
            }
            return;
          }
          recipeList = result.items;
          // Do NOT write slim list to the offline cache — the background sync
          // service writes full-detail recipes. Only mobile uses offline cache.
          if (!kIsWeb) {
            RecipeSyncService.getInstance().sync(household);
          }

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
                  hasMore: result.hasMore,
                  currentPage: 0,
                )
              : ListRecipeListState(
                  recipes: recipeList,
                  tags: await tags,
                  listView: state.listView,
                  hasMore: result.hasMore,
                  currentPage: 0,
                );
        }
      } catch (_) {
        if (query == _refreshCurrentQuery && !isClosed) {
          // Only replace current list with error state when there's nothing to show
          if (recipeList.isEmpty) {
            emit(ErrorRecipeListState(listView: state.listView));
          }
          _refreshThread = null;
        }
        return;
      }
    }
    if (query == _refreshCurrentQuery && !isClosed) {
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

class ErrorRecipeListState extends RecipeListState {
  const ErrorRecipeListState({super.listView});

  @override
  RecipeListState copyWith({bool? listView}) {
    return ErrorRecipeListState(listView: listView ?? this.listView);
  }
}

class ListRecipeListState extends RecipeListState {
  final List<Recipe> recipes;
  final Set<Tag> tags;
  final bool hasMore;
  final bool isLoadingMore;
  final int currentPage;

  const ListRecipeListState({
    this.recipes = const [],
    this.tags = const {},
    super.listView,
    this.hasMore = false,
    this.isLoadingMore = false,
    this.currentPage = 0,
  });

  @override
  List<Object?> get props =>
      super.props + <Object?>[tags, hasMore, isLoadingMore, currentPage] + recipes;

  @override
  ListRecipeListState copyWith({
    bool? listView,
    List<Recipe>? recipes,
    Set<Tag>? tags,
    bool? hasMore,
    bool? isLoadingMore,
    int? currentPage,
  }) {
    return ListRecipeListState(
      listView: listView ?? this.listView,
      recipes: recipes ?? this.recipes,
      tags: tags ?? this.tags,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      currentPage: currentPage ?? this.currentPage,
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
    super.hasMore = false,
    super.isLoadingMore = false,
    super.currentPage = 0,
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
        hasMore: state.hasMore,
        currentPage: state.currentPage,
      );

  @override
  FilteredListRecipeListState copyWith({
    bool? listView,
    List<Recipe>? recipes,
    Set<Tag>? tags,
    Set<Tag>? selectedTags,
    bool? hasMore,
    bool? isLoadingMore,
    int? currentPage,
  }) =>
      FilteredListRecipeListState(
        listView: listView ?? this.listView,
        recipes: recipes ?? this.recipes,
        tags: tags ?? this.tags,
        selectedTags: selectedTags ?? this.selectedTags,
        allRecipes: allRecipes,
        hasMore: hasMore ?? this.hasMore,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        currentPage: currentPage ?? this.currentPage,
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
  SearchRecipeListState copyWith({
    bool? listView,
    List<Recipe>? recipes,
    Set<Tag>? tags,
    bool? hasMore,
    bool? isLoadingMore,
    int? currentPage,
    String? query,
  }) {
    return SearchRecipeListState(
      listView: listView ?? this.listView,
      query: query ?? this.query,
      recipes: recipes ?? this.recipes,
      tags: tags ?? this.tags,
    );
  }
}
