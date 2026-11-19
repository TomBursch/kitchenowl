import 'package:flutter_test/flutter_test.dart';
import 'package:kitchenowl/cubits/item_search_cubit.dart';
import 'package:kitchenowl/models/item.dart';

void main() {
  const persian = ItemWithDescription(name: "Persian rice");
  const pepper = ItemWithDescription(name: "Pepper");
  const milk = ItemWithDescription(name: "Milk");
  const milkChocolate = ItemWithDescription(name: "Milk chocolate");

  test("Unknown item is put before similar suggestions", () {
    final result = ItemSearchCubit.withExactMatchFirst(
      [persian, pepper],
      "Pepsi",
      "2l",
    );

    expect(result.map((e) => e.name), ["Pepsi", "Persian rice", "Pepper"]);
    expect((result.first as ItemWithDescription).description, "2l");
  });

  test("Unknown item is the only result without suggestions", () {
    final result = ItemSearchCubit.withExactMatchFirst(const [], "Pepsi", null);

    expect(result.map((e) => e.name), ["Pepsi"]);
  });

  test("Known item is moved to the front without duplicating it", () {
    final result = ItemSearchCubit.withExactMatchFirst(
      [milkChocolate, milk],
      "milk",
      null,
    );

    expect(result, [milk, milkChocolate]);
  });

  test("Known item matches ignoring accents and case", () {
    final result = ItemSearchCubit.withExactMatchFirst(
      [pepper, const ItemWithDescription(name: "Crème fraîche")],
      "CREME FRAICHE",
      null,
    );

    expect(result.map((e) => e.name), ["Crème fraîche", "Pepper"]);
  });

  test("Exact match already in front stays untouched", () {
    final items = [milk, milkChocolate];

    expect(ItemSearchCubit.withExactMatchFirst(items, "Milk", null), items);
  });
}
