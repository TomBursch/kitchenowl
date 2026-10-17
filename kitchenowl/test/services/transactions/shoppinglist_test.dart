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

  setUpAll(() async {
    final cacheDir = await Directory.systemTemp.createTemp('kitchenowl_test');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (_) async => cacheDir.path,
    );
    await MemStorage.getInstance().writeShoppingLists(household, [
      const ShoppingList(
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
      ),
    ]);
  });

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
}
