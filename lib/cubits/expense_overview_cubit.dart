import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/enums/expenselist_sorting.dart';
import 'package:kitchenowl/services/transaction_handler.dart';
import 'package:kitchenowl/services/transactions/expense.dart';

class ExpenseOverviewCubit extends Cubit<ExpenseOverviewState> {
  ExpenseOverviewCubit() : super(const ExpenseOverviewLoading()) {
    refresh();
  }

  Future<void> refresh() async {
    final overview = await TransactionHandler.getInstance()
        .runTransaction(TransactionExpenseGetOverview(
      sorting: ExpenselistSorting.all,
      months: 5,
    ));
    if (overview.isEmpty) return;

    emit(ExpenseOverviewLoaded(
      categoryOverviewsByCategory: overview,
    ));
  }
}

abstract class ExpenseOverviewState extends Equatable {
  const ExpenseOverviewState();
}

class ExpenseOverviewLoading extends ExpenseOverviewState {
  const ExpenseOverviewLoading();

  @override
  List<Object?> get props => [];
}

class ExpenseOverviewLoaded extends ExpenseOverviewState {
  final Map<String, Map<String, double>> categoryOverviewsByCategory;

  const ExpenseOverviewLoaded({
    required this.categoryOverviewsByCategory,
  });

  double getTotalForMonth(int i) {
    return categoryOverviewsByCategory[i.toString()]
            ?.values
            .reduce((v, e) => v + e) ??
        0;
  }

  @override
  List<Object?> get props => [categoryOverviewsByCategory];
}
