import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/models/item.dart';
import 'package:kitchenowl/models/recipe.dart';
import 'package:kitchenowl/services/api/api_service.dart';
import 'package:kitchenowl/services/transaction_handler.dart';
import 'package:kitchenowl/services/transactions/item.dart';
import 'package:kitchenowl/services/transactions/shoppinglist.dart';

class ItemEditCubit extends Cubit<ItemEditState> {
  final Item item;

  ItemEditCubit({required this.item})
      : super(ItemEditState(
          description: (item is ItemWithDescription) ? item.description : '',
          name: item.name,
        )) {
    refresh();
  }

  Future<void> refresh() async {
    if (item.id != null) {
      final recipes = (await TransactionHandler.getInstance()
          .runTransaction(TransactionItemGetRecipes(item: item)));
      emit(state.copyWith(recipes: recipes));
    }
  }

  bool hasChanged() {
    return item is ItemWithDescription &&
        (item as ItemWithDescription).description != state.description;
  }

  Future<void> saveItem() async {
    if (item is ShoppinglistItem) {
      await TransactionHandler.getInstance()
          .runTransaction(TransactionShoppingListUpdateItem(
        item: item,
        description: state.description,
      ));
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
