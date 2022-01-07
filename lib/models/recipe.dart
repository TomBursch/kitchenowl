import 'package:kitchenowl/models/item.dart';
import 'package:kitchenowl/models/model.dart';
import 'package:kitchenowl/models/tag.dart';

class Recipe extends Model {
  final int id;
  final String name;
  final String description;
  final bool isPlanned;
  final int time;
  final List<RecipeItem> items;
  final List<Tag> tags;

  const Recipe({
    this.id,
    this.name = '',
    this.description = '',
    this.isPlanned = false,
    this.time = 0,
    this.items = const [],
    this.tags = const [],
  });

  factory Recipe.fromJson(Map<String, dynamic> map) {
    List<RecipeItem> items = const [];
    if (map.containsKey('items')) {
      items = List.from(map['items'].map((e) => RecipeItem.fromJson(e)));
    }
    List<Tag> tags = const [];
    if (map.containsKey('tags')) {
      tags = List.from(map['tags'].map((e) => Tag.fromJson(e)));
    }
    return Recipe(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      isPlanned: map['planned'] ?? false,
      time: map['time'] ?? 0,
      items: items,
      tags: tags,
    );
  }

  Recipe copyWith({
    String name,
    String description,
    bool isPlanned,
    int time,
    List<RecipeItem> items,
    List<Tag> tags,
  }) =>
      Recipe(
        id: id,
        name: name ?? this.name,
        description: description ?? this.description,
        items: items ?? this.items,
        isPlanned: isPlanned ?? this.isPlanned,
        time: time ?? this.time,
        tags: tags ?? this.tags,
      );

  @override
  List<Object> get props => [id, name, description];

  @override
  Map<String, dynamic> toJson() => {
        "name": name,
        "description": description,
        "time": time,
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
    });
}
