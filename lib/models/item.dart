import 'package:flutter/foundation.dart';
import 'package:kitchenowl/models/model.dart';

class Item extends Model {
  final int id;
  final String name;

  const Item({this.id, this.name});

  factory Item.fromJson(Map<String, dynamic> map) => Item(
        id: map['id'],
        name: map['name'],
      );

  @override
  List<Object> get props => [this.id, this.name];

  @override
  Map<String, dynamic> toJson() => {
        "name": this.name,
      };

  @override
  Map<String, dynamic> toJsonWithId() => this.toJson()
    ..addAll({
      "id": this.id,
    });
}

class ItemWithDescription extends Item {
  final String description;

  const ItemWithDescription({int id, String name, this.description})
      : super(id: id, name: name);

  factory ItemWithDescription.fromJson(Map<String, dynamic> map) =>
      ItemWithDescription(
        id: map['id'],
        name: map['name'],
        description: map['description'],
      );

  factory ItemWithDescription.fromItem({
    @required Item item,
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
    String name,
    String description,
  }) =>
      ItemWithDescription(
        id: id,
        name: name ?? this.name,
        description: description ?? this.description,
      );

  @override
  List<Object> get props => super.props + [this.description];
}

class ShoppinglistItem extends ItemWithDescription {
  const ShoppinglistItem({int id, String name, String description})
      : super(id: id, name: name, description: description);

  factory ShoppinglistItem.fromJson(Map<String, dynamic> map) =>
      ShoppinglistItem(
        id: map['id'],
        name: map['name'],
        description: map['description'],
      );

  factory ShoppinglistItem.fromItem({
    @required Item item,
    String description = '',
  }) =>
      ShoppinglistItem(
        id: item.id,
        name: item.name,
        description: description,
      );

  @override
  Map<String, dynamic> toJson() => super.toJson();

  ShoppinglistItem copyWith({
    String name,
    String description,
  }) =>
      ShoppinglistItem(
        id: id,
        name: name ?? this.name,
        description: description ?? this.description,
      );

  @override
  List<Object> get props => super.props;
}

class RecipeItem extends ShoppinglistItem {
  final bool optional;

  const RecipeItem({int id, String name, String description, this.optional})
      : super(id: id, name: name, description: description);

  factory RecipeItem.fromJson(Map<String, dynamic> map) => RecipeItem(
        id: map['id'],
        name: map['name'],
        description: map['description'],
        optional: map['optional'],
      );

  factory RecipeItem.fromItem({
    @required Item item,
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

  RecipeItem copyWith({
    String name,
    String description,
    bool optional,
  }) =>
      RecipeItem(
        id: id,
        name: name ?? this.name,
        description: description ?? this.description,
        optional: optional ?? this.optional,
      );

  Item toItem() => Item(id: this.id, name: this.name);

  @override
  List<Object> get props => super.props + [this.optional];
}
