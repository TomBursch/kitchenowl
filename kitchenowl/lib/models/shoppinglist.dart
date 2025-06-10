import 'package:kitchenowl/models/item.dart';
import 'package:kitchenowl/models/model.dart';

class ShoppingList extends Model {
  final int? id;
  final String name;
  final List<ShoppinglistItem> items;
  final List<ItemWithDescription> recentItems;
  final int order; // Add order field
  final bool isStandard; // Add standard list flag

  const ShoppingList({
    this.id,
    required this.name,
    this.items = const [],
    this.recentItems = const [],
    this.order = 0, // Default order
    this.isStandard = false, // Default not standard
  });

  factory ShoppingList.fromJson(Map<String, dynamic> map) {
    List<ShoppinglistItem> items = const [];
    if (map.containsKey('items')) {
      items = List.from(map['items'].map((e) => ShoppinglistItem.fromJson(e)));
    }
    List<ItemWithDescription> recentItems = const [];
    if (map.containsKey('recentItems')) {
      recentItems = List.from(
          map['recentItems'].map((e) => ItemWithDescription.fromJson(e)));
    }

    // Update fromJson to include order and isStandard
    return ShoppingList(
      id: map['id'],
      name: map['name'],
      items: items,
      recentItems: recentItems,
      order: json['order'] ?? 0, // Handle legacy data
      isStandard: json['is_standard'] ?? false,
    );
  }

  // Add copyWith method for reordering and standard list changes
  ShoppingList copyWith({
    String? name,
    List<ShoppinglistItem>? items,
    List<ItemWithDescription>? recentItems,
    int? order,
    bool? isStandard,
  }) =>
      ShoppingList(
        id: id,
        name: name ?? this.name,
        items: items ?? this.items,
        recentItems: recentItems ?? this.recentItems,
        order: order ?? this.order,
        isStandard: isStandard ?? this.isStandard,
      );

  @override
  List<Object?> get props => [id, name, items, recentItems];

  @override
  Map<String, dynamic> toJson() => {
        "name": name,
      };

  @override
  Map<String, dynamic> toJsonWithId() => toJson()
    ..addAll({
      "id": id,
      "items": items.map((e) => e.toJsonWithId()).toList(),
      "recentItems": recentItems.map((e) => e.toJsonWithId()).toList(),
    });
}
