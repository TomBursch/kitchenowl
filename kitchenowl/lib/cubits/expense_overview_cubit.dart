import 'dart:math';

import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/enums/expenselist_sorting.dart';
import 'package:kitchenowl/enums/timeframe.dart';
import 'package:kitchenowl/models/expense_category.dart';
import 'package:kitchenowl/models/household.dart';
import 'package:kitchenowl/models/member.dart';
import 'package:kitchenowl/models/expense_overview.dart';
import 'package:kitchenowl/services/transaction_handler.dart';
import 'package:kitchenowl/services/transactions/expense.dart';
import 'package:kitchenowl/services/transactions/household.dart';

class ExpenseOverviewCubit extends Cubit<ExpenseOverviewState> {
  final Household household;

  ExpenseOverviewCubit(this.household, ExpenselistSorting initialSorting)
      : super(ExpenseOverviewLoading(sorting: initialSorting)) {
    _load();
  }

  void incrementSorting() {
    setSorting(ExpenselistSorting
        .values[(state.sorting.index + 1) % ExpenselistSorting.values.length]);
  }

  void setSorting(ExpenselistSorting sorting) {
    emit(state.copyWith(sorting: sorting));
    _load();
  }

  void setSelectedMonth(int month) {
    emit(state.copyWith(selectedMonthIndex: month));
  }

  void pagePrev([int viewSize = 5]) {
    emit(state.copyWith(
      currentMonthOffset: state.currentMonthOffset + 1,
    ));
    _loadMore(viewSize);
  }

  void pageNext() {
    if (state.currentMonthOffset > 0) {
      emit(state.copyWith(
        currentMonthOffset: state.currentMonthOffset - 1,
      ));
    }
  }

  Future<void> _loadMore(int viewSize) async {
    if (state is! ExpenseOverviewLoaded ||
        state.currentMonthOffset <
            (state as ExpenseOverviewLoaded).monthOverview.length - viewSize) {
      return;
    }

    final overview = await TransactionHandler.getInstance()
        .runTransaction(TransactionExpenseGetOverview(
      household: household,
      sorting: state.sorting,
      timeframe: Timeframe.monthly,
      steps: viewSize,
      page: (state.currentMonthOffset / viewSize).floor() + 1,
    ));
    emit((state as ExpenseOverviewLoaded).copyWith(
      monthOverview: Map.from((state as ExpenseOverviewLoaded).monthOverview)
        ..addAll(overview),
    ));
  }

  Future<void> refresh() async {
    return _load();
  }

  Future<void> _load() async {
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
      steps: 11,
      page: 0,
    ));

    emit(ExpenseOverviewLoaded(
      sorting: sorting,
      categories: await categories,
      monthOverview: overview,
      household: (await fHousehold) ?? household,
      owes: _calculateOwes((await fHousehold) ?? household),
    ));
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
  final int currentMonthOffset;

  const ExpenseOverviewState({
    required this.sorting,
    this.selectedMonthIndex = 0,
    this.currentMonthOffset = 0,
  });

  ExpenseOverviewState copyWith({
    ExpenselistSorting? sorting,
    int? selectedMonthIndex,
    int? currentMonthOffset,
  });
}

class ExpenseOverviewLoading extends ExpenseOverviewState {
  const ExpenseOverviewLoading({
    required super.sorting,
    super.selectedMonthIndex,
    super.currentMonthOffset,
  });

  @override
  ExpenseOverviewState copyWith({
    ExpenselistSorting? sorting,
    int? selectedMonthIndex,
    int? currentMonthOffset,
  }) =>
      ExpenseOverviewLoading(
        sorting: sorting ?? this.sorting,
        selectedMonthIndex: selectedMonthIndex ?? this.selectedMonthIndex,
        currentMonthOffset: currentMonthOffset ?? this.currentMonthOffset,
      );

  @override
  List<Object?> get props => [sorting, selectedMonthIndex, currentMonthOffset];
}

class ExpenseOverviewLoaded extends ExpenseOverviewState {
  final List<ExpenseCategory> categories;
  final Map<int, ExpenseOverview> monthOverview;
  final Household household;
  final List<(Member, Member, double)> owes;

  const ExpenseOverviewLoaded({
    required this.categories,
    required this.monthOverview,
    required super.sorting,
    required this.household,
    required this.owes,
    super.selectedMonthIndex = 0,
    super.currentMonthOffset,
  });

  double getTotalForMonth(int i) {
    return monthOverview[i]?.getTotalForPeriod() ?? 0;
  }

  double getExpenseTotalForMonth(int i) {
    return monthOverview[i]?.getExpenseTotalForPeriod() ?? 0;
  }

  double getIncomeTotalForMonth(int i) {
    return monthOverview[i]?.getIncomeTotalForPeriod() ?? 0;
  }

  double getTransactionAmountPercentage(double amount) {
    final total = amount > 0 
        ? getExpenseTotalForMonth(selectedMonthIndex) 
        : getIncomeTotalForMonth(selectedMonthIndex);
    return total != 0 ? amount / total : -1;
  }

  double getAverageForLastMonths(int n) =>
      monthOverview.values
          .skip(1)
          .take(n)
          .fold(0.0, (value, e) => value + e.getTotalForPeriod()) /
      monthOverview.values
          .skip(1)
          .take(n)
          .where((e) => e.getTotalForPeriod() != 0)
          .length;

  bool trendUp(double total, double average) {
    if (!average.isFinite) return true;
    if (selectedMonthIndex == 0) {
      return total > DateTime.now().day * average / 30;
    } else {
      return total > average;
    }
  }

  @override
  ExpenseOverviewState copyWith({
    ExpenselistSorting? sorting,
    int? selectedMonthIndex,
    Household? household,
    List<(Member, Member, double)>? owes,
    Map<int, ExpenseOverview>? monthOverview,
    int? currentMonthOffset,
  }) =>
      ExpenseOverviewLoaded(
        sorting: sorting ?? this.sorting,
        monthOverview: monthOverview ?? this.monthOverview,
        categories: categories,
        selectedMonthIndex: selectedMonthIndex ?? this.selectedMonthIndex,
        household: household ?? this.household,
        owes: owes ?? this.owes,
        currentMonthOffset: currentMonthOffset ?? this.currentMonthOffset,
      );

  @override
  List<Object?> get props => [
        sorting,
        selectedMonthIndex,
        categories,
        monthOverview,
        household,
        owes,
        currentMonthOffset,
      ];
}
