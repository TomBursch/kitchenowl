import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/enums/expenselist_sorting.dart';
import 'package:kitchenowl/services/transaction_handler.dart';
import 'package:kitchenowl/services/transactions/expense.dart';

class ExpenseOverviewCubit extends Cubit<ExpenseOverviewState> {
  Future<void>? _refreshThread;

  ExpenseOverviewCubit(ExpenselistSorting initialSorting)
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
    final overview = await TransactionHandler.getInstance()
        .runTransaction(TransactionExpenseGetOverview(
      sorting: sorting,
      months: 5,
    ));
    if (overview.isEmpty) {
      _refreshThread = null;

      return;
    }

    emit(ExpenseOverviewLoaded(
      sorting: sorting,
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
  final Map<String, Map<String, double>> categoryOverviewsByCategory;

  const ExpenseOverviewLoaded({
    required this.categoryOverviewsByCategory,
    required ExpenselistSorting sorting,
  }) : super(sorting);

  double getTotalForMonth(int i) {
    return categoryOverviewsByCategory[i.toString()]
            ?.values
            .reduce((v, e) => v + e) ??
        0;
  }

  @override
  ExpenseOverviewState copyWith({
    ExpenselistSorting? sorting,
  }) =>
      ExpenseOverviewLoaded(
        sorting: sorting ?? this.sorting,
        categoryOverviewsByCategory: categoryOverviewsByCategory,
      );

  @override
  List<Object?> get props => [sorting, categoryOverviewsByCategory];
}
