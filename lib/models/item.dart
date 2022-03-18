import 'package:kitchenowl/models/model.dart';

class Item extends Model {
  final int? id;
  final String name;
  final int ordering;

  const Item({this.id, required this.name, this.ordering = 0});

  factory Item.fromJson(Map<String, dynamic> map) => Item(
        id: map['id'],
        name: map['name'],
        ordering: map['ordering'],
      );

  @override
  List<Object?> get props => [id, name, ordering];

  @override
  Map<String, dynamic> toJson() => {
        "name": name,
      };

  @override
  Map<String, dynamic> toJsonWithId() => toJson()
    ..addAll({
      "id": id,
      "ordering": ordering,
    });
}

class ItemWithDescription extends Item {
  final String description;

  const ItemWithDescription({
    int? id,
    required String name,
    int ordering = 0,
    this.description = '',
  }) : super(id: id, name: name, ordering: ordering);

  factory ItemWithDescription.fromJson(Map<String, dynamic> map) =>
      ItemWithDescription(
        id: map['id'],
        name: map['name'],
        description: map['description'],
      );

  factory ItemWithDescription.fromItem({
    required Item item,
    String description = '',
  }) =>
      ItemWithDescription(
        id: item.id,
        name: item.name,
        description: description,
      );

  @override
  Map<String, dynamic> toJson() => super.toJson()
    ..addAll({
      "description": description,
    });

  ItemWithDescription copyWith({
    String? name,
    String? description,
  }) =>
      ItemWithDescription(
        id: id,
        name: name ?? this.name,
        description: description ?? this.description,
      );

  @override
  List<Object?> get props => super.props + [description];
}

class ShoppinglistItem extends ItemWithDescription {
  const ShoppinglistItem({
    int? id,
    required String name,
    String description = '',
    int ordering = 0,
  }) : super(id: id, name: name, description: description, ordering: ordering);

  factory ShoppinglistItem.fromJson(Map<String, dynamic> map) =>
      ShoppinglistItem(
        id: map['id'],
        name: map['name'],
        description: map['description'],
        ordering: map['ordering'],
      );

  factory ShoppinglistItem.fromItem({
    required Item item,
    String description = '',
  }) =>
      ShoppinglistItem(
        id: item.id,
        name: item.name,
        description: description,
      );

  @override
  ShoppinglistItem copyWith({
    String? name,
    String? description,
  }) =>
      ShoppinglistItem(
        id: id,
        name: name ?? this.name,
        description: description ?? this.description,
      );
}

class RecipeItem extends ItemWithDescription {
  final bool optional;

  const RecipeItem({
    int? id,
    required String name,
    String description = '',
    int ordering = 0,
    this.optional = false,
  }) : super(id: id, name: name, description: description, ordering: ordering);

  factory RecipeItem.fromJson(Map<String, dynamic> map) => RecipeItem(
        id: map['id'],
        name: map['name'] ?? '',
        description: map['description'],
        optional: map['optional'],
      );

  factory RecipeItem.fromItem({
    required Item item,
    String description = '',
    bool optional = false,
  }) =>
      RecipeItem(
        id: item.id,
        name: item.name,
        description: description,
        optional: optional,
      );

  @override
  Map<String, dynamic> toJson() => super.toJson()
    ..addAll({
      "optional": optional,
    });

  @override
  RecipeItem copyWith({
    String? name,
    String? description,
    bool? optional,
  }) =>
      RecipeItem(
        id: id,
        name: name ?? this.name,
        description: description ?? this.description,
        optional: optional ?? this.optional,
      );

  Item toItem() => Item(id: id, name: name);

  ItemWithDescription toItemWithDescription() =>
      ItemWithDescription(id: id, name: name, description: description);

  ShoppinglistItem toShoppingListItem() =>
      ShoppinglistItem(id: id, name: name, description: description);

  @override
  List<Object?> get props => super.props + [optional];
}
