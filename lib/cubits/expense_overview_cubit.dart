import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/services/api/api_service.dart';
import 'package:kitchenowl/services/transaction_handler.dart';

class ExpenseOverviewCubit extends Cubit<ExpenseOverviewState> {
  ExpenseOverviewCubit() : super(const ExpenseOverviewLoading()) {
    refresh();
  }

  Future<void> refresh() async {
    // final expense = TransactionHandler.getInstance()
    //     .runTransaction(TransactionExpenseGet(expense: state.));

    final data = await ApiService.getInstance().getExpenseOverview();
    if (data == null) return;

    emit(ExpenseOverviewLoaded(
      categoryOverviewsByMonth: data,
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
  final Map<String, Map<String, double>> categoryOverviewsByMonth;

  const ExpenseOverviewLoaded({
    required this.categoryOverviewsByMonth,
  });

  double getTotalForMonth(int i) {
    return categoryOverviewsByMonth.entries
        .map((e) => e.value[i.toString()] ?? 0)
        .reduce((v, e) => v + e);
  }

  @override
  List<Object?> get props => [categoryOverviewsByMonth];
}
