import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/enums/expenselist_sorting.dart';
import 'package:kitchenowl/enums/timeframe.dart';
import 'package:kitchenowl/models/expense.dart';
import 'package:kitchenowl/models/expense_category.dart';
import 'package:kitchenowl/models/household.dart';
import 'package:kitchenowl/models/expense_overview.dart';
import 'package:kitchenowl/services/storage/storage.dart';
import 'package:kitchenowl/services/transaction_handler.dart';
import 'package:kitchenowl/services/transactions/expense.dart';

class ExpenseListCubit extends Cubit<ExpenseListCubitState> {
  final Household household;
  Future<void>? _refreshThread;

  ExpenseListCubit(this.household)
      : super(const LoadingExpenseListCubitState()) {
    PreferenceStorage.getInstance().readInt(key: 'expenseSorting').then((i) {
      if (i != null && state.sorting.index != i) {
        setSorting(
          ExpenselistSorting.values[i % ExpenselistSorting.values.length],
          false,
        );
      }
      refresh();
    });
  }

  Future<void> remove(Expense expense) async {
    await TransactionHandler.getInstance()
        .runTransaction(TransactionExpenseRemove(expense: expense));
    await refresh();
  }

  Future<void> add(Expense expense) async {
    await TransactionHandler.getInstance().runTransaction(TransactionExpenseAdd(
      household: household,
      expense: expense,
    ));
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

  void setTimeframe(Timeframe? timeframe) {
    emit(state.copyWith(timeframe: timeframe));
    refresh();
  }

  void setFilter(ExpenseCategory? category, bool selected) {
    final filter = List.of(state.filter);
    if (selected) {
      filter.add(category);
    } else {
      filter.removeWhere((e) => e?.id == category?.id);
    }
    emit(state.copyWith(filter: filter));
    refresh();
  }

  void clearFilter() {
    if (state.filter.isNotEmpty) {
      emit(state.copyWith(filter: const []));
      refresh();
    }
  }

  void setSearch(String search) {
    search = search.trim();
    if (search != state.search) {
      emit(state.copyWith(search: search));
      refresh();
    }
  }

  Future<void> loadMore() async {
    if (state.allLoaded) return;

    final moreExpenses = TransactionHandler.getInstance()
        .runTransaction(TransactionExpenseGetAll(
      household: household,
      sorting: state.sorting,
      startAfter: state.expenses.last.date,
      filter: state.filter,
      search: state.search,
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
    final timeframe = state.timeframe;
    final filter = state.filter;
    final search = state.search;
    final categories = TransactionHandler.getInstance()
        .runTransaction(TransactionExpenseCategoriesGet(household: household));
    final expenses = TransactionHandler.getInstance()
        .runTransaction(TransactionExpenseGetAll(
      household: household,
      sorting: sorting,
      filter: filter,
      search: search,
    ));

    Future<ExpenseOverview> monthOverview = TransactionHandler.getInstance()
        .runTransaction(TransactionExpenseGetOverview(
          household: household,
          sorting: state.sorting,
          timeframe: timeframe,
          steps: 1,
        ))
        .then<ExpenseOverview>((v) => v[0] ?? const ExpenseOverview());

    emit(ExpenseListCubitState(
      expenses: await expenses,
      sorting: sorting,
      categories: await categories,
      allLoaded: (await expenses).length < 30,
      expenseOverview: Map.from(state.expenseOverview)
        ..[sorting] = await monthOverview,
      timeframe: timeframe,
      filter: filter,
      search: search,
    ));
    _refreshThread = null;
  }
}

class ExpenseListCubitState extends Equatable {
  final List<Expense> expenses;
  final ExpenselistSorting sorting;
  final List<ExpenseCategory> categories;
  final Map<ExpenselistSorting, ExpenseOverview> expenseOverview;
  final bool allLoaded;
  final Timeframe timeframe;
  final List<ExpenseCategory?> filter;
  final String search;

  const ExpenseListCubitState({
    this.expenses = const [],
    this.sorting = ExpenselistSorting.all,
    this.allLoaded = false,
    this.categories = const [],
    required this.expenseOverview,
    this.timeframe = Timeframe.monthly,
    this.filter = const [],
    this.search = "",
  });

  ExpenseListCubitState copyWith({
    List<Expense>? expenses,
    ExpenselistSorting? sorting,
    bool? allLoaded,
    List<ExpenseCategory>? categories,
    Map<ExpenselistSorting, ExpenseOverview>? expenseOverview,
    Timeframe? timeframe,
    List<ExpenseCategory?>? filter,
    String? search,
  }) =>
      ExpenseListCubitState(
        expenses: expenses ?? this.expenses,
        sorting: sorting ?? this.sorting,
        allLoaded: allLoaded ?? this.allLoaded,
        categories: categories ?? this.categories,
        expenseOverview: expenseOverview ?? this.expenseOverview,
        timeframe: timeframe ?? this.timeframe,
        filter: filter ?? this.filter,
        search: search ?? this.search,
      );

  @override
  List<Object?> get props =>
      <Object>[sorting, expenseOverview, timeframe, filter, search] +
      categories +
      expenses;
}

class LoadingExpenseListCubitState extends ExpenseListCubitState {
  const LoadingExpenseListCubitState({
    super.sorting,
    super.timeframe,
    super.filter,
  }) : super(expenseOverview: const {
          ExpenselistSorting.all: ExpenseOverview(),
          ExpenselistSorting.personal: ExpenseOverview(),
        });

  @override
  ExpenseListCubitState copyWith({
    List<Expense>? expenses,
    ExpenselistSorting? sorting,
    bool? allLoaded,
    List<ExpenseCategory>? categories,
    Map<ExpenselistSorting, ExpenseOverview>? expenseOverview,
    Timeframe? timeframe,
    List<ExpenseCategory?>? filter,
    String? search,
  }) =>
      LoadingExpenseListCubitState(
        sorting: sorting ?? this.sorting,
        timeframe: timeframe ?? this.timeframe,
        filter: filter ?? this.filter,
      );
}
