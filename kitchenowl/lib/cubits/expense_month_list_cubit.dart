import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/enums/expenselist_sorting.dart';
import 'package:kitchenowl/models/expense.dart';
import 'package:kitchenowl/models/expense_category.dart';
import 'package:kitchenowl/models/household.dart';
import 'package:kitchenowl/services/transaction_handler.dart';
import 'package:kitchenowl/services/transactions/expense.dart';
import 'package:kitchenowl/services/transactions/household.dart';

class ExpenseMonthListCubit extends Cubit<ExpenseListCubitState> {
  final Household household;
  final List<ExpenseCategory?>? filter;
  final ExpenselistSorting sorting;
  final DateTime startAfter;
  final DateTime endBefore;

  ExpenseMonthListCubit(this.household, this.filter, this.sorting,
      this.startAfter, this.endBefore)
      : super(LoadingExpenseListCubitState(household)) {
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
      household: this.household,
      sorting: sorting,
      filter: filter,
      startAfter: startAfter,
      endBefore: endBefore,
    ));

    final household = TransactionHandler.getInstance().runTransaction(
      TransactionHouseholdGet(household: this.household),
      forceOffline: true,
    );

    emit(ExpenseListCubitState(
      household: (await household) ?? this.household,
      expenses: await expenses,
      allLoaded: (await expenses).length < 30,
    ));
  }
}

class ExpenseListCubitState extends Equatable {
  final Household household;
  final List<Expense> expenses;
  final bool allLoaded;

  const ExpenseListCubitState({
    required this.household,
    this.expenses = const [],
    this.allLoaded = false,
  });

  ExpenseListCubitState copyWith({
    Household? household,
    List<Expense>? expenses,
    bool? allLoaded,
  }) =>
      ExpenseListCubitState(
        household: household ?? this.household,
        expenses: expenses ?? this.expenses,
        allLoaded: allLoaded ?? this.allLoaded,
      );

  @override
  List<Object?> get props => expenses;
}

class LoadingExpenseListCubitState extends ExpenseListCubitState {
  const LoadingExpenseListCubitState(Household household)
      : super(household: household, allLoaded: true);

  @override
  ExpenseListCubitState copyWith({
    Household? household,
    List<Expense>? expenses,
    bool? allLoaded,
  }) =>
      LoadingExpenseListCubitState((household ?? this.household));
}
