import 'package:kitchenowl/models/category.dart';
import 'package:kitchenowl/models/household.dart';
import 'package:kitchenowl/models/item.dart';
import 'package:kitchenowl/models/recipe.dart';
import 'package:kitchenowl/models/shoppinglist.dart';
import 'package:kitchenowl/models/tag.dart';
import 'package:kitchenowl/models/user.dart';
import 'package:kitchenowl/services/storage/temp_storage.dart';

/// An in memory storage for cached households.
/// Optionally, can write and read (on initial load) the data from a persistent storage.
class MemStorage {
  static MemStorage? _instance;
  final TempStorage? persistentStorage;

  MemStorage._internal(this.persistentStorage);
  static MemStorage getInstance() {
    _instance ??= MemStorage._internal(TempStorage.getInstance());

    return _instance!;
  }

  Future<void> clearAll() async {
    persistentStorage?.clearAll();
    await readHouseholds().then(
      (value) => Future.wait(
        value?.map((household) async {
              await readShoppingLists(household).then((value) =>
                  value?.map((shoppingList) => clearItems(shoppingList)));

              await Future.wait([
                clearShoppingLists(household),
                clearRecipes(household),
                clearCategories(household),
                clearTags(household),
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

  User? _user;

  Future<User?> readUser() async {
    if (persistentStorage != null && _user == null) {
      _user = await persistentStorage!.readUser();
    }
    return _user;
  }

  Future<void> clearUser() async {
    _user = null;
  }

  Future<void> writeUser(User user) async {
    persistentStorage?.writeUser(user);
    _user = user;
  }

  Map<int, List<ShoppingList>?> _shoppinglists = {};

  Future<List<ShoppingList>?> readShoppingLists(Household household) async {
    if (persistentStorage != null && _shoppinglists[household.id] == null) {
      _shoppinglists[household.id] =
          await persistentStorage!.readShoppingLists(household);
    }
    if (_shoppinglists[household.id] == null) return null;
    return List.of(_shoppinglists[household.id]!);
  }

  Future<void> clearShoppingLists(Household household) async {
    _shoppinglists = {};
  }

  Future<void> writeShoppingLists(
    Household household,
    List<ShoppingList> shoppingLists,
  ) async {
    persistentStorage?.writeShoppingLists(household, shoppingLists);
    _shoppinglists[household.id] = shoppingLists;
  }

  Map<int?, List<ShoppinglistItem>?> _shoppinglistItems = {};

  Future<List<ShoppinglistItem>?> readItems(ShoppingList shoppingList) async {
    if (persistentStorage != null &&
        _shoppinglistItems[shoppingList.id] == null) {
      _shoppinglistItems[shoppingList.id] =
          await persistentStorage!.readItems(shoppingList);
    }
    if (_shoppinglistItems[shoppingList.id] == null) return null;
    return List.of(_shoppinglistItems[shoppingList.id]!);
  }

  Future<void> writeItems(
    ShoppingList shoppinglist,
    List<ShoppinglistItem> items,
  ) async {
    persistentStorage?.writeItems(shoppinglist, items);
    _shoppinglistItems[shoppinglist.id] = items;
  }

  Future<void> clearItems(ShoppingList shoppinglist) async {
    _shoppinglistItems = {};
  }

  Map<int, List<Recipe>?> _recipes = {};

  Future<List<Recipe>?> readRecipes(Household household) async {
    if (persistentStorage != null && _recipes[household.id] == null) {
      _recipes[household.id] = await persistentStorage!.readRecipes(household);
    }
    if (_recipes[household.id] == null) return null;
    return List.of(_recipes[household.id]!);
  }

  Future<void> writeRecipes(Household household, List<Recipe> recipes) async {
    persistentStorage?.writeRecipes(household, recipes);
    _recipes[household.id] = recipes;
  }

  Future<void> clearRecipes(Household household) async {
    _recipes = {};
  }

  Map<int, List<Category>?> _categories = {};

  Future<List<Category>?> readCategories(Household household) async {
    if (persistentStorage != null && _categories[household.id] == null) {
      _categories[household.id] =
          await persistentStorage!.readCategories(household);
    }
    if (_categories[household.id] == null) return null;
    return List.of(_categories[household.id]!);
  }

  Future<void> writeCategories(
    Household household,
    List<Category> categories,
  ) async {
    persistentStorage?.writeCategories(household, categories);
    _categories[household.id] = categories;
  }

  Future<void> clearCategories(Household household) async {
    _categories = {};
  }

  Map<int, Set<Tag>?> _tags = {};

  Future<Set<Tag>?> readTags(Household household) async {
    if (persistentStorage != null && _tags[household.id] == null) {
      _tags[household.id] = await persistentStorage!.readTags(household);
    }
    if (_tags[household.id] == null) return null;
    return Set.of(_tags[household.id]!);
  }

  Future<void> writeTags(
    Household household,
    Set<Tag> tags,
  ) async {
    persistentStorage?.writeTags(household, tags);
    _tags[household.id] = tags;
  }

  Future<void> clearTags(Household household) async {
    _tags = {};
  }

  List<Household>? _households;

  Future<List<Household>?> readHouseholds() async {
    if (persistentStorage != null && _households == null) {
      _households = await persistentStorage!.readHouseholds();
    }
    if (_households == null) return null;
    return List.of(_households!);
  }

  Future<void> writeHouseholds(List<Household> households) async {
    persistentStorage?.writeHouseholds(households);
    _households = households;
  }

  Future<void> clearHouseholds() async {
    _households = null;
  }
}
