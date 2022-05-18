import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/models/category.dart';
import 'package:kitchenowl/models/tag.dart';
import 'package:kitchenowl/models/user.dart';
import 'package:kitchenowl/services/api/api_service.dart';

class SettingsServerCubit extends Cubit<SettingsServerState> {
  SettingsServerCubit() : super(const SettingsServerState([], {})) {
    refresh();
  }

  Future<void> refresh() async {
    Future<List<User>?> users = ApiService.getInstance().getAllUsers();
    Future<Set<Tag>?> tags = ApiService.getInstance().getAllTags();
    Future<List<Category>?> categories =
        ApiService.getInstance().getCategories();
    Future<List<String>?> expenseCategories =
        ApiService.getInstance().getExpenseCategories();

    emit(SettingsServerState(
      await users ?? [],
      await tags ?? {},
      await categories ?? [],
      await expenseCategories ?? [],
    ));
  }

  Future<bool> createUser(String username, String name, String password) async {
    if (username.isNotEmpty && name.isNotEmpty && password.isNotEmpty) {
      final res =
          await ApiService.getInstance().createUser(username, name, password);
      refresh();

      return res;
    }

    return false;
  }

  Future<bool> deleteUser(User user) async {
    final res = await ApiService.getInstance().removeUser(user);
    refresh();

    return res;
  }

  Future<bool> addTag(String name) async {
    final res = await ApiService.getInstance().addTag(Tag(name: name));
    refresh();

    return res;
  }

  Future<bool> deleteTag(Tag tag) async {
    final res = await ApiService.getInstance().deleteTag(tag);
    refresh();

    return res;
  }

  Future<bool> deleteCategory(Category name) async {
    final res = await ApiService.getInstance().deleteCategory(name);
    refresh();

    return res;
  }

  Future<bool> addCategory(String name) async {
    final res =
        await ApiService.getInstance().addCategory(Category(name: name));
    refresh();

    return res;
  }

  Future<bool> deleteExpenseCategory(String name) async {
    final res = await ApiService.getInstance().deleteExpenseCategory(name);
    refresh();

    return res;
  }

  Future<bool> addExpenseCategory(String name) async {
    final res = await ApiService.getInstance().addExpenseCategory(name);
    refresh();

    return res;
  }
}

class SettingsServerState extends Equatable {
  final List<User> users;
  final Set<Tag> tags;
  final List<Category> categories;
  final List<String> expenseCategories;

  const SettingsServerState(
    this.users,
    this.tags, [
    this.categories = const [],
    this.expenseCategories = const [],
  ]);

  @override
  List<Object?> get props => [users, tags, categories, expenseCategories];
}
