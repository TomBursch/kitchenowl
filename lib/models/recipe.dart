import 'package:kitchenowl/models/item.dart';
import 'package:kitchenowl/models/model.dart';

class Recipe extends Model {
  final int id;
  final String name;
  final String description;
  final bool isPlanned;
  final List<RecipeItem> items;

  const Recipe({
    this.id,
    this.name = '',
    this.description = '',
    this.isPlanned = false,
    this.items = const [],
  });

  factory Recipe.fromJson(Map<String, dynamic> map) {
    List<RecipeItem> items = const [];
    if (map.containsKey('items')) {
      items = List.from(map['items'].map((e) => RecipeItem.fromJson(e)));
    }
    return Recipe(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      isPlanned: map['planned'] ?? false,
      items: items,
    );
  }

  Recipe copyWith({
    String name,
    String description,
    List<RecipeItem> items,
  }) =>
      Recipe(
        id: id,
        name: name ?? this.name,
        description: description ?? this.description,
        items: items ?? this.items,
        isPlanned: isPlanned,
      );

  @override
  List<Object> get props => [id, name, description];

  @override
  Map<String, dynamic> toJson() => {
        "name": name,
        "description": description,
        "items": items.map((e) => e.toJson()).toList()
      };

  @override
  Map<String, dynamic> toJsonWithId() => toJson()
    ..addAll({
      "id": id,
      "planned": isPlanned,
      "items": items.map((e) => e.toJsonWithId()).toList(),
    });
}
