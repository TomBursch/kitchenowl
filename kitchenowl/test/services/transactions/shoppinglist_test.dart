import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitchenowl/models/household.dart';
import 'package:kitchenowl/models/item.dart';
import 'package:kitchenowl/models/shoppinglist.dart';
import 'package:kitchenowl/services/storage/mem_storage.dart';
import 'package:kitchenowl/services/transactions/shoppinglist.dart';

const household = Household(id: 1);

Future<List<String>> searchLocally(String query) async =>
    (await TransactionShoppingListSearchItem(
      household: household,
      query: query,
    ).runLocal())
        .map((e) => e.name)
        .toList();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // MemStorage may hand out the same instance, so use mutable lists
  ShoppingList initialList() => ShoppingList(
        id: 1,
        name: "Groceries",
        items: [
          ShoppinglistItem(id: 1, name: "Œuf"),
          ShoppinglistItem(id: 2, name: "Milk"),
        ],
        recentItems: [
          ItemWithDescription(id: 3, name: "Äpple"),
          ItemWithDescription(id: 4, name: "Crème fraîche"),
        ],
      );

  setUpAll(() async {
    final cacheDir = await Directory.systemTemp.createTemp('kitchenowl_test');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (_) async => cacheDir.path,
    );
  });

  setUp(() async {
    await MemStorage.getInstance().writeShoppingLists(household, [
      initialList(),
    ]);
  });

  Future<ShoppingList> readShoppingList() async =>
      (await MemStorage.getInstance().readShoppingLists(household))!
          .firstWhere((e) => e.id == 1);

  test("Offline search ignores case", () async {
    expect(await searchLocally("MILK"), ["Milk"]);
  });

  test("Offline search matches ligatures", () async {
    expect(await searchLocally("oeuf"), ["Œuf"]);
    expect(await searchLocally("Œu"), ["Œuf"]);
  });

  test("Offline search ignores diacritics", () async {
    expect(await searchLocally("apple"), ["Äpple"]);
    expect(await searchLocally("creme"), ["Crème fraîche"]);
  });

  test("Remove item moves it to the recent items", () async {
    await TransactionShoppingListRemoveItem(
      household: household,
      shoppinglist: initialList(),
      item: const ShoppinglistItem(id: 2, name: "Milk"),
    ).runLocal();

    final list = await readShoppingList();
    expect(list.items.map((e) => e.name), ["Œuf"]);
    expect(list.recentItems.first.name, "Milk");
  });

  test("Hard remove does not touch the recent items", () async {
    await TransactionShoppingListRemoveItem(
      household: household,
      shoppinglist: initialList(),
      item: const ShoppinglistItem(id: 2, name: "Milk"),
      hard: true,
    ).runLocal();

    final list = await readShoppingList();
    expect(list.items.map((e) => e.name), ["Œuf"]);
    expect(
      list.recentItems.map((e) => e.name),
      ["Äpple", "Crème fraîche"],
    );
  });

  test("Hard remove multiple items does not touch the recent items", () async {
    await TransactionShoppingListRemoveItems(
      household: household,
      shoppinglist: initialList(),
      items: const [
        ShoppinglistItem(id: 1, name: "Œuf"),
        ShoppinglistItem(id: 2, name: "Milk"),
      ],
      hard: true,
    ).runLocal();

    final list = await readShoppingList();
    expect(list.items, isEmpty);
    expect(
      list.recentItems.map((e) => e.name),
      ["Äpple", "Crème fraîche"],
    );
  });

  test("Hard flag is serialized in transactions", () {
    final transaction = TransactionShoppingListRemoveItem(
      household: household,
      shoppinglist: initialList(),
      item: const ShoppinglistItem(id: 2, name: "Milk"),
      hard: true,
    );
    final map = transaction.toJson();
    expect(map["hard"], true);

    final restored = TransactionShoppingListRemoveItem.fromJson(
      map,
      DateTime.now(),
    );
    expect(restored.hard, true);
  });

  test("Transactions without hard flag are soft", () {
    final map = TransactionShoppingListRemoveItem(
      household: household,
      shoppinglist: initialList(),
      item: const ShoppinglistItem(id: 2, name: "Milk"),
    ).toJson();
    expect(map.containsKey("hard"), false);

    final restored = TransactionShoppingListRemoveItem.fromJson(
      map,
      DateTime.now(),
    );
    expect(restored.hard, false);

    final itemsRestored = TransactionShoppingListRemoveItems.fromJson(
      TransactionShoppingListRemoveItems(
        household: household,
        shoppinglist: initialList(),
        items: const [ShoppinglistItem(id: 2, name: "Milk")],
        hard: true,
      ).toJson(),
      DateTime.now(),
    );
    expect(itemsRestored.hard, true);
  });
}
