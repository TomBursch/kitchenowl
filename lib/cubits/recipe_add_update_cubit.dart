import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/helpers/named_bytearray.dart';
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
          cookTime: recipe.cookTime,
          prepTime: recipe.prepTime,
          yields: recipe.yields,
          source: recipe.source,
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
    final AddUpdateRecipeState _state = state;
    if (state.isValid()) {
      String? image;
      if (_state.image != null) {
        image = _state.image!.isEmpty
            ? ''
            : await ApiService.getInstance().uploadBytes(_state.image!);
      }
      if (recipe.id == null) {
        await ApiService.getInstance().addRecipe(Recipe(
          name: _state.name,
          description: _state.description,
          time: _state.time,
          cookTime: _state.cookTime,
          prepTime: _state.prepTime,
          yields: _state.yields,
          source: _state.source,
          image: image ?? recipe.image,
          items: _state.items,
          tags: _state.selectedTags,
        ));
      } else {
        await ApiService.getInstance().updateRecipe(recipe.copyWith(
          name: _state.name,
          description: _state.description,
          time: _state.time,
          cookTime: _state.cookTime,
          prepTime: _state.prepTime,
          yields: _state.yields,
          source: _state.source,
          image: image,
          items: _state.items,
          tags: _state.selectedTags,
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

  void setImage(NamedByteArray image) {
    emit(state.copyWith(image: image));
  }

  void setDescription(String desc) {
    emit(state.copyWith(description: desc));
  }

  Future<void> setDescriptionFromSource() async {
    final source = state.source;
    final scrape = await ApiService.getInstance().scrapeRecipe(source);
    if (scrape != null && scrape.recipe.description.isNotEmpty) {
      setDescription(scrape.recipe.description);
    }
  }

  void setTime(int time) {
    emit(state.copyWith(time: time));
  }

  void setCookTime(int time) {
    emit(state.copyWith(cookTime: time));
  }

  void setPrepTime(int time) {
    emit(state.copyWith(prepTime: time));
  }

  void setYields(int yields) {
    emit(state.copyWith(yields: yields));
  }

  void setSource(String source) {
    emit(state.copyWith(source: source));
  }

  void selectTag(Tag tag, bool selected) {
    final l = Set<Tag>.from(state.selectedTags);
    if (selected) {
      l.add(tag);
    } else {
      l.removeWhere((e) => e.name == tag.name);
    }
    emit(state.copyWith(selectedTags: l));
  }

  void addTag(String tag) {
    final l = Set<Tag>.from(state.tags);
    final selected = Set<Tag>.from(state.selectedTags);
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
                (item is ItemWithDescription) ? item.description : null,
          ));
    }
    l.addAll(state.items.where((e) => e.optional != optional));
    emit(state.copyWith(items: l));
  }

  void updateItem(RecipeItem item) {
    final int i = state.items.indexWhere((e) => e.name == item.name);
    if (i < 0) return;
    final l = List.of(state.items);
    l[i] = item;
    emit(state.copyWith(items: l));
  }
}

class AddUpdateRecipeState extends Equatable {
  final String name;
  final String description;
  final int time;
  final int cookTime;
  final int prepTime;
  final int yields;
  final String source;
  final NamedByteArray? image;
  final List<RecipeItem> items;
  final Set<Tag> tags;
  final Set<Tag> selectedTags;

  const AddUpdateRecipeState({
    this.name = "",
    this.description = "",
    this.time = 0,
    this.cookTime = 0,
    this.prepTime = 0,
    this.yields = 0,
    this.source = '',
    this.image,
    this.items = const [],
    this.tags = const {},
    this.selectedTags = const {},
  });

  AddUpdateRecipeState copyWith({
    String? name,
    String? description,
    int? time,
    int? cookTime,
    int? prepTime,
    int? yields,
    String? source,
    NamedByteArray? image,
    List<RecipeItem>? items,
    Set<Tag>? tags,
    Set<Tag>? selectedTags,
  }) =>
      AddUpdateRecipeState(
        name: name ?? this.name,
        description: description ?? this.description,
        time: time ?? this.time,
        cookTime: cookTime ?? this.cookTime,
        prepTime: prepTime ?? this.prepTime,
        yields: yields ?? this.yields,
        source: source ?? this.source,
        image: image ?? this.image,
        items: items ?? this.items,
        tags: tags ?? this.tags,
        selectedTags: selectedTags ?? this.selectedTags,
      );

  bool isValid() => name.isNotEmpty;

  @override
  List<Object?> get props => [
        name,
        description,
        time,
        cookTime,
        prepTime,
        yields,
        source,
        image,
        items,
        tags,
        selectedTags,
      ];
}
