import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:kitchenowl/models/item.dart';
import 'package:kitchenowl/models/recipe.dart';
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
    final directory = Directory(temp.path + '/kitchenowl');
    if (!await directory.exists()) directory.create();

    return directory.path;
  }

  Future<File> get _localUserFile async {
    final path = await _localPath;

    return File('$path/user.json');
  }

  Future<File> get _localUsersFile async {
    final path = await _localPath;

    return File('$path/users.json');
  }

  Future<File> get _localItemFile async {
    final path = await _localPath;

    return File('$path/items.json');
  }

  Future<File> get _localRecipeFile async {
    final path = await _localPath;

    return File('$path/recipes.json');
  }

  Future<void> clearAll() async {
    await clearItems();
    await clearUser();
    await clearUsers();
    await clearRecipes();
  }

  Future<User?> readUser() async {
    if (!kIsWeb) {
      try {
        final file = await _localUserFile;
        final String content = await file.readAsString();

        return User.fromJson(json.decode(content));
      } catch (_) {}
    }

    return null;
  }

  Future<void> clearUser() async {
    if (!kIsWeb) {
      try {
        final file = await _localUserFile;
        if (await file.exists()) await file.delete();
      } catch (_) {}
    }
  }

  Future<void> writeUser(User user) async {
    if (!kIsWeb) {
      final file = await _localUserFile;
      await file.writeAsString(json.encode(user.toJsonWithId()));
    }
  }

  Future<List<User>?> readUsers() async {
    if (!kIsWeb) {
      try {
        final file = await _localUsersFile;
        final String content = await file.readAsString();
        List list = json.decode(content);

        return list.map((e) => User.fromJson(e)).toList();
      } catch (_) {}
    }

    return null;
  }

  Future<void> clearUsers() async {
    if (!kIsWeb) {
      try {
        final file = await _localUsersFile;
        if (await file.exists()) await file.delete();
      } catch (_) {}
    }
  }

  Future<void> writeUsers(List<User> users) async {
    if (!kIsWeb) {
      final file = await _localUsersFile;
      await file.writeAsString(
        json.encode(users.map((e) => e.toJsonWithId()).toList()),
      );
    }
  }

  Future<List<ShoppinglistItem>?> readItems() async {
    if (!kIsWeb) {
      try {
        final file = await _localItemFile;
        final String content = await file.readAsString();

        return List<ShoppinglistItem>.from(
          json.decode(content).map((e) => ShoppinglistItem.fromJson(e)),
        );
      } catch (_) {}
    }

    return null;
  }

  Future<void> writeItems(List<ShoppinglistItem> items) async {
    if (!kIsWeb) {
      final file = await _localItemFile;
      await file.writeAsString(
        json.encode(items.map((e) => e.toJsonWithId()).toList()),
      );
    }
  }

  Future<void> clearItems() async {
    if (!kIsWeb) {
      try {
        final file = await _localItemFile;
        if (await file.exists()) await file.delete();
      } catch (_) {}
    }
  }

  Future<List<Recipe>?> readRecipes() async {
    if (!kIsWeb) {
      try {
        final file = await _localRecipeFile;
        final String content = await file.readAsString();

        return List<Recipe>.from(
          json.decode(content).map((e) => Recipe.fromJson(e)),
        );
      } catch (_) {}
    }

    return null;
  }

  Future<void> writeRecipes(List<Recipe> recipes) async {
    if (!kIsWeb) {
      final file = await _localRecipeFile;
      await file.writeAsString(
        json.encode(recipes.map((e) => e.toJsonWithId()).toList()),
      );
    }
  }

  Future<void> clearRecipes() async {
    if (!kIsWeb) {
      try {
        final file = await _localRecipeFile;
        if (await file.exists()) await file.delete();
      } catch (_) {}
    }
  }
}
