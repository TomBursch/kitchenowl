import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' as foundation;
import 'package:kitchenowl/models/category.dart';
import 'package:kitchenowl/models/household.dart';
import 'package:kitchenowl/models/item.dart';
import 'package:kitchenowl/models/recipe.dart';
import 'package:kitchenowl/models/shoppinglist.dart';
import 'package:kitchenowl/models/user.dart';
import 'package:path_provider/path_provider.dart';

class TempStorage {
  static TempStorage? _instance;

  TempStorage._internal();
  static TempStorage getInstance() {
    _instance ??= TempStorage._internal();

    return _instance!;
  }

  Future<String> get _localPath async {
    final temp = await getTemporaryDirectory();
    final directory = Directory('${temp.path}/kitchenowl');
    if (!await directory.exists()) directory.create();

    return directory.path;
  }

  Future<File> get _localUserFile async {
    final path = await _localPath;

    return File('$path/user.json');
  }

  Future<File> get _localHouseholdsFile async {
    final path = await _localPath;

    return File('$path/households.json');
  }

  Future<File> _localShoppingListsFile(Household household) async {
    final path = await _localPath;

    return File('$path/${household.id}-shoppinglists.json');
  }

  Future<File> _localItemFile(ShoppingList shoppinglist) async {
    final path = await _localPath;

    return File('$path/${shoppinglist.id}-items.json');
  }

  Future<File> _localRecipesFile(Household household) async {
    final path = await _localPath;

    return File('$path/${household.id}-recipes.json');
  }

  Future<File> _localCategoryFile(Household household) async {
    final path = await _localPath;

    return File('$path/${household.id}-categories.json');
  }

  Future<void> clearAll() async {
    await readHouseholds().then(
      (value) => Future.wait(
        value?.map((household) async {
              await readShoppingLists(household).then((value) =>
                  value?.map((shoppingList) => clearItems(shoppingList)));

              await Future.wait([
                clearShoppingLists(household),
                clearRecipes(household),
                clearCategories(household),
              ]);
            }).toList() ??
            [],
      ),
    );

    await Future.wait([
      clearUser(),
      clearHouseholds(),
    ]);
  }

  Future<User?> readUser() async {
    if (!foundation.kIsWeb) {
      try {
        final file = await _localUserFile;
        final String content = await file.readAsString();

        return User.fromJson(json.decode(content));
      } catch (_) {}
    }

    return null;
  }

  Future<void> clearUser() async {
    if (!foundation.kIsWeb) {
      try {
        final file = await _localUserFile;
        if (await file.exists()) await file.delete();
      } catch (_) {}
    }
  }

  Future<void> writeUser(User user) async {
    if (!foundation.kIsWeb) {
      final file = await _localUserFile;
      await file.writeAsString(json.encode(user.toJsonWithId()));
    }
  }

  Future<List<ShoppingList>?> readShoppingLists(Household household) async {
    if (!foundation.kIsWeb) {
      try {
        final file = await _localShoppingListsFile(household);
        final String content = await file.readAsString();
        List list = json.decode(content);

        return list.map((e) => ShoppingList.fromJson(e)).toList();
      } catch (_) {}
    }

    return null;
  }

  Future<void> clearShoppingLists(Household household) async {
    if (!foundation.kIsWeb) {
      try {
        final file = await _localShoppingListsFile(household);
        if (await file.exists()) await file.delete();
      } catch (_) {}
    }
  }

  Future<void> writeShoppingLists(
    Household household,
    List<ShoppingList> shoppingLists,
  ) async {
    if (!foundation.kIsWeb) {
      final file = await _localShoppingListsFile(household);
      await file.writeAsString(
        json.encode(shoppingLists.map((e) => e.toJsonWithId()).toList()),
      );
    }
  }

  Future<List<ShoppinglistItem>?> readItems(ShoppingList shoppingList) async {
    if (!foundation.kIsWeb) {
      try {
        final file = await _localItemFile(shoppingList);
        final String content = await file.readAsString();

        return List<ShoppinglistItem>.from(
          json.decode(content).map((e) => ShoppinglistItem.fromJson(e)),
        );
      } catch (_) {}
    }

    return null;
  }

  Future<void> writeItems(
    ShoppingList shoppinglist,
    List<ShoppinglistItem> items,
  ) async {
    if (!foundation.kIsWeb) {
      final file = await _localItemFile(shoppinglist);
      await file.writeAsString(
        json.encode(items.map((e) => e.toJsonWithId()).toList()),
      );
    }
  }

  Future<void> clearItems(ShoppingList shoppinglist) async {
    if (!foundation.kIsWeb) {
      try {
        final file = await _localItemFile(shoppinglist);
        if (await file.exists()) await file.delete();
      } catch (_) {}
    }
  }

  Future<List<Recipe>?> readRecipes(Household household) async {
    if (!foundation.kIsWeb) {
      try {
        final file = await _localRecipesFile(household);
        final String content = await file.readAsString();

        return List<Recipe>.from(
          json.decode(content).map((e) => Recipe.fromJson(e)),
        );
      } catch (_) {}
    }

    return null;
  }

  Future<void> writeRecipes(Household household, List<Recipe> recipes) async {
    if (!foundation.kIsWeb) {
      final file = await _localRecipesFile(household);
      await file.writeAsString(
        json.encode(recipes.map((e) => e.toJsonWithId()).toList()),
      );
    }
  }

  Future<void> clearRecipes(Household household) async {
    if (!foundation.kIsWeb) {
      try {
        final file = await _localRecipesFile(household);
        if (await file.exists()) await file.delete();
      } catch (_) {}
    }
  }

  Future<List<Category>?> readCategories(Household household) async {
    if (!foundation.kIsWeb) {
      try {
        final file = await _localCategoryFile(household);
        final String content = await file.readAsString();

        return List<Category>.from(
          json.decode(content).map((e) => Category.fromJson(e)),
        );
      } catch (_) {}
    }

    return null;
  }

  Future<void> writeCategories(
    Household household,
    List<Category> categories,
  ) async {
    if (!foundation.kIsWeb) {
      final file = await _localCategoryFile(household);
      await file.writeAsString(
        json.encode(categories.map((e) => e.toJsonWithId()).toList()),
      );
    }
  }

  Future<void> clearCategories(Household household) async {
    if (!foundation.kIsWeb) {
      try {
        final file = await _localCategoryFile(household);
        if (await file.exists()) await file.delete();
      } catch (_) {}
    }
  }

  Future<List<Household>?> readHouseholds() async {
    if (!foundation.kIsWeb) {
      try {
        final file = await _localHouseholdsFile;
        final String content = await file.readAsString();

        return List<Household>.from(
          json.decode(content).map((e) => Household.fromJson(e)),
        );
      } catch (_) {}
    }

    return null;
  }

  Future<void> writeHouseholds(List<Household> households) async {
    if (!foundation.kIsWeb) {
      final file = await _localHouseholdsFile;
      await file.writeAsString(
        json.encode(households.map((e) => e.toJsonWithId()).toList()),
      );
    }
  }

  Future<void> clearHouseholds() async {
    if (!foundation.kIsWeb) {
      try {
        final file = await _localHouseholdsFile;
        if (await file.exists()) await file.delete();
      } catch (_) {}
    }
  }
}
