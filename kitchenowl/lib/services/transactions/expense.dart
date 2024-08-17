import 'package:kitchenowl/enums/expenselist_sorting.dart';
import 'package:kitchenowl/enums/timeframe.dart';
import 'package:kitchenowl/models/expense.dart';
import 'package:kitchenowl/models/expense_category.dart';
import 'package:kitchenowl/models/household.dart';
import 'package:kitchenowl/models/expense_overview.dart';
import 'package:kitchenowl/services/api/api_service.dart';
import 'package:kitchenowl/services/transaction.dart';

class TransactionExpenseGetAll extends Transaction<List<Expense>> {
  final ExpenselistSorting sorting;
  final Household household;
  final List<ExpenseCategory?>? filter;
  final DateTime? startAfter;
  final DateTime? endBefore;
  final String search;

  TransactionExpenseGetAll({
    DateTime? timestamp,
    required this.household,
    this.sorting = ExpenselistSorting.all,
    this.filter,
    this.startAfter,
    this.endBefore,
    this.search = "",
  }) : super.internal(timestamp ?? DateTime.now(), "TransactionExpenseGetAll");

  @override
  Future<List<Expense>> runLocal() async {
    return [];
  }

  @override
  Future<List<Expense>?> runOnline() async {
    return await ApiService.getInstance().getAllExpenses(
      household: household,
      sorting: sorting,
      filter: filter,
      startAfter: startAfter,
      endBefore: endBefore,
      search: search,
    );
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
  Future<Expense?> runOnline() async {
    return await ApiService.getInstance().getExpense(expense);
  }
}

class TransactionExpenseAdd extends Transaction<bool> {
  final Expense expense;
  final Household household;

  TransactionExpenseAdd({
    required this.household,
    required this.expense,
    DateTime? timestamp,
  }) : super.internal(timestamp ?? DateTime.now(), "TransactionExpenseAdd");

  @override
  Future<bool> runLocal() async {
    return true;
  }

  @override
  Future<bool> runOnline() {
    return ApiService.getInstance().addExpense(household, expense);
  }
}

class TransactionExpenseRemove extends Transaction<bool> {
  final Expense expense;

  TransactionExpenseRemove({required this.expense, DateTime? timestamp})
      : super.internal(
          timestamp ?? DateTime.now(),
          "TransactionExpenseRemove",
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
  Map<String, dynamic> toJson() => super.toJson()
    ..addAll({
      "expense": expense.toJsonWithId(),
    });

  @override
  Future<bool> runLocal() async {
    return true;
  }

  @override
  Future<bool?> runOnline() {
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
  Map<String, dynamic> toJson() => super.toJson()
    ..addAll({
      "expense": expense.toJsonWithId(),
    });

  @override
  Future<bool> runLocal() async {
    return true;
  }

  @override
  Future<bool?> runOnline() {
    return ApiService.getInstance().updateExpense(expense);
  }
}

class TransactionExpenseGetOverview
    extends Transaction<Map<int, ExpenseOverview>> {
  final Household household;
  final ExpenselistSorting sorting;
  final Timeframe timeframe;
  final int steps;
  final int page;

  TransactionExpenseGetOverview({
    DateTime? timestamp,
    required this.household,
    this.sorting = ExpenselistSorting.all,
    this.timeframe = Timeframe.monthly,
    this.steps = 1,
    this.page = 0,
  }) : super.internal(
          timestamp ?? DateTime.now(),
          "TransactionExpenseGetOverview",
        );

  @override
  Future<Map<int, ExpenseOverview>> runLocal() async {
    return {};
  }

  @override
  Future<Map<int, ExpenseOverview>?> runOnline() async {
    return await ApiService.getInstance()
        .getExpenseOverview(household, sorting, timeframe, steps, page);
  }
}

class TransactionExpenseCategoriesGet
    extends Transaction<List<ExpenseCategory>> {
  final Household household;

  TransactionExpenseCategoriesGet({
    DateTime? timestamp,
    required this.household,
  }) : super.internal(
          timestamp ?? DateTime.now(),
          "TransactionExpenseCategoriesGet",
        );

  @override
  Future<List<ExpenseCategory>> runLocal() async {
    return const [];
  }

  @override
  Future<List<ExpenseCategory>?> runOnline() async {
    return await ApiService.getInstance().getExpenseCategories(household);
  }
}
