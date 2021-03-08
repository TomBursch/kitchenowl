import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/models/item.dart';
import 'package:kitchenowl/models/recipe.dart';
import 'package:kitchenowl/services/api/api_service.dart';

class RecipeCubit extends Cubit<RecipeState> {
  RecipeCubit(Recipe recipe)
      : super(RecipeState(
            recipe, recipe.items.where((e) => !e.optional).toList()));

  void itemSelected(RecipeItem item) {
    final List<RecipeItem> selectedItems = List.from(state.selectedItems);
    if (selectedItems.contains(item)) {
      selectedItems.remove(item);
    } else {
      selectedItems.add(item);
    }
    emit(state.copyWith(selectedItems: selectedItems));
  }

  void refresh() async {
    final recipe = await ApiService.getInstance().getRecipe(state.recipe);
    if (recipe != null)
      emit(
          RecipeState(recipe, recipe.items.where((e) => !e.optional).toList()));
  }

  Future<void> addItemsToList() async {
    await ApiService.getInstance().addRecipeItems(state.selectedItems);
  }
}

class RecipeState extends Equatable {
  final List<RecipeItem> selectedItems;
  final Recipe recipe;

  RecipeState(this.recipe, this.selectedItems);

  RecipeState copyWith({Recipe recipe, List<RecipeItem> selectedItems}) =>
      RecipeState(recipe ?? this.recipe, selectedItems ?? this.selectedItems);

  @override
  List<Object> get props => [recipe, selectedItems];
}
