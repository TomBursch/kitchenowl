import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/models/item.dart';
import 'package:kitchenowl/models/recipe.dart';
import 'package:kitchenowl/services/api/api_service.dart';

class ItemEditCubit extends Cubit<ItemEditState> {
  final Item item;

  ItemEditCubit({this.item = const ShoppinglistItem()})
      : super(ItemEditState(
          description: (item is ItemWithDescription) ? item.description : '',
          name: item.name,
        )) {
    refresh();
  }

  Future<void> refresh() async {
    if (item.id != null) {
      final item = await ApiService.getInstance().getItem(this.item);
      if (item != null) {
        final recipes =
            (await ApiService.getInstance().getItemRecipes(item)) ?? [];
        emit(state.copyWith(recipes: recipes));
      }
    }
  }

  bool hasChanged() {
    return item is ItemWithDescription &&
        (item as ItemWithDescription).description != state.description;
  }

  Future<void> saveItem() async {
    if (item is ShoppinglistItem) {
      await ApiService.getInstance()
          .updateShoppingListItemDescription(item, state.description ?? '');
    }
  }

  Future<bool> deleteItem() async {
    if (item.id != null) {
      return ApiService.getInstance().deleteItem(item);
    }
    return false;
  }

  void setName(String name) {
    emit(state.copyWith(name: name));
  }

  void setDescription(String desc) {
    emit(state.copyWith(description: desc));
  }
}

class ItemEditState extends Equatable {
  final String name;
  final String description;
  final List<Recipe> recipes;

  const ItemEditState(
      {this.name = "", this.description = "", this.recipes = const []});

  ItemEditState copyWith({
    String name,
    String description,
    List<Recipe> recipes,
  }) =>
      ItemEditState(
        name: name ?? this.name,
        description: description ?? this.description,
        recipes: recipes ?? this.recipes,
      );

  @override
  List<Object> get props => [name, description, recipes];
}
