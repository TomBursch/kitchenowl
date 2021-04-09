import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/models/item.dart';
import 'package:kitchenowl/models/recipe.dart';
import 'package:kitchenowl/services/api/api_service.dart';

class AddUpdateRecipeCubit extends Cubit<AddUpdateRecipeState> {
  final Recipe recipe;
  AddUpdateRecipeCubit([this.recipe = const Recipe()])
      : super(AddUpdateRecipeState(
          description: recipe.description,
          name: recipe.name,
          items: recipe.items,
        ));

  Future<void> saveRecipe() async {
    if (recipe.id == null) {
      if (state.name.isNotEmpty) {
        await ApiService.getInstance().addRecipe(Recipe(
          name: state.name,
          description: state.description ?? "",
          items: state.items,
        ));
      }
    } else {
      await ApiService.getInstance().updateRecipe(recipe.copyWith(
        name: state.name,
        description: state.description,
        items: state.items,
      ));
    }
  }

  Future<bool> removeRecipe() async {
    if (recipe.id != null) return ApiService.getInstance().deleteRecipe(recipe);
    return false;
  }

  void setName(String name) {
    emit(state.copyWith(name: name));
  }

  void setDescription(String desc) {
    emit(state.copyWith(description: desc));
  }

  void addItem(RecipeItem item) {
    emit(state.copyWith(items: List.from(state.items)..add(item)));
  }

  bool containsItem(RecipeItem item) {
    return state.items.contains(item);
  }

  void removeItem(RecipeItem item) {
    final l = List<RecipeItem>.from(state.items);
    l.remove(item);
    emit(state.copyWith(items: l));
  }

  void updateFromItemList(List<Item> items, bool optional) {
    final l = <RecipeItem>[];
    for (final item in items) {
      l.add(state.items
          .where((e) => e.optional == optional)
          .firstWhere(
            (e) => e.toItem() == item,
            orElse: () => RecipeItem.fromItem(item: item, optional: optional),
          )
          .copyWith(
              description:
                  (item is ItemWithDescription) ? item.description : null));
    }
    l.addAll(state.items.where((e) => e.optional != optional));
    emit(state.copyWith(items: l));
  }
}

class AddUpdateRecipeState extends Equatable {
  final String name;
  final String description;
  final List<RecipeItem> items;

  const AddUpdateRecipeState(
      {this.name = "", this.description = "", this.items = const []});

  AddUpdateRecipeState copyWith({
    String name,
    String description,
    List<RecipeItem> items,
  }) =>
      AddUpdateRecipeState(
        name: name ?? this.name,
        description: description ?? this.description,
        items: items ?? this.items,
      );

  @override
  List<Object> get props => [name, description, items];
}
