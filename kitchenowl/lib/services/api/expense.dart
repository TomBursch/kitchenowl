import 'dart:convert';

import 'package:kitchenowl/enums/expenselist_sorting.dart';
import 'package:kitchenowl/enums/timeframe.dart';
import 'package:kitchenowl/models/expense.dart';
import 'package:kitchenowl/models/expense_category.dart';
import 'package:kitchenowl/models/household.dart';
import 'package:kitchenowl/models/expense_overview.dart';
import 'package:kitchenowl/services/api/api_service.dart';

extension ExpenseApi on ApiService {
  static const baseRoute = '/expense';

  Future<List<Expense>?> getAllExpenses({
    required Household household,
    ExpenselistSorting sorting = ExpenselistSorting.all,
    DateTime? startAfter,
    List<ExpenseCategory?>? filter,
    DateTime? endBefore,
    String search = "",
  }) async {
    String url = '${householdPath(household)}$baseRoute?view=${sorting.index}';
    if (startAfter != null) {
      url += '&startAfterDate=${startAfter.toUtc().millisecondsSinceEpoch}';
    }
    if (endBefore != null) {
      url += '&endBeforeDate=${endBefore.toUtc().millisecondsSinceEpoch}';
    }
    if (search.isNotEmpty) {
      url += '&search=${search}';
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

  Future<bool> mergeExpenseCategories(
    ExpenseCategory category,
    ExpenseCategory other,
  ) async {
    final res = await post(
      '$baseRoute/categories/${category.id}',
      jsonEncode({
        "merge_category_id": other.id,
      }),
    );

    return res.statusCode == 200;
  }

  Future<Map<int, ExpenseOverview>?> getExpenseOverview(
    Household household, [
    ExpenselistSorting sorting = ExpenselistSorting.all,
    Timeframe timeframe = Timeframe.monthly,
    int? steps,
    int? page,
  ]) async {
    String url =
        '${householdPath(household)}$baseRoute/overview?view=${sorting.index}&frame=${timeframe.index}';

    if (steps != null) {
      url += '&steps=$steps';
    }
    if (page != null) {
      url += '&page=$page';
    }

    final res = await get(url);
    if (res.statusCode != 200) return null;

    final body = jsonDecode(res.body);

    return Map.from(body).map(
      (key, value) =>
          MapEntry(int.parse(key), ExpenseOverview.fromJson(timeframe, value)),
    );
  }
}
