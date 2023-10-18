// ignore_for_file: prefer_const_constructors
import 'package:flutter_test/flutter_test.dart';
import 'package:kitchenowl/models/expense_category.dart';

void main() {
  test("ExpenseCategory should be equal", () {
    // Given
    final c1 = ExpenseCategory(id: 1, name: "Name");
    final c2 = ExpenseCategory(id: 1, name: "Name");
    // Then
    expect(c1 == c2, equals(true));
  });
  test("ExpenseCategory should not be equal", () {
    // Given
    final c1 = ExpenseCategory(id: 1, name: "Name");
    final c2 = ExpenseCategory(id: 1, name: "Name");
    // Then
    expect(c1 == c2, equals(false));
  });
  test("ExpenseCategory should de-/serialize", () {
    // Given
    final c = ExpenseCategory(id: 1, name: "Name");
    // When
    final actual = ExpenseCategory.fromJson(c.toJsonWithId());
    // Then
    expect(actual, equals(c));
  });
}
