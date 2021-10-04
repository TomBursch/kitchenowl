import 'dart:convert';

import 'package:kitchenowl/models/expense.dart';
import 'package:kitchenowl/services/api/api_service.dart';

extension ExpenseApi on ApiService {
  Future<List<Expense>> getAllExpenses() async {
    final res = await get('/expense');
    if (res.statusCode != 200) return [];

    final body = List.from(jsonDecode(res.body));
    return body.map((e) => Expense.fromJson(e)).toList();
  }

  Future<Expense> getExpense(Expense expense) async {
    final res = await get('/expense/${expense.id}');
    if (res.statusCode != 200) return null;

    return Expense.fromJson(jsonDecode(res.body));
  }

  Future<bool> addExpense(Expense expense) async {
    final body = expense.toJson();
    final res = await post('/expense', jsonEncode(body));
    return res.statusCode == 200;
  }

  Future<bool> deleteExpense(Expense expense) async {
    final res = await delete('/expense/${expense.id}');
    return res.statusCode == 200;
  }

  Future<bool> updateExpense(Expense expense) async {
    final body = expense.toJson();
    final res = await post('/expense/${expense.id}', jsonEncode(body));
    return res.statusCode == 200;
  }
}
