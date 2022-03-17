import 'package:kitchenowl/models/expense.dart';
import 'package:kitchenowl/services/api/api_service.dart';
import 'package:kitchenowl/services/transaction.dart';

class TransactionExpenseGetAll extends Transaction<List<Expense>> {
  TransactionExpenseGetAll({DateTime? timestamp})
      : super.internal(timestamp ?? DateTime.now(), "TransactionExpenseGetAll");

  @override
  Future<List<Expense>> runLocal() async {
    return [];
  }

  @override
  Future<List<Expense>> runOnline() async {
    return await ApiService.getInstance().getAllExpenses() ?? [];
  }
}

class TransactionExpenseGet extends Transaction<Expense> {
  final Expense expense;

  TransactionExpenseGet({required this.expense, DateTime? timestamp})
      : super.internal(timestamp ?? DateTime.now(), "TransactionExpenseGet");

  @override
  Future<Expense> runLocal() async {
    return expense;
  }

  @override
  Future<Expense> runOnline() async {
    return await ApiService.getInstance().getExpense(expense) ?? expense;
  }
}

class TransactionExpenseAdd extends Transaction<bool> {
  final Expense expense;

  TransactionExpenseAdd({required this.expense, DateTime? timestamp})
      : super.internal(timestamp ?? DateTime.now(), "TransactionExpenseAdd");

  @override
  Future<bool> runLocal() async {
    return true;
  }

  @override
  Future<bool> runOnline() {
    return ApiService.getInstance().addExpense(expense);
  }
}

class TransactionExpenseRemove extends Transaction<bool> {
  final Expense expense;

  TransactionExpenseRemove({required this.expense, DateTime? timestamp})
      : super.internal(
          timestamp ?? DateTime.now(),
          "TransactionPlannerRemoveRecipe",
        );

  factory TransactionExpenseRemove.fromJson(
    Map<String, dynamic> map,
    DateTime timestamp,
  ) =>
      TransactionExpenseRemove(
        expense: Expense.fromJson(map['expense']),
        timestamp: timestamp,
      );

  @override
  bool get saveTransaction => true;

  @override
  Map<String, dynamic> toJson() => super.toJson()
    ..addAll({
      "expense": expense.toJsonWithId(),
    });

  @override
  Future<bool> runLocal() async {
    return true;
  }

  @override
  Future<bool> runOnline() {
    return ApiService.getInstance().deleteExpense(expense);
  }
}

class TransactionExpenseUpdate extends Transaction<bool> {
  final Expense expense;

  TransactionExpenseUpdate({required this.expense, DateTime? timestamp})
      : super.internal(timestamp ?? DateTime.now(), "TransactionExpenseUpdate");

  factory TransactionExpenseUpdate.fromJson(
    Map<String, dynamic> map,
    DateTime timestamp,
  ) =>
      TransactionExpenseUpdate(
        expense: Expense.fromJson(map['expense']),
        timestamp: timestamp,
      );

  @override
  bool get saveTransaction => true;

  @override
  Map<String, dynamic> toJson() => super.toJson()
    ..addAll({
      "expense": expense.toJsonWithId(),
    });

  @override
  Future<bool> runLocal() async {
    return true;
  }

  @override
  Future<bool> runOnline() {
    return ApiService.getInstance().updateExpense(expense);
  }
}
