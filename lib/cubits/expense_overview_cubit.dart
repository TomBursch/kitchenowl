import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/enums/expenselist_sorting.dart';
import 'package:kitchenowl/enums/timeframe.dart';
import 'package:kitchenowl/models/expense_category.dart';
import 'package:kitchenowl/models/household.dart';
import 'package:kitchenowl/services/transaction_handler.dart';
import 'package:kitchenowl/services/transactions/expense.dart';

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
    ));

    _refreshThread = null;
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

  const ExpenseOverviewLoaded({
    required this.categories,
    required this.categoryOverviewsByCategory,
    required super.sorting,
    super.selectedMonthIndex = 0,
  });

  double getTotalForMonth(int i) {
    return categoryOverviewsByCategory[i]?.values.reduce((v, e) => v + e) ?? 0;
  }

  @override
  ExpenseOverviewState copyWith({
    ExpenselistSorting? sorting,
    int? selectedMonthIndex,
  }) =>
      ExpenseOverviewLoaded(
        sorting: sorting ?? this.sorting,
        categoryOverviewsByCategory: categoryOverviewsByCategory,
        categories: categories,
        selectedMonthIndex: selectedMonthIndex ?? this.selectedMonthIndex,
      );

  @override
  List<Object?> get props =>
      [sorting, selectedMonthIndex, categories, categoryOverviewsByCategory];
}
