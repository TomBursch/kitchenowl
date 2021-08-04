import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:kitchenowl/models/item.dart';
import 'package:kitchenowl/models/recipe.dart';
import 'package:kitchenowl/models/user.dart';
import 'package:path_provider/path_provider.dart';

class TempStorage {
  static TempStorage _instance;

  TempStorage._internal();
  static TempStorage getInstance() {
    if (_instance == null) _instance = TempStorage._internal();
    return _instance;
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

  Future<File> get _localItemFile async {
    final path = await _localPath;
    return File('$path/items.json');
  }

  Future<File> get _localRecipeFile async {
    final path = await _localPath;
    return File('$path/recipes.json');
  }

  Future<void> clearAll() async {
    await this.clearItems();
    await this.clearUser();
    await this.clearRecipes();
  }

  Future<User> readUser() async {
    if (!kIsWeb)
      try {
        final file = await _localUserFile;
        final String content = await file.readAsString();
        return User.fromJson(json.decode(content));
      } catch (e) {}
    return null;
  }

  Future<File> clearUser() async {
    if (!kIsWeb)
      try {
        final file = await _localUserFile;
        if (await file.exists()) return file.delete();
      } catch (e) {}
    return null;
  }

  Future<File> writeUser(User user) async {
    if (!kIsWeb) {
      final file = await _localUserFile;
      return file.writeAsString(json.encode(user.toJsonWithId()));
    }
    return null;
  }

  Future<List<ShoppinglistItem>> readItems() async {
    if (!kIsWeb)
      try {
        final file = await _localItemFile;
        final String content = await file.readAsString();
        return List<ShoppinglistItem>.from(
            json.decode(content).map((e) => ShoppinglistItem.fromJson(e)));
      } catch (e) {}
    return null;
  }

  Future<File> writeItems(List<ShoppinglistItem> items) async {
    if (!kIsWeb) {
      final file = await _localItemFile;
      return file.writeAsString(
          json.encode(items.map((e) => e.toJsonWithId()).toList()));
    }
    return null;
  }

  Future<File> clearItems() async {
    if (!kIsWeb)
      try {
        final file = await _localItemFile;
        if (await file.exists()) return file.delete();
      } catch (e) {}
    return null;
  }

  Future<List<Recipe>> readRecipes() async {
    if (!kIsWeb)
      try {
        final file = await _localRecipeFile;
        final String content = await file.readAsString();
        return List<Recipe>.from(
            json.decode(content).map((e) => Recipe.fromJson(e)));
      } catch (e) {}
    return null;
  }

  Future<File> writeRecipes(List<Recipe> recipes) async {
    if (!kIsWeb) {
      final file = await _localRecipeFile;
      return file.writeAsString(
          json.encode(recipes.map((e) => e.toJsonWithId()).toList()));
    }
    return null;
  }

  Future<File> clearRecipes() async {
    if (!kIsWeb)
      try {
        final file = await _localRecipeFile;
        if (await file.exists()) return file.delete();
      } catch (e) {}
    return null;
  }
}
