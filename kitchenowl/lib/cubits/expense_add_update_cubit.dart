import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/helpers/named_bytearray.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/models/expense.dart';
import 'package:kitchenowl/models/expense_category.dart';
import 'package:kitchenowl/models/household.dart';
import 'package:kitchenowl/models/user.dart';
import 'package:kitchenowl/services/api/api_service.dart';

class AddUpdateExpenseCubit extends Cubit<AddUpdateExpenseState> {
  final Household household;

  final Expense expense;
  AddUpdateExpenseCubit(
    this.household, [
    this.expense = const Expense(paidById: 0),
  ]) : super(AddUpdateExpenseState(
          amount: expense.amount.abs(),
          description: expense.description ?? "",
          date: expense.date ?? DateTime.now(),
          isIncome: expense.amount < 0,
          name: expense.name,
          paidBy: expense.paidById,
          paidFor: expense.paidFor,
          excludeFromStatistics: expense.excludeFromStatistics,
          category: expense.category,
          categories: expense.category == null ? const [] : [expense.category!],
        )) {
    _getCategories();
  }

  Future<void> saveExpense() async {
    final _state = state;
    if (_state.isValid()) {
      final amount = _state.amount * (_state.isIncome ? -1 : 1);
      String? image;
      if (_state.image != null) {
        image = _state.image!.isEmpty
            ? ''
            : await ApiService.getInstance().uploadBytes(_state.image!);
      }
      if (expense.id == null) {
        await ApiService.getInstance().addExpense(
          household,
          Expense(
            amount: amount,
            name: _state.name,
            description: _state.description,
            date: _state.date,
            image: image ?? expense.image,
            excludeFromStatistics: _state.excludeFromStatistics,
            paidById: _state.paidBy,
            paidFor: _state.paidFor,
            category: _state.category,
          ),
        );
      } else {
        await ApiService.getInstance().updateExpense(expense.copyWith(
          name: _state.name,
          description: _state.description,
          amount: amount,
          date: _state.date,
          image: image,
          excludeFromStatistics: _state.excludeFromStatistics,
          paidById: _state.paidBy,
          paidFor: _state.paidFor,
          category: Nullable(_state.category),
        ));
      }
    }
  }

  Future<bool> deleteExpense() async {
    if (expense.id != null) {
      return ApiService.getInstance().deleteExpense(expense);
    }

    return false;
  }

  void setName(String name) {
    emit(state.copyWith(name: name));
  }

  void setDescription(String description) {
    emit(state.copyWith(description: description));
  }

  void setDate(DateTime date) {
    emit(state.copyWith(date: date));
  }

  void setAmount(double amount) {
    emit(state.copyWith(amount: amount));
  }

  void setIncome(bool isIncome) {
    emit(state.copyWith(isIncome: isIncome));
  }

  void setImage(NamedByteArray image) {
    emit(state.copyWith(image: image));
  }

  void setPaidBy(User user) {
    emit(state.copyWith(paidBy: user.id));
  }

  void setPaidById(int userId) {
    emit(state.copyWith(paidBy: userId));
  }

  void setCategory(ExpenseCategory? category) {
    List<ExpenseCategory>? categories;
    if (category != null && !state.categories.contains(category)) {
      categories = List.of(state.categories)..add(category);
    }
    emit(state.copyWithCategory(
      category: category,
      categories: categories,
    ));
  }

  void setExcludeFromStatistics(bool? value) {
    emit(state.copyWith(excludeFromStatistics: value));
  }

  void addUser(User user, [int factor = 1]) {
    if (!containsUser(user)) {
      emit(state.copyWith(
        paidFor: List.from(state.paidFor)
          ..add(PaidForModel(
            userId: user.id,
            factor: factor,
          )),
      ));
    }
  }

  bool containsUser(User user) {
    return state.paidFor.map((e) => e.userId).contains(user.id);
  }

  void removeUser(User user) {
    final l = List<PaidForModel>.from(state.paidFor);
    l.removeWhere((e) => e.userId == user.id);
    emit(state.copyWith(paidFor: l));
  }

  void setFactor(User user, int? factor) {
    if (factor == null || factor <= 0) return removeUser(user);

    final l = List<PaidForModel>.from(state.paidFor);
    final i = l.indexWhere((e) => e.userId == user.id);
    if (i >= 0) {
      l[i] = PaidForModel(userId: user.id, factor: factor);
      emit(state.copyWith(paidFor: l));
    } else {
      addUser(user, factor);
    }
  }

  Future<void> _getCategories() async {
    final categories =
        (await ApiService.getInstance().getExpenseCategories(household)) ?? [];
    final category = state.category;
    if (category != null && !categories.contains(category)) {
      categories.add(category);
    }
    emit(state.copyWith(categories: categories, category: category));
  }
}

class AddUpdateExpenseState extends Equatable {
  final String name;
  final String description;
  final double amount;
  final DateTime date;
  final bool isIncome;
  final NamedByteArray? image;
  final int paidBy;
  final bool excludeFromStatistics;
  final List<PaidForModel> paidFor;
  final ExpenseCategory? category;
  final List<ExpenseCategory> categories;

  const AddUpdateExpenseState({
    this.name = "",
    required this.amount,
    this.description = "",
    this.isIncome = false,
    this.image,
    this.excludeFromStatistics = false,
    required this.paidBy,
    required this.date,
    this.category,
    this.paidFor = const [],
    this.categories = const [],
  });

  AddUpdateExpenseState copyWith({
    String? name,
    String? description,
    double? amount,
    int? paidBy,
    DateTime? date,
    bool? isIncome,
    NamedByteArray? image,
    bool? excludeFromStatistics,
    List<PaidForModel>? paidFor,
    ExpenseCategory? category,
    List<ExpenseCategory>? categories,
  }) =>
      AddUpdateExpenseState(
        name: name ?? this.name,
        description: description ?? this.description,
        amount: amount ?? this.amount,
        date: date ?? this.date,
        isIncome: isIncome ?? this.isIncome,
        image: image ?? this.image,
        excludeFromStatistics:
            excludeFromStatistics ?? this.excludeFromStatistics,
        category: category ?? this.category,
        paidBy: paidBy ?? this.paidBy,
        paidFor: paidFor ?? this.paidFor,
        categories: categories ?? this.categories,
      );

  AddUpdateExpenseState copyWithCategory({
    required ExpenseCategory? category,
    required List<ExpenseCategory>? categories,
  }) =>
      AddUpdateExpenseState(
        name: name,
        description: description,
        amount: amount,
        date: date,
        isIncome: isIncome,
        category: category,
        paidBy: paidBy,
        paidFor: paidFor,
        excludeFromStatistics: excludeFromStatistics,
        categories: categories ?? this.categories,
      );

  bool isValid() => name.isNotEmpty && amount != 0 && paidFor.isNotEmpty;

  @override
  List<Object?> get props => [
        name,
        description,
        amount,
        date,
        isIncome,
        image,
        excludeFromStatistics,
        paidBy,
        category,
        categories,
        paidFor,
      ];
}
