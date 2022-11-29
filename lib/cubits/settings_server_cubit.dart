import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/models/category.dart';
import 'package:kitchenowl/models/expense_category.dart';
import 'package:kitchenowl/models/tag.dart';
import 'package:kitchenowl/models/user.dart';
import 'package:kitchenowl/services/api/api_service.dart';

class SettingsServerCubit extends Cubit<SettingsServerState> {
  SettingsServerCubit() : super(const LoadingSettingsServerState([], {})) {
    refresh();
  }

  Future<void> refresh() async {
    Future<List<User>?> users = ApiService.getInstance().getAllUsers();
    Future<Set<Tag>?> tags = ApiService.getInstance().getAllTags();
    Future<List<Category>?> categories =
        ApiService.getInstance().getCategories();
    Future<List<ExpenseCategory>?> expenseCategories =
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

  Future<bool> updateTag(Tag tag) async {
    final res = await ApiService.getInstance().updateTag(tag);
    refresh();

    return res;
  }

  Future<bool> deleteCategory(Category category) async {
    final res = await ApiService.getInstance().deleteCategory(category);
    refresh();

    return res;
  }

  Future<bool> addCategory(String name) async {
    final res =
        await ApiService.getInstance().addCategory(Category(name: name));
    refresh();

    return res;
  }

  Future<bool> updateCategory(Category category) async {
    final res = await ApiService.getInstance().updateCategory(category);
    refresh();

    return res;
  }

  Future<bool> reorderCategory(int oldIndex, int newIndex) async {
    final l = List<Category>.of(state.categories);
    final category = l.removeAt(oldIndex);
    l.insert(newIndex, category);
    emit(state.copyWith(categories: l));

    final res = await ApiService.getInstance()
        .updateCategory(category.copyWith(ordering: newIndex));

    refresh();

    return res;
  }

  Future<bool> deleteExpenseCategory(ExpenseCategory category) async {
    final res = await ApiService.getInstance().deleteExpenseCategory(category);
    refresh();

    return res;
  }

  Future<bool> addExpenseCategory(ExpenseCategory category) async {
    final res = await ApiService.getInstance().addExpenseCategory(category);
    refresh();

    return res;
  }

  Future<bool> updateExpenseCategory(ExpenseCategory category) async {
    final res = await ApiService.getInstance().updateExpenseCategory(category);
    refresh();

    return res;
  }
}

class SettingsServerState extends Equatable {
  final List<User> users;
  final Set<Tag> tags;
  final List<Category> categories;
  final List<ExpenseCategory> expenseCategories;

  const SettingsServerState(
    this.users,
    this.tags, [
    this.categories = const [],
    this.expenseCategories = const [],
  ]);

  SettingsServerState copyWith({
    List<User>? users,
    Set<Tag>? tags,
    List<Category>? categories,
    List<ExpenseCategory>? expenseCategories,
  }) =>
      SettingsServerState(
        users ?? this.users,
        tags ?? this.tags,
        categories ?? this.categories,
        expenseCategories ?? this.expenseCategories,
      );

  @override
  List<Object?> get props => [users, tags, categories, expenseCategories];
}

class LoadingSettingsServerState extends SettingsServerState {
  const LoadingSettingsServerState(super.users, super.tags);

  @override
  SettingsServerState copyWith({
    List<User>? users,
    Set<Tag>? tags,
    List<Category>? categories,
    List<ExpenseCategory>? expenseCategories,
  }) =>
      LoadingSettingsServerState(
        users ?? this.users,
        tags ?? this.tags,
      );
}
