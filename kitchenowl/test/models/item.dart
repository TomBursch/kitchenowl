// ignore_for_file: prefer_const_constructors
import 'package:flutter_test/flutter_test.dart';
import 'package:kitchenowl/models/item.dart';
import 'package:kitchenowl/models/store.dart';

void main() {
  test("Item should be equal", () {
    // Given
    final c1 = Item(id: 1, name: "Name", ordering: 1);
    final c2 = Item(id: 1, name: "Name", ordering: 1);
    // Then
    expect(c1 == c2, equals(true));
  });
  test("Item should not be equal", () {
    // Given
    final c1 = Item(id: 1, name: "Name", ordering: 1);
    final c2 = Item(id: 1, name: "Name", ordering: 3);
    // Then
    expect(c1 == c2, equals(false));
  });
  test("Item should de-/serialize", () {
    // Given
    final c = Item(id: 1, name: "Name", ordering: 1);
    // When
    final actual = Item.fromJson(c.toJsonWithId());
    // Then
    expect(actual, equals(c));
  });
  test("Item should de-/serialize with stores", () {
    // Given
    final c = Item(
      id: 1,
      name: "Name",
      ordering: 1,
      stores: [Store(id: 1, name: "Store A"), Store(id: 2, name: "Store B")],
    );
    // When
    final actual = Item.fromJson(c.toJsonWithId());
    // Then
    expect(actual, equals(c));
  });
}
