import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/enums/expenselist_sorting.dart';
import 'package:kitchenowl/models/expense.dart';
import 'package:kitchenowl/models/expense_category.dart';
import 'package:kitchenowl/models/household.dart';
import 'package:kitchenowl/services/transaction_handler.dart';
import 'package:kitchenowl/services/transactions/expense.dart';

class ExpenseMonthListCubit extends Cubit<ExpenseListCubitState> {
  final Household household;
  final List<ExpenseCategory?>? filter;
  final ExpenselistSorting sorting;
  final DateTime startAfter;
  final DateTime endBefore;

  ExpenseMonthListCubit(this.household, this.filter, this.sorting,
      this.startAfter, this.endBefore)
      : super(const LoadingExpenseListCubitState()) {
    refresh();
  }

  Future<void> loadMore() async {
    if (state.allLoaded) return;

    final moreExpenses = TransactionHandler.getInstance()
        .runTransaction(TransactionExpenseGetAll(
      household: household,
      startAfter: state.expenses.last.date,
      endBefore: endBefore,
    ));
    emit(state.copyWith(
      expenses: List.from(state.expenses + await moreExpenses),
      allLoaded: (await moreExpenses).length < 30,
    ));
  }

  Future<void> refresh() async {
    final expenses = TransactionHandler.getInstance()
        .runTransaction(TransactionExpenseGetAll(
      household: household,
      sorting: sorting,
      filter: filter,
      startAfter: startAfter,
      endBefore: endBefore,
    ));

    emit(ExpenseListCubitState(
      expenses: await expenses,
      allLoaded: (await expenses).length < 30,
    ));
  }
}

class ExpenseListCubitState extends Equatable {
  final List<Expense> expenses;
  final bool allLoaded;

  const ExpenseListCubitState({
    this.expenses = const [],
    this.allLoaded = false,
  });

  ExpenseListCubitState copyWith({
    List<Expense>? expenses,
    bool? allLoaded,
  }) =>
      ExpenseListCubitState(
        expenses: expenses ?? this.expenses,
        allLoaded: allLoaded ?? this.allLoaded,
      );

  @override
  List<Object?> get props => expenses;
}

class LoadingExpenseListCubitState extends ExpenseListCubitState {
  const LoadingExpenseListCubitState() : super(allLoaded: true);

  @override
  ExpenseListCubitState copyWith({
    List<Expense>? expenses,
    bool? allLoaded,
  }) =>
      const LoadingExpenseListCubitState();
}
