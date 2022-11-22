import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/enums/expenselist_sorting.dart';
import 'package:kitchenowl/models/expense.dart';
import 'package:kitchenowl/models/user.dart';
import 'package:kitchenowl/services/storage/storage.dart';
import 'package:kitchenowl/services/transaction_handler.dart';
import 'package:kitchenowl/services/transactions/expense.dart';
import 'package:kitchenowl/services/transactions/user.dart';

class ExpenseListCubit extends Cubit<ExpenseListCubitState> {
  Future<void>? _refreshThread;

  ExpenseListCubit() : super(const LoadingExpenseListCubitState()) {
    PreferenceStorage.getInstance().readInt(key: 'expenseSorting').then((i) {
      if (i != null && state.sorting.index != i) {
        setSorting(
          ExpenselistSorting.values[i % ExpenselistSorting.values.length],
          false,
        );
      }
    });
    refresh();
  }

  Future<void> remove(Expense expense) async {
    await TransactionHandler.getInstance()
        .runTransaction(TransactionExpenseRemove(expense: expense));
    await refresh();
  }

  Future<void> add(Expense expense) async {
    await TransactionHandler.getInstance()
        .runTransaction(TransactionExpenseAdd(expense: expense));
    await refresh();
  }

  Future<void> update(Expense expense) async {
    await TransactionHandler.getInstance()
        .runTransaction(TransactionExpenseUpdate(expense: expense));
    await refresh();
  }

  void incrementSorting() {
    setSorting(ExpenselistSorting
        .values[(state.sorting.index + 1) % ExpenselistSorting.values.length]);
  }

  void setSorting(ExpenselistSorting sorting, [bool savePreference = true]) {
    if (savePreference) {
      PreferenceStorage.getInstance()
          .writeInt(key: 'expenseSorting', value: sorting.index);
    }
    emit(state.copyWith(sorting: sorting));
    refresh();
  }

  Future<void> loadMore() async {
    if (state.allLoaded) return;

    final moreExpenses = TransactionHandler.getInstance()
        .runTransaction(TransactionExpenseGetMore(
      sorting: state.sorting,
      lastExpense: state.expenses.last,
    ));
    emit(state.copyWith(
      expenses: List.from(state.expenses + await moreExpenses),
      allLoaded: (await moreExpenses).length < 30,
    ));
  }

  Future<void> refresh() {
    _refreshThread ??= _refresh();

    return _refreshThread!;
  }

  Future<void> _refresh() async {
    final sorting = state.sorting;
    final users = TransactionHandler.getInstance()
        .runTransaction(TransactionUserGetAll());
    final expenses = TransactionHandler.getInstance()
        .runTransaction(TransactionExpenseGetAll(sorting: sorting));

    Future<Map<String, double>>? categoryOverview;
    if (state.sorting == ExpenselistSorting.personal) {
      categoryOverview = TransactionHandler.getInstance()
          .runTransaction(TransactionExpenseGetOverview(
            sorting: state.sorting,
            months: 1,
          ))
          .then<Map<String, double>>((v) => v['0'] ?? const {});
    }

    emit(ExpenseListCubitState(
      users: await users,
      expenses: await expenses,
      sorting: sorting,
      categoryOverview: await categoryOverview ?? state.categoryOverview,
    ));
    _refreshThread = null;
  }
}

class ExpenseListCubitState extends Equatable {
  final List<User> users;
  final List<Expense> expenses;
  final ExpenselistSorting sorting;
  final Map<String, double> categoryOverview;
  final bool allLoaded;

  const ExpenseListCubitState({
    this.users = const [],
    this.expenses = const [],
    this.sorting = ExpenselistSorting.all,
    this.allLoaded = false,
    this.categoryOverview = const {},
  });

  ExpenseListCubitState copyWith({
    List<User>? users,
    List<Expense>? expenses,
    ExpenselistSorting? sorting,
    bool? allLoaded,
    Map<String, double>? categoryOverview,
  }) =>
      ExpenseListCubitState(
        users: users ?? this.users,
        expenses: expenses ?? this.expenses,
        sorting: sorting ?? this.sorting,
        allLoaded: allLoaded ?? this.allLoaded,
        categoryOverview: categoryOverview ?? this.categoryOverview,
      );

  @override
  List<Object?> get props =>
      <Object>[sorting, categoryOverview] + users + expenses;
}

class LoadingExpenseListCubitState extends ExpenseListCubitState {
  const LoadingExpenseListCubitState({super.sorting});

  @override
  // ignore: long-parameter-list
  ExpenseListCubitState copyWith({
    List<User>? users,
    List<Expense>? expenses,
    ExpenselistSorting? sorting,
    bool? allLoaded,
    Map<String, double>? categoryOverview,
  }) =>
      LoadingExpenseListCubitState(
        sorting: sorting ?? this.sorting,
      );
}
