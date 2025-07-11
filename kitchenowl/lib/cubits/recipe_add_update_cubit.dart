import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:kitchenowl/helpers/named_bytearray.dart';
import 'package:kitchenowl/models/household.dart';
import 'package:kitchenowl/models/item.dart';
import 'package:kitchenowl/models/recipe.dart';
import 'package:kitchenowl/models/tag.dart';
import 'package:kitchenowl/services/api/api_service.dart';
import 'package:kitchenowl/services/transaction_handler.dart';
import 'package:kitchenowl/services/transactions/tag.dart';
import 'package:replay_bloc/replay_bloc.dart';

class AddUpdateRecipeCubit extends ReplayCubit<AddUpdateRecipeState> {
  final Household household;
  final Recipe recipe;

  AddUpdateRecipeCubit(
    this.household, [
    this.recipe = const Recipe(),
    bool? hasChanges,
  ]) : super(AddUpdateRecipeState(
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
          visibility: recipe.visibility,
          hasChanges: hasChanges ?? false,
        )) {
    getTags();
  }

  Future<void> getTags() async {
    final tags = await TransactionHandler.getInstance()
        .runTransaction(TransactionTagGetAll(household: household));
    emit(state.copyWith(tags: tags));
    this.clearHistory();
  }

  Future<Recipe?> saveRecipe() async {
    final AddUpdateRecipeState _state = state;
    if (state.isValid()) {
      String? image;
      if (_state.image != null) {
        image = _state.image!.isEmpty
            ? ''
            : await ApiService.getInstance().uploadBytes(_state.image!);
      }
      if (recipe.id == null) {
        return ApiService.getInstance().addRecipe(
          household,
          Recipe(
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
            visibility: _state.visibility,
            curated: _state.curated,
          ),
        );
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
          visibility: _state.visibility,
          curated: _state.curated,
        ));
      }
      emit(_state.copyWith(hasChanges: false));
      this.clearHistory();
    }

    return null;
  }

  Future<bool> removeRecipe() async {
    if (recipe.id != null) return ApiService.getInstance().deleteRecipe(recipe);

    return false;
  }

  void setName(String name) {
    emit(state.copyWith(name: name, hasChanges: true));
  }

  void setImage(NamedByteArray image) {
    emit(state.copyWith(image: image, hasChanges: true));
  }

  void setDescription(String desc) {
    emit(state.copyWith(description: desc, hasChanges: true));
  }

  Future<void> setDescriptionFromSource() async {
    final source = state.source;
    final scrape =
        await ApiService.getInstance().scrapeRecipe(household, source);
    if (scrape.$1 != null && scrape.$1!.recipe.description.isNotEmpty) {
      setDescription(scrape.$1!.recipe.description);
    }
  }

  void setTime(int time) {
    emit(state.copyWith(time: time, hasChanges: true));
  }

  void setCookTime(int time) {
    emit(state.copyWith(cookTime: time, hasChanges: true));
  }

  void setPrepTime(int time) {
    emit(state.copyWith(prepTime: time, hasChanges: true));
  }

  void setYields(int yields) {
    emit(state.copyWith(yields: yields, hasChanges: true));
  }

  void setSource(String source) {
    emit(state.copyWith(source: source, hasChanges: true));
  }

  void setVisibility(RecipeVisibility visibility) {
    emit(state.copyWith(visibility: visibility, hasChanges: true));
  }

  void setCurated(bool curated) {
    emit(state.copyWith(curated: curated, hasChanges: true));
  }

  void selectTag(Tag tag, bool selected) {
    final l = Set<Tag>.from(state.selectedTags);
    if (selected) {
      l.add(tag);
    } else {
      l.removeWhere((e) => e.name == tag.name);
    }
    emit(state.copyWith(selectedTags: l, hasChanges: true));
  }

  void addTag(String tag) {
    final l = Set<Tag>.from(state.tags);
    final selected = Set<Tag>.from(state.selectedTags);
    final t = Tag(name: tag);
    l.add(t);
    selected.add(t);
    emit(state.copyWith(tags: l, selectedTags: selected, hasChanges: true));
  }

  void addItem(RecipeItem item) {
    emit(state.copyWith(
        items: List.from(state.items)..add(item), hasChanges: true));
  }

  bool containsItem(RecipeItem item) {
    return state.items.contains(item);
  }

  void removeItem(RecipeItem item) {
    final l = List<RecipeItem>.from(state.items);
    l.remove(item);
    emit(state.copyWith(items: l, hasChanges: true));
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
    emit(state.copyWith(items: l, hasChanges: true));
  }

  void updateItem(RecipeItem item) {
    final int i = state.items.indexWhere((e) => e.name == item.name);
    if (i < 0) return;
    final l = List.of(state.items);
    l[i] = item;
    emit(state.copyWith(items: l, hasChanges: true));
  }

  void detectIngridientsInDescription() {
    if (!state.canMatchIngredients()) return;

    final String description = state.description.replaceAllMapped(
        RegExp(
          "(?<!#.*)\\b(?<!@)(" +
              state.items
                  // sort long to short names
                  .sorted((a, b) => b.name.length.compareTo(a.name.length))
                  .where((e) => e.name.isNotEmpty)
                  .map((e) => e.name)
                  .fold("", (a, b) => a.isEmpty ? "$b" : "$a|$b") +
              ")\\b",
          caseSensitive: false,
        ), (match) {
      final name = match[1]!.toLowerCase();
      if (name.isEmpty ||
          !recipe.items.map((e) => e.name.toLowerCase()).contains(name)) {
        return match[0]!;
      }
      return "@" + name.replaceAll(" ", "_");
    });
    emit(state.copyWith(
      description: description,
      hasChanges: true,
    ));
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
  final bool curated;
  final NamedByteArray? image;
  final RecipeVisibility visibility;
  final List<RecipeItem> items;
  final Set<Tag> tags;
  final Set<Tag> selectedTags;
  final bool hasChanges;

  const AddUpdateRecipeState({
    this.name = "",
    this.description = "",
    this.time = 0,
    this.cookTime = 0,
    this.prepTime = 0,
    this.yields = 0,
    this.source = '',
    this.curated = false,
    this.image,
    this.visibility = RecipeVisibility.private,
    this.items = const [],
    this.tags = const {},
    this.selectedTags = const {},
    this.hasChanges = true,
  });

  AddUpdateRecipeState copyWith({
    String? name,
    String? description,
    int? time,
    int? cookTime,
    int? prepTime,
    int? yields,
    String? source,
    bool? curated,
    NamedByteArray? image,
    RecipeVisibility? visibility,
    List<RecipeItem>? items,
    Set<Tag>? tags,
    Set<Tag>? selectedTags,
    bool? hasChanges,
  }) =>
      AddUpdateRecipeState(
        name: name ?? this.name,
        description: description ?? this.description,
        time: time ?? this.time,
        cookTime: cookTime ?? this.cookTime,
        prepTime: prepTime ?? this.prepTime,
        yields: yields ?? this.yields,
        source: source ?? this.source,
        curated: curated ?? this.curated,
        image: image ?? this.image,
        items: items ?? this.items,
        tags: tags ?? this.tags,
        visibility: visibility ?? this.visibility,
        selectedTags: selectedTags ?? this.selectedTags,
        hasChanges: hasChanges ?? this.hasChanges,
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
        curated,
        image,
        items,
        tags,
        visibility,
        selectedTags,
        hasChanges,
      ];

  bool canMatchIngredients() {
    if (items.isEmpty) return false;

    return description.contains(RegExp(
      "(?<!#.*)\\b(?<!@)(" +
          items
              // sort long to short names
              .sorted((a, b) => b.name.length.compareTo(a.name.length))
              .where((e) => e.name.isNotEmpty)
              .map((e) => e.name)
              .fold("", (a, b) => a.isEmpty ? "$b" : "$a|$b") +
          ")\\b",
      caseSensitive: false,
    ));
  }
}
