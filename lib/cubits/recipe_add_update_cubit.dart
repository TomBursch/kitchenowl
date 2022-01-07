import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/models/item.dart';
import 'package:kitchenowl/models/recipe.dart';
import 'package:kitchenowl/models/tag.dart';
import 'package:kitchenowl/services/api/api_service.dart';
import 'package:kitchenowl/services/transaction_handler.dart';
import 'package:kitchenowl/services/transactions/tag.dart';

class AddUpdateRecipeCubit extends Cubit<AddUpdateRecipeState> {
  final Recipe recipe;
  AddUpdateRecipeCubit([this.recipe = const Recipe()])
      : super(AddUpdateRecipeState(
          description: recipe.description,
          name: recipe.name,
          time: recipe.time,
          items: recipe.items,
          selectedTags: recipe.tags,
          tags: recipe.tags,
        )) {
    getTags();
  }

  Future<void> getTags() async {
    final tags = await TransactionHandler.getInstance()
        .runTransaction(TransactionTagGetAll());
    emit(state.copyWith(tags: tags));
  }

  Future<void> saveRecipe() async {
    if (state.isValid()) {
      if (recipe.id == null) {
        await ApiService.getInstance().addRecipe(Recipe(
          name: state.name,
          description: state.description ?? "",
          time: state.time,
          items: state.items,
          tags: state.selectedTags,
        ));
      } else {
        await ApiService.getInstance().updateRecipe(recipe.copyWith(
          name: state.name,
          description: state.description,
          time: state.time,
          items: state.items,
          tags: state.selectedTags,
        ));
      }
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

  void setTime(int time) {
    emit(state.copyWith(time: time));
  }

  void selectTag(Tag tag, bool selected) {
    final l = List<Tag>.from(state.selectedTags);
    if (selected) {
      l.add(tag);
    } else {
      l.removeWhere((e) => e.name == tag.name);
    }
    emit(state.copyWith(selectedTags: l));
  }

  void addTag(String tag) {
    final l = List<Tag>.from(state.tags);
    final selected = List<Tag>.from(state.selectedTags);
    final t = Tag(name: tag);
    l.add(t);
    selected.add(t);
    emit(state.copyWith(tags: l, selectedTags: selected));
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
  final int time;
  final List<RecipeItem> items;
  final List<Tag> tags;
  final List<Tag> selectedTags;

  const AddUpdateRecipeState({
    this.name = "",
    this.description = "",
    this.time = 0,
    this.items = const [],
    this.tags = const [],
    this.selectedTags = const [],
  });

  AddUpdateRecipeState copyWith({
    String name,
    String description,
    int time,
    List<RecipeItem> items,
    List<Tag> tags,
    List<Tag> selectedTags,
  }) =>
      AddUpdateRecipeState(
        name: name ?? this.name,
        description: description ?? this.description,
        time: time ?? this.time,
        items: items ?? this.items,
        tags: tags ?? this.tags,
        selectedTags: selectedTags ?? this.selectedTags,
      );

  bool isValid() => name.isNotEmpty;

  @override
  List<Object> get props =>
      [name, description, time, items, tags, selectedTags];
}
