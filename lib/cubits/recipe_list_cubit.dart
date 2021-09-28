import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/models/recipe.dart';
import 'package:kitchenowl/services/transaction_handler.dart';
import 'package:kitchenowl/services/transactions/recipe.dart';

class RecipeListCubit extends Cubit<ListRecipeCubitState> {
  List<Recipe> shoppinglist = [];

  RecipeListCubit() : super(const ListRecipeCubitState([])) {
    refresh();
  }

  String get query => (state != null && state is SearchRecipeCubitState)
      ? (state as SearchRecipeCubitState).query
      : "";

  Future<void> search(String query) {
    return refresh(query);
  }

  Future<void> refresh([String query]) async {
    if (state is SearchRecipeCubitState) {
      query = query ?? (state as SearchRecipeCubitState).query;
    }
    if (query != null && query.isNotEmpty) {
      final items = (await TransactionHandler.getInstance()
              .runTransaction(TransactionRecipeSearchRecipes(query: query))) ??
          [];
      emit(SearchRecipeCubitState(query, items));
    } else {
      shoppinglist = await TransactionHandler.getInstance()
              .runTransaction(TransactionRecipeGetRecipes()) ??
          const [];
      emit(ListRecipeCubitState(shoppinglist));
    }
  }
}

class ListRecipeCubitState extends Equatable {
  final List<Recipe> recipes;

  const ListRecipeCubitState(this.recipes);

  @override
  List<Object> get props => recipes;
}

class SearchRecipeCubitState extends ListRecipeCubitState {
  final String query;

  const SearchRecipeCubitState(this.query, List<Recipe> recipes)
      : super(recipes);

  @override
  List<Object> get props => super.props + recipes;
}
