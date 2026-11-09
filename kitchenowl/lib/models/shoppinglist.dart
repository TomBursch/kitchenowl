import 'dart:math';

import 'package:kitchenowl/models/item.dart';
import 'package:kitchenowl/models/model.dart';

class ShoppingList extends Model {
  final int? id;
  final String name;
  final List<ShoppinglistItem> items;
  final List<ItemWithDescription> recentItems;
  final List<ShoppingListLocation> locations;

  const ShoppingList({
    this.id,
    required this.name,
    this.items = const [],
    this.recentItems = const [],
    this.locations = const [],
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
    List<ShoppingListLocation> locations = const [];
    if (map['locations'] != null) {
      locations = List.from(
          map['locations'].map((e) => ShoppingListLocation.fromJson(e)));
    }

    return ShoppingList(
      id: map['id'],
      name: map['name'],
      items: items,
      recentItems: recentItems,
      locations: locations,
    );
  }

  ShoppingList copyWith({
    String? name,
    List<ShoppinglistItem>? items,
    List<ItemWithDescription>? recentItems,
    List<ShoppingListLocation>? locations,
  }) =>
      ShoppingList(
        id: id,
        name: name ?? this.name,
        items: items ?? this.items,
        recentItems: recentItems ?? this.recentItems,
        locations: locations ?? this.locations,
      );

  @override
  List<Object?> get props => [id, name, items, recentItems, locations];

  @override
  Map<String, dynamic> toJson() => {
        "name": name,
      };

  Map<String, dynamic> toJsonWithLocations() => toJson()
    ..addAll({
      "locations": locations.map((e) => e.toJson()).toList(),
    });

  @override
  Map<String, dynamic> toJsonWithId() => toJsonWithLocations()
    ..addAll({
      "id": id,
      "items": items.map((e) => e.toJsonWithId()).toList(),
      "recentItems": recentItems.map((e) => e.toJsonWithId()).toList(),
    });
}

/// A store location (geofence) assigned to a shopping list.
class ShoppingListLocation extends Model {
  static const int defaultRadius = 150;
  static const int minRadius = 50;
  static const int maxRadius = 2000;

  final String? name;
  final double latitude;
  final double longitude;

  /// Radius in meters
  final int radius;

  const ShoppingListLocation({
    this.name,
    required this.latitude,
    required this.longitude,
    this.radius = defaultRadius,
  });

  factory ShoppingListLocation.fromJson(Map<String, dynamic> map) =>
      ShoppingListLocation(
        name: map['name'],
        latitude: (map['latitude'] as num).toDouble(),
        longitude: (map['longitude'] as num).toDouble(),
        radius: map['radius'] ?? defaultRadius,
      );

  /// Distance in meters between this location and the given coordinates
  double distanceTo(double latitude, double longitude) {
    const earthRadius = 6371000.0;
    double rad(double deg) => deg * pi / 180;
    final dLat = rad(latitude - this.latitude);
    final dLon = rad(longitude - this.longitude);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(rad(this.latitude)) *
            cos(rad(latitude)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    return earthRadius * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  bool contains(double latitude, double longitude) =>
      distanceTo(latitude, longitude) <= radius;

  @override
  List<Object?> get props => [name, latitude, longitude, radius];

  @override
  Map<String, dynamic> toJson() => {
        "name": name,
        "latitude": latitude,
        "longitude": longitude,
        "radius": radius,
      };
}
