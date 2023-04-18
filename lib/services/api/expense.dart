import 'dart:convert';

import 'package:kitchenowl/enums/expenselist_sorting.dart';
import 'package:kitchenowl/models/expense.dart';
import 'package:kitchenowl/models/expense_category.dart';
import 'package:kitchenowl/models/household.dart';
import 'package:kitchenowl/services/api/api_service.dart';

extension ExpenseApi on ApiService {
  static const baseRoute = '/expense';

  Future<List<Expense>?> getAllExpenses({
    required Household household,
    ExpenselistSorting sorting = ExpenselistSorting.all,
    Expense? startAfter,
    List<ExpenseCategory?>? filter,
  }) async {
    String url = '${householdPath(household)}$baseRoute?view=${sorting.index}';
    if (startAfter != null) {
      url += '&startAfterId=${startAfter.id}';
    }
    if (filter != null && filter.isNotEmpty) {
      for (final c in filter) {
        url += '&filter=${c?.id ?? ""}';
      }
    }

    final res = await get(url);
    if (res.statusCode != 200) return null;

    final body = List.from(jsonDecode(res.body));

    return body.map((e) => Expense.fromJson(e)).toList();
  }

  Future<Expense?> getExpense(Expense expense) async {
    final res = await get('$baseRoute/${expense.id}');
    if (res.statusCode != 200) return null;

    return Expense.fromJson(jsonDecode(res.body));
  }

  Future<bool> addExpense(Household household, Expense expense) async {
    final body = expense.toJson();
    final res =
        await post("${householdPath(household)}$baseRoute", jsonEncode(body));

    return res.statusCode == 200;
  }

  Future<bool> deleteExpense(Expense expense) async {
    final res = await delete('$baseRoute/${expense.id}');

    return res.statusCode == 200;
  }

  Future<bool> updateExpense(Expense expense) async {
    final body = expense.toJson();
    final res = await post('$baseRoute/${expense.id}', jsonEncode(body));

    return res.statusCode == 200;
  }

  Future<List<ExpenseCategory>?> getExpenseCategories(
    Household household,
  ) async {
    final res = await get('${householdPath(household)}$baseRoute/categories');
    if (res.statusCode != 200) return null;

    final body = List.from(jsonDecode(res.body));

    return body.map((e) => ExpenseCategory.fromJson(e)).toList();
  }

  Future<bool> addExpenseCategory(
    Household household,
    ExpenseCategory category,
  ) async {
    final res = await post(
      '${householdPath(household)}$baseRoute/categories',
      jsonEncode(category.toJson()),
    );

    return res.statusCode == 200;
  }

  Future<bool> updateExpenseCategory(
    ExpenseCategory category,
  ) async {
    final res = await post(
      '$baseRoute/categories/${category.id}',
      jsonEncode(category.toJson()),
    );

    return res.statusCode == 200;
  }

  Future<bool> deleteExpenseCategory(ExpenseCategory category) async {
    final res = await delete('$baseRoute/categories/${category.id}');

    return res.statusCode == 200;
  }

  Future<Map<int, Map<int, double>>?> getExpenseOverview(
    Household household, [
    ExpenselistSorting sorting = ExpenselistSorting.all,
    int? months,
  ]) async {
    String url =
        '${householdPath(household)}$baseRoute/overview?view=${sorting.index}';

    if (months != null) {
      url += '&months=$months';
    }

    final res = await get(url);
    if (res.statusCode != 200) return null;

    final body = jsonDecode(res.body);

    return Map.from(body).map((key, value) => MapEntry(
          int.parse(key),
          Map.from(value).map((key, value) => MapEntry(int.parse(key), value)),
        ));
  }
}
