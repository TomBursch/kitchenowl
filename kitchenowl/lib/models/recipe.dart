import 'package:azlistview_plus/azlistview_plus.dart';
import 'package:fraction/fraction.dart';
import 'package:kitchenowl/models/item.dart';
import 'package:kitchenowl/models/model.dart';
import 'package:kitchenowl/models/tag.dart';

import 'household.dart';

class Recipe extends Model implements ISuspensionBean {
  final int? id;
  final String name;
  final String description;
  final bool isPlanned;
  final Set<int> plannedDays;
  final int time;
  final int cookTime;
  final int prepTime;
  final int yields;
  final String source;
  final String? image;
  final String? imageHash;
  final List<RecipeItem> items;
  final Set<Tag> tags;
  final bool public;
  final int? householdId;

  /// The household this recipe belongs to, the contained field is not complete and should only be used for external recipes
  final Household? household;

  const Recipe({
    this.id,
    this.name = '',
    this.description = '',
    this.isPlanned = false,
    this.time = 0,
    this.cookTime = 0,
    this.prepTime = 0,
    this.yields = 0,
    this.source = '',
    this.image,
    this.imageHash,
    this.items = const [],
    this.tags = const {},
    this.plannedDays = const {},
    this.public = false,
    this.householdId,
    this.household,
  });

  factory Recipe.fromJson(Map<String, dynamic> map) {
    List<RecipeItem> items = const [];
    if (map.containsKey('items')) {
      items = List.from(map['items'].map((e) => RecipeItem.fromJson(e)));
    }
    Set<Tag> tags = const {};
    if (map.containsKey('tags')) {
      tags = Set.from(map['tags'].map((e) => Tag.fromJson(e)));
    }
    Set<int> plannedDays = const {};
    if (map.containsKey('planned_days')) {
      plannedDays = Set.from(map['planned_days']);
    }

    return Recipe(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      isPlanned: map['planned'] ?? false,
      time: map['time'] ?? 0,
      cookTime: map['cook_time'] ?? 0,
      prepTime: map['prep_time'] ?? 0,
      yields: map['yields'] ?? 0,
      source: map['source'] ?? '',
      image: map['photo'],
      imageHash: map['photo_hash'],
      public: map['public'],
      householdId: map['household_id'],
      items: items,
      tags: tags,
      plannedDays: plannedDays,
      household: map.containsKey("household")
          ? Household.fromJson(map['household'])
          : null,
    );
  }

  Recipe copyWith({
    String? name,
    String? description,
    bool? isPlanned,
    int? time,
    int? cookTime,
    int? prepTime,
    int? yields,
    String? source,
    String? image,
    bool? public,
    List<RecipeItem>? items,
    Set<Tag>? tags,
    Set<int>? plannedDays,
    int? householdId,
  }) =>
      Recipe(
        id: id,
        name: name ?? this.name,
        description: description ?? this.description,
        items: items ?? this.items,
        isPlanned: isPlanned ?? this.isPlanned,
        time: time ?? this.time,
        cookTime: cookTime ?? this.cookTime,
        prepTime: prepTime ?? this.prepTime,
        yields: yields ?? this.yields,
        source: source ?? this.source,
        imageHash: imageHash,
        image: image ?? this.image,
        tags: tags ?? this.tags,
        plannedDays: plannedDays ?? this.plannedDays,
        public: public ?? this.public,
        householdId: householdId ?? this.householdId,
        household: this.household,
      );

  Recipe withYields(int yields) {
    if (yields == this.yields) return this;

    return copyWith(
      items: items
          .map((item) => item.withFactor(Fraction(yields, this.yields)))
          .toList(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        isPlanned,
        time,
        cookTime,
        prepTime,
        yields,
        source,
        image,
        imageHash,
        tags,
        items,
        plannedDays,
        public,
        householdId,
        household,
      ];

  @override
  Map<String, dynamic> toJson() => {
        "name": name,
        "description": description,
        "time": time,
        "cook_time": cookTime,
        "prep_time": prepTime,
        "yields": yields,
        "source": source,
        "public": public,
        if (image != null) "photo": image,
        "items": items.map((e) => e.toJson()).toList(),
        "tags": tags.map((e) => e.toString()).toList(),
      };

  @override
  Map<String, dynamic> toJsonWithId() => toJson()
    ..addAll({
      "id": id,
      "planned": isPlanned,
      "items": items.map((e) => e.toJsonWithId()).toList(),
      "tags": tags.map((e) => e.toJsonWithId()).toList(),
      if (imageHash != null) "photo_hash": imageHash,
      "planned_days": plannedDays.toList(),
      "household_id": householdId,
    });

  @override
  bool get isShowSuspension => true;

  @override
  String getSuspensionTag() => name[0].toUpperCase();

  @override
  set isShowSuspension(bool isShowSuspension) {}

  List<RecipeItem> get optionalItems => items.where((e) => e.optional).toList();
  List<RecipeItem> get mandatoryItems =>
      items.where((e) => !e.optional).toList();
}
