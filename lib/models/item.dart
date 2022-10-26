import 'package:intl/intl.dart';
import 'package:kitchenowl/models/category.dart';
import 'package:kitchenowl/models/model.dart';

import 'nullable.dart';

class Item extends Model {
  final int? id;
  final String name;
  final int ordering;
  final Category? category;

  const Item({
    this.id,
    required this.name,
    this.ordering = 0,
    this.category,
  });

  factory Item.fromJson(Map<String, dynamic> map) => Item(
        id: map['id'],
        name: map['name'],
        ordering: map['ordering'],
        category:
            map['category'] != null ? Category.fromJson(map['category']) : null,
      );

  Item copyWith({
    String? name,
    Nullable<Category>? category,
  }) =>
      ItemWithDescription(
        id: id,
        name: name ?? this.name,
        category: (category ?? Nullable(this.category)).value,
      );

  @override
  List<Object?> get props => [id, name, ordering, category];

  @override
  Map<String, dynamic> toJson() => {
        "name": name,
      };

  @override
  Map<String, dynamic> toJsonWithId() => toJson()
    ..addAll({
      "id": id,
      "ordering": ordering,
      "category": category?.name,
    });
}

class ItemWithDescription extends Item {
  final String description;

  const ItemWithDescription({
    super.id,
    required super.name,
    super.ordering = 0,
    super.category,
    this.description = '',
  });

  factory ItemWithDescription.fromJson(Map<String, dynamic> map) =>
      ItemWithDescription(
        id: map['id'],
        name: map['name'],
        description: map['description'] ?? "",
        category:
            map['category'] != null ? Category.fromJson(map['category']) : null,
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

  @override
  ItemWithDescription copyWith({
    String? name,
    Nullable<Category>? category,
    String? description,
  }) =>
      ItemWithDescription(
        id: id,
        name: name ?? this.name,
        category: (category ?? Nullable(this.category)).value,
        description: description ?? this.description,
      );

  @override
  List<Object?> get props => super.props + [description];
}

class ShoppinglistItem extends ItemWithDescription {
  const ShoppinglistItem({
    super.id,
    required super.name,
    super.description = '',
    super.category,
    super.ordering = 0,
  });

  factory ShoppinglistItem.fromJson(Map<String, dynamic> map) {
    return ShoppinglistItem(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      ordering: map['ordering'],
      category:
          map['category'] != null ? Category.fromJson(map['category']) : null,
    );
  }

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
    Nullable<Category>? category,
    String? description,
  }) =>
      ShoppinglistItem(
        id: id,
        name: name ?? this.name,
        category: (category ?? Nullable(this.category)).value,
        description: description ?? this.description,
      );
}

class RecipeItem extends ItemWithDescription {
  final bool optional;

  const RecipeItem({
    super.id,
    required super.name,
    super.description = '',
    super.ordering = 0,
    super.category,
    this.optional = false,
  });

  factory RecipeItem.fromJson(Map<String, dynamic> map) => RecipeItem(
        id: map['id'],
        name: map['name'] ?? '',
        description: map['description'],
        optional: map['optional'],
        category:
            map['category'] != null ? Category.fromJson(map['category']) : null,
      );

  factory RecipeItem.fromItem({
    required Item item,
    String description = '',
    bool optional = false,
  }) =>
      RecipeItem(
        id: item.id,
        name: item.name,
        description:
            item is ItemWithDescription ? item.description : description,
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
    Nullable<Category>? category,
    String? description,
    bool? optional,
  }) =>
      RecipeItem(
        id: id,
        name: name ?? this.name,
        category: (category ?? Nullable(this.category)).value,
        description: description ?? this.description,
        optional: optional ?? this.optional,
      );

  // ignore: long-method
  RecipeItem withFactor(double factor) {
    if (factor == 1) return this;
    String description = this.description.replaceAllMapped(
      RegExp('¼|½|¾|⅐|⅑|⅒|⅓|⅔|⅕|⅖|⅗|⅘|⅙|⅚|⅛|⅜|⅝|⅞'),
      (match) {
        switch (match.group(0)!) {
          case '¼':
            return '0.25';
          case '½':
            return '0.5';
          case '¾':
            return '0.75';
          case '⅐':
            return '0.142857142857';
          case '⅑':
            return '0.111111111111';
          case '⅒':
            return '0.1';
          case '⅓':
            return '0.333333333333';
          case '⅔':
            return '0.666666666667';
          case '⅕':
            return '0.2';
          case '⅖':
            return '0.4';
          case '⅗':
            return '0.6';
          case '⅘':
            return '0.8';
          case '⅙':
            return '0.166666666667';
          case '⅚':
            return '0.833333333333';
          case '⅛':
            return '0.125';
          case '⅜':
            return '0.375';
          case '⅝':
            return '0.625';
          case '⅞':
            return '0.875';
          default:
            return match.group(0)!;
        }
      },
    );
    description = description.replaceAllMapped(
      RegExp(',(\\d)'),
      (match) => '.${match.group(1)}',
    );
    description = description.replaceAllMapped(
      RegExp("\\d+((\\.)\\d+)?((e|E)\\d+)?"),
      (match) => NumberFormat.decimalPattern().format(
        (double.tryParse(match.group(0)!)! * factor * 100).round() / 100,
      ),
    );

    return copyWith(description: description);
  }

  Item toItem() => Item(id: id, name: name);

  ItemWithDescription toItemWithDescription() =>
      ItemWithDescription(id: id, name: name, description: description);

  ShoppinglistItem toShoppingListItem() =>
      ShoppinglistItem(id: id, name: name, description: description);

  @override
  List<Object?> get props => super.props + [optional];
}
