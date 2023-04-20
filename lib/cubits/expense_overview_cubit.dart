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
      : super(ExpenseOverviewLoading(initialSorting)) {
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

  const ExpenseOverviewState(this.sorting);

  ExpenseOverviewState copyWith({
    ExpenselistSorting? sorting,
  });
}

class ExpenseOverviewLoading extends ExpenseOverviewState {
  const ExpenseOverviewLoading(super.sorting);

  @override
  ExpenseOverviewState copyWith({
    ExpenselistSorting? sorting,
  }) =>
      ExpenseOverviewLoading(sorting ?? this.sorting);

  @override
  List<Object?> get props => [sorting];
}

class ExpenseOverviewLoaded extends ExpenseOverviewState {
  final List<ExpenseCategory> categories;
  final Map<int, Map<int, double>> categoryOverviewsByCategory;

  const ExpenseOverviewLoaded({
    required this.categories,
    required this.categoryOverviewsByCategory,
    required ExpenselistSorting sorting,
  }) : super(sorting);

  double getTotalForMonth(int i) {
    return categoryOverviewsByCategory[i]?.values.reduce((v, e) => v + e) ?? 0;
  }

  @override
  ExpenseOverviewState copyWith({
    ExpenselistSorting? sorting,
  }) =>
      ExpenseOverviewLoaded(
        sorting: sorting ?? this.sorting,
        categoryOverviewsByCategory: categoryOverviewsByCategory,
        categories: categories,
      );

  @override
  List<Object?> get props => [sorting, categories, categoryOverviewsByCategory];
}
