import 'package:kitchenowl/models/item.dart';
import 'package:kitchenowl/models/model.dart';

class Inventory extends Model {
  final int? id;
  final String name;
  final List<InventoryItem> items;
  final List<ItemWithDescription> recentItems;

  const Inventory({
    this.id,
    required this.name,
    this.items = const [],
    this.recentItems = const [],
  });

  factory Inventory.fromJson(Map<String, dynamic> map) {
    List<InventoryItem> items = const [];
    if (map.containsKey('items')) {
      items = List.from(map['items'].map((e) => InventoryItem.fromJson(e)));
    }
    List<ItemWithDescription> recentItems = const [];
    if (map.containsKey('recentItems')) {
      recentItems = List.from(
          map['recentItems'].map((e) => ItemWithDescription.fromJson(e)));
    }

    return Inventory(
      id: map['id'],
      name: map['name'],
      items: items,
      recentItems: recentItems,
    );
  }

  Inventory copyWith({
    String? name,
    List<InventoryItem>? items,
    List<ItemWithDescription>? recentItems,
  }) =>
      Inventory(
        id: id,
        name: name ?? this.name,
        items: items ?? this.items,
        recentItems: recentItems ?? this.recentItems,
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
