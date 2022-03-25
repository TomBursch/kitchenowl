import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/models/item.dart';
import 'package:kitchenowl/models/recipe.dart';
import 'package:kitchenowl/services/api/api_service.dart';
import 'package:kitchenowl/services/transaction_handler.dart';
import 'package:kitchenowl/services/transactions/item.dart';
import 'package:kitchenowl/services/transactions/shoppinglist.dart';

class ItemEditCubit<T extends Item> extends Cubit<ItemEditState> {
  final T _item;

  T get item {
    if (_item is ItemWithDescription) {
      return (((_item as ItemWithDescription)
          .copyWith(description: state.description)) as T);
    }

    return _item;
  }

  ItemEditCubit({required T item})
      : _item = item,
        super(ItemEditState(
          description: (item is ItemWithDescription) ? item.description : '',
          name: item.name,
        )) {
    refresh();
  }

  Future<void> refresh() async {
    if (_item.id != null) {
      final recipes = (await TransactionHandler.getInstance()
          .runTransaction(TransactionItemGetRecipes(item: _item)))
        ..sort(((a, b) {
          if (a.isPlanned == b.isPlanned) {
            return 0;
          } else if (b.isPlanned) {
            return 1;
          } else {
            return -1;
          }
        }));
      emit(state.copyWith(recipes: recipes));
    }
  }

  bool hasChanged() {
    return _item is ItemWithDescription &&
        (_item as ItemWithDescription).description != state.description;
  }

  Future<void> saveItem() async {
    if (_item is ShoppinglistItem) {
      await TransactionHandler.getInstance()
          .runTransaction(TransactionShoppingListUpdateItem(
        item: _item,
        description: state.description,
      ));
    }
  }

  Future<bool> deleteItem() async {
    if (_item.id != null) {
      return ApiService.getInstance().deleteItem(_item);
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

  const ItemEditState({
    this.name = "",
    this.description = "",
    this.recipes = const [],
  });

  ItemEditState copyWith({
    String? name,
    String? description,
    List<Recipe>? recipes,
  }) =>
      ItemEditState(
        name: name ?? this.name,
        description: description ?? this.description,
        recipes: recipes ?? this.recipes,
      );

  @override
  List<Object?> get props => [name, description, recipes];
}
