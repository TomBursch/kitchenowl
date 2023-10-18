// ignore_for_file: prefer_const_constructors
import 'package:flutter_test/flutter_test.dart';
import 'package:kitchenowl/models/category.dart';

void main() {
  test("Category should be equal", () {
    // Given
    final c1 = Category(id: 1, name: "Name", ordering: 1);
    final c2 = Category(id: 1, name: "Name", ordering: 1);
    // Then
    expect(c1 == c2, equals(true));
  });
  test("Category should not be equal", () {
    // Given
    final c1 = Category(id: 1, name: "Name", ordering: 1);
    final c2 = Category(id: 1, name: "Name", ordering: 3);
    // Then
    expect(c1 == c2, equals(false));
  });
  test("Category should de-/serialize", () {
    // Given
    final c = Category(id: 1, name: "Name", ordering: 1);
    // When
    final actual = Category.fromJson(c.toJsonWithId());
    // Then
    expect(actual, equals(c));
  });
}
