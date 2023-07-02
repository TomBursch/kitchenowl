import 'dart:math';

import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/enums/expenselist_sorting.dart';
import 'package:kitchenowl/enums/timeframe.dart';
import 'package:kitchenowl/models/expense_category.dart';
import 'package:kitchenowl/models/household.dart';
import 'package:kitchenowl/models/member.dart';
import 'package:kitchenowl/services/transaction_handler.dart';
import 'package:kitchenowl/services/transactions/expense.dart';
import 'package:kitchenowl/services/transactions/household.dart';

class ExpenseOverviewCubit extends Cubit<ExpenseOverviewState> {
  final Household household;
  Future<void>? _refreshThread;

  ExpenseOverviewCubit(this.household, ExpenselistSorting initialSorting)
      : super(ExpenseOverviewLoading(sorting: initialSorting)) {
    refresh();
  }

  void incrementSorting() {
    setSorting(ExpenselistSorting
        .values[(state.sorting.index + 1) % ExpenselistSorting.values.length]);
  }

  void setSorting(ExpenselistSorting sorting) {
    emit(state.copyWith(sorting: sorting));
    refresh();
  }

  void setSelectedMonth(int month) {
    emit(state.copyWith(selectedMonthIndex: month));
  }

  Future<void> refresh() {
    _refreshThread ??= _refresh();

    return _refreshThread!;
  }

  Future<void> _refresh() async {
    final sorting = state.sorting;
    final fHousehold = TransactionHandler.getInstance()
        .runTransaction(TransactionHouseholdGet(household: household));
    final categories = TransactionHandler.getInstance()
        .runTransaction(TransactionExpenseCategoriesGet(household: household));
    final overview = await TransactionHandler.getInstance()
        .runTransaction(TransactionExpenseGetOverview(
      household: household,
      sorting: sorting,
      timeframe: Timeframe.monthly,
      steps: 5,
    ));
    if (overview.isEmpty) {
      _refreshThread = null;

      return;
    }

    emit(ExpenseOverviewLoaded(
      sorting: sorting,
      categories: await categories,
      categoryOverviewsByCategory: overview,
      household: (await fHousehold) ?? household,
      owes: _calculateOwes((await fHousehold) ?? household),
    ));

    _refreshThread = null;
  }

  List<(Member, Member, double)> _calculateOwes(Household household) {
    final members = household.member ?? [];
    final memberBalances =
        Map.fromEntries(members.map((e) => MapEntry(e, e.balance)));
    final List<(Member, Member, double)> result = [];
    for (final member in members) {
      while (memberBalances[member]! < 0) {
        final owes = members
            .firstWhereOrNull((e) => e.balance > 0 && memberBalances[e]! > 0);
        if (owes == null) break;
        final amount = min(-memberBalances[member]!, memberBalances[owes]!);
        memberBalances[member] = memberBalances[member]! + amount;
        memberBalances[owes] = memberBalances[owes]! - amount;
        result.add((member, owes, amount));
      }
    }

    return result;
  }
}

abstract class ExpenseOverviewState extends Equatable {
  final ExpenselistSorting sorting;
  final int selectedMonthIndex;

  const ExpenseOverviewState({
    required this.sorting,
    this.selectedMonthIndex = 0,
  });

  ExpenseOverviewState copyWith({
    ExpenselistSorting? sorting,
    int? selectedMonthIndex,
  });
}

class ExpenseOverviewLoading extends ExpenseOverviewState {
  const ExpenseOverviewLoading({
    required super.sorting,
    super.selectedMonthIndex,
  });

  @override
  ExpenseOverviewState copyWith({
    ExpenselistSorting? sorting,
    int? selectedMonthIndex,
  }) =>
      ExpenseOverviewLoading(
        sorting: sorting ?? this.sorting,
        selectedMonthIndex: selectedMonthIndex ?? this.selectedMonthIndex,
      );

  @override
  List<Object?> get props => [sorting, selectedMonthIndex];
}

class ExpenseOverviewLoaded extends ExpenseOverviewState {
  final List<ExpenseCategory> categories;
  final Map<int, Map<int, double>> categoryOverviewsByCategory;
  final Household household;
  final List<(Member, Member, double)> owes;

  const ExpenseOverviewLoaded({
    required this.categories,
    required this.categoryOverviewsByCategory,
    required super.sorting,
    required this.household,
    required this.owes,
    super.selectedMonthIndex = 0,
  });

  double getTotalForMonth(int i) {
    return categoryOverviewsByCategory[i]?.values.reduce((v, e) => v + e) ?? 0;
  }

  @override
  ExpenseOverviewState copyWith({
    ExpenselistSorting? sorting,
    int? selectedMonthIndex,
    Household? household,
    List<(Member, Member, double)>? owes,
  }) =>
      ExpenseOverviewLoaded(
        sorting: sorting ?? this.sorting,
        categoryOverviewsByCategory: categoryOverviewsByCategory,
        categories: categories,
        selectedMonthIndex: selectedMonthIndex ?? this.selectedMonthIndex,
        household: household ?? this.household,
        owes: owes ?? this.owes,
      );

  @override
  List<Object?> get props => [
        sorting,
        selectedMonthIndex,
        categories,
        categoryOverviewsByCategory,
        household,
        owes,
      ];
}
