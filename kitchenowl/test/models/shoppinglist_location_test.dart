import 'package:flutter_test/flutter_test.dart';
import 'package:kitchenowl/models/shoppinglist.dart';
import 'package:kitchenowl/services/location_service.dart';

void main() {
  const marienplatz = ShoppingListLocation(
    name: 'Marienplatz',
    latitude: 48.137154,
    longitude: 11.576124,
  );

  group('ShoppingListLocation', () {
    test('calculates distances', () {
      // Marienplatz -> Munich central station is roughly 1.4 km
      final distance = marienplatz.distanceTo(48.140229, 11.558339);
      expect(distance, closeTo(1360, 50));
      expect(marienplatz.distanceTo(48.137154, 11.576124), 0);
    });

    test('contains positions within its radius', () {
      expect(marienplatz.contains(48.1375, 11.5765), isTrue);
      expect(marienplatz.contains(48.140229, 11.558339), isFalse);
    });

    test('json roundtrip', () {
      final location = ShoppingListLocation.fromJson(marienplatz.toJson());
      expect(location, marienplatz);
      expect(location.radius, ShoppingListLocation.defaultRadius);
    });

    test('shopping list parses locations', () {
      final list = ShoppingList.fromJson({
        'id': 1,
        'name': 'Supermarket',
        'locations': [
          {'id': 3, 'name': null, 'latitude': 1, 'longitude': 2, 'radius': 300},
        ],
      });
      expect(list.locations.single.latitude, 1.0);
      expect(list.locations.single.radius, 300);
      expect(list.toJson().containsKey('locations'), isFalse);
      expect(list.toJsonWithLocations()['locations'], hasLength(1));
      expect(ShoppingList.fromJson(list.toJsonWithId()), list);
      expect(ShoppingList.fromJson({'id': 2, 'name': 'a'}).locations, isEmpty);
    });
  });

  group('LocationService.findShoppingListAt', () {
    const food = ShoppingList(id: 1, name: 'Food', locations: [
      ShoppingListLocation(latitude: 48.0, longitude: 11.0, radius: 500),
    ]);
    const hardware = ShoppingList(id: 2, name: 'Hardware', locations: [
      ShoppingListLocation(latitude: 50.0, longitude: 8.0),
      ShoppingListLocation(latitude: 48.001, longitude: 11.0, radius: 500),
    ]);

    test('finds the closest matching location', () {
      final match =
          LocationService.findShoppingListAt([food, hardware], 48.0009, 11.0);
      expect(match?.$1, hardware);
      expect(match?.$2, hardware.locations[1]);

      expect(
        LocationService.findShoppingListAt([food, hardware], 48.0, 11.0)?.$1,
        food,
      );
    });

    test('supports multiple locations per list', () {
      expect(
        LocationService.findShoppingListAt([food, hardware], 50.0005, 8.0)?.$1,
        hardware,
      );
    });

    test('returns null outside of all locations', () {
      expect(LocationService.findShoppingListAt([food, hardware], 0, 0), null);
    });
  });
}
