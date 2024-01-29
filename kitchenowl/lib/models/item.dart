import 'package:fraction/fraction.dart';
import 'package:kitchenowl/helpers/string_scaler.dart';
import 'package:kitchenowl/models/category.dart';
import 'package:kitchenowl/models/model.dart';

import 'nullable.dart';

class Item extends Model {
  final int? id;
  final String name;
  final String? icon;
  final int ordering;
  final Category? category;
  final DateTime? createdAt;

  const Item({
    this.id,
    required this.name,
    this.icon,
    this.ordering = 0,
    this.category,
    this.createdAt,
  });

  factory Item.fromJson(Map<String, dynamic> map) => Item(
        id: map['id'],
        name: map['name'],
        ordering: map['ordering'],
        icon: map['icon'],
        category:
            map['category'] != null ? Category.fromJson(map['category']) : null,
        createdAt: map['created_at'] != null
            ? DateTime.fromMillisecondsSinceEpoch(map['created_at'],
                    isUtc: true)
                .toLocal()
            : null,
      );

  Item copyWith({
    String? name,
    Nullable<Category>? category,
    Nullable<String>? icon,
  }) =>
      Item(
        id: id,
        name: name ?? this.name,
        category: (category ?? Nullable(this.category)).value,
        icon: (icon ?? Nullable(this.icon)).value,
        ordering: ordering,
        createdAt: createdAt,
      );

  @override
  List<Object?> get props => [id, name, icon, ordering, category, createdAt];

  @override
  Map<String, dynamic> toJson() => {
        "name": name,
      };

  @override
  Map<String, dynamic> toJsonWithId() => toJson()
    ..addAll({
      "id": id,
      "ordering": ordering,
      "icon": icon,
      "category": category?.toJsonWithId(),
      "created_at": createdAt?.toUtc().millisecondsSinceEpoch,
    });
}

class ItemWithDescription extends Item {
  final String description;

  const ItemWithDescription({
    super.id,
    required super.name,
    super.ordering = 0,
    super.icon,
    super.category,
    this.description = '',
    super.createdAt,
  });

  factory ItemWithDescription.fromJson(Map<String, dynamic> map) =>
      ItemWithDescription(
        id: map['id'],
        name: map['name'],
        description: map['description'] ?? "",
        icon: map['icon'],
        category:
            map['category'] != null ? Category.fromJson(map['category']) : null,
        createdAt: map['created_at'] != null
            ? DateTime.fromMillisecondsSinceEpoch(map['created_at'],
                    isUtc: true)
                .toLocal()
            : null,
      );

  factory ItemWithDescription.fromItem({
    required Item item,
    String? description,
  }) =>
      ItemWithDescription(
        id: item.id,
        name: item.name,
        icon: item.icon,
        category: item.category,
        ordering: item.ordering,
        description: description ??
            ((item is ItemWithDescription) ? item.description : ''),
        createdAt: item.createdAt,
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
    Nullable<String>? icon,
    String? description,
  }) =>
      ItemWithDescription(
        id: id,
        name: name ?? this.name,
        category: (category ?? Nullable(this.category)).value,
        icon: (icon ?? Nullable(this.icon)).value,
        description: description ?? this.description,
        ordering: ordering,
        createdAt: createdAt,
      );

  @override
  List<Object?> get props => super.props + [description];
}

class ShoppinglistItem extends ItemWithDescription {
  final int? createdById;

  const ShoppinglistItem({
    super.id,
    required super.name,
    super.description = '',
    super.category,
    super.icon,
    super.ordering = 0,
    this.createdById,
    super.createdAt,
  });

  factory ShoppinglistItem.fromJson(Map<String, dynamic> map) {
    return ShoppinglistItem(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      ordering: map['ordering'],
      icon: map['icon'],
      category:
          map['category'] != null ? Category.fromJson(map['category']) : null,
      createdAt: map['created_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['created_at'], isUtc: true)
              .toLocal()
          : null,
      createdById: map['created_by'],
    );
  }

  /// Turn an Item into a Shopping list item.
  ///
  /// If description is null and item is an ItemWithDescription the existing description is used.
  factory ShoppinglistItem.fromItem({
    required Item item,
    String? description,
    DateTime? createdAt,
    int? createdById,
  }) =>
      ShoppinglistItem(
        id: item.id,
        name: item.name,
        icon: item.icon,
        description: description ??
            (item is ItemWithDescription ? item.description : ""),
        category: item.category,
        ordering: item.ordering,
        createdAt: createdAt ?? DateTime.now(),
        createdById: createdById,
      );

  @override
  ShoppinglistItem copyWith({
    String? name,
    Nullable<Category>? category,
    Nullable<String>? icon,
    String? description,
  }) =>
      ShoppinglistItem(
        id: id,
        name: name ?? this.name,
        category: (category ?? Nullable(this.category)).value,
        icon: (icon ?? Nullable(this.icon)).value,
        description: description ?? this.description,
        ordering: ordering,
        createdAt: createdAt,
        createdById: createdById,
      );

  @override
  List<Object?> get props => super.props + [createdById];

  @override
  Map<String, dynamic> toJsonWithId() => super.toJsonWithId()
    ..addAll({
      "created_by": createdById,
    });
}

class RecipeItem extends ItemWithDescription {
  final bool optional;

  const RecipeItem({
    super.id,
    required super.name,
    super.description = '',
    super.ordering = 0,
    super.category,
    super.icon,
    this.optional = false,
  });

  factory RecipeItem.fromJson(Map<String, dynamic> map) => RecipeItem(
        id: map['id'],
        name: map['name'] ?? '',
        description: map['description'],
        icon: map['icon'],
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
        icon: item.icon,
        category: item.category,
        ordering: item.ordering,
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
    Nullable<String>? icon,
    String? description,
    bool? optional,
  }) =>
      RecipeItem(
        id: id,
        name: name ?? this.name,
        category: (category ?? Nullable(this.category)).value,
        icon: (icon ?? Nullable(this.icon)).value,
        description: description ?? this.description,
        optional: optional ?? this.optional,
      );

  RecipeItem withFactor(
    Fraction factor, {
    bool addDescriptionWhenEmpty = true,
  }) {
    if (!addDescriptionWhenEmpty) return this;

    return copyWith(description: StringScaler.scale(description, factor));
  }

  Item toItem() => Item(
        id: id,
        name: name,
        icon: icon,
        ordering: ordering,
        category: category,
      );

  ItemWithDescription toItemWithDescription() => ItemWithDescription(
        id: id,
        name: name,
        icon: icon,
        ordering: ordering,
        category: category,
        description: description,
      );

  ShoppinglistItem toShoppingListItem() => ShoppinglistItem(
        id: id,
        name: name,
        icon: icon,
        ordering: ordering,
        category: category,
        description: description,
      );

  @override
  List<Object?> get props => super.props + [optional];
}
