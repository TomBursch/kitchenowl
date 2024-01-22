// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables
import 'package:flutter_test/flutter_test.dart';
import 'package:kitchenowl/enums/views_enum.dart';
import 'package:kitchenowl/models/household.dart';
import 'package:kitchenowl/models/member.dart';
import 'package:kitchenowl/models/shoppinglist.dart';

void main() {
  test("Household should be equal", () {
    // Given
    final h1 = Household(id: 1, name: "Name", featureExpenses: true);
    final h2 = Household(id: 1, name: "Name", featureExpenses: true);
    // Then
    expect(h1 == h2, equals(true));
  });
  test("Household should not be equal", () {
    // Given
    final h1 = Household(id: 1, name: "Name", featureExpenses: true);
    final h2 = Household(id: 1, name: "Name", featureExpenses: false);
    // Then
    expect(h1 == h2, equals(false));
  });
  test("Household should de-/serialize", () {
    // Given
    final h = Household(
      id: 1,
      name: "Name",
      featureExpenses: true,
      featurePlanner: false,
      defaultShoppingList: ShoppingList(name: "S"),
      viewOrdering: ViewsEnum.addMissing(ViewsEnum.values.sublist(1, 4)),
      member: [Member(id: 0, name: "M", username: "username")],
    );
    // When
    final actual = Household.fromJson(h.toJsonWithId());
    // Then
    expect(actual, equals(h));
  });
}
