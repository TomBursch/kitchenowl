import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/models/expense.dart';
import 'package:kitchenowl/models/user.dart';
import 'package:kitchenowl/services/api/api_service.dart';

class AddUpdateExpenseCubit extends Cubit<AddUpdateExpenseState> {
  final Expense expense;
  AddUpdateExpenseCubit([this.expense = const Expense(paidById: 0)])
      : super(AddUpdateExpenseState(
          amount: expense.amount,
          name: expense.name,
          paidBy: expense.paidById,
          paidFor: expense.paidFor,
          category: expense.category,
          categories: expense.category == null ? const [] : [expense.category!],
        )) {
    _getCategories();
  }

  Future<void> saveExpense() async {
    if (state.isValid()) {
      final amount = state.amount * (state.isIncome ? -1 : 1);
      if (expense.id == null) {
        await ApiService.getInstance().addExpense(Expense(
          amount: amount,
          name: state.name,
          paidById: state.paidBy,
          paidFor: state.paidFor,
          category: state.category,
        ));
      } else {
        await ApiService.getInstance().updateExpense(expense.copyWith(
          name: state.name,
          amount: amount,
          paidById: state.paidBy,
          paidFor: state.paidFor,
          category: Nullable(state.category),
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

  void setAmount(double amount) {
    emit(state.copyWith(amount: amount));
  }

  void setIncome(bool isIncome) {
    emit(state.copyWith(isIncome: isIncome));
  }

  void setPaidBy(User user) {
    emit(state.copyWith(paidBy: user.id));
  }

  void setPaidById(int userId) {
    emit(state.copyWith(paidBy: userId));
  }

  void setCategory(String? category) {
    List<String>? categories;
    if (category != null && !state.categories.contains(category)) {
      categories = List.of(state.categories)..add(category);
    }
    emit(state.copyWithCategory(
      category: category,
      categories: categories,
    ));
  }

  void addUser(User user) {
    if (!containsUser(user)) {
      emit(state.copyWith(
        paidFor: List.from(state.paidFor)
          ..add(PaidForModel(
            userId: user.id,
            factor: 1,
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

  void setFactor(User user, int factor) {
    final l = List<PaidForModel>.from(state.paidFor);
    final i = l.indexWhere((e) => e.userId == user.id);
    if (i >= 0) {
      l[i] = PaidForModel(userId: user.id, factor: factor);
      emit(state.copyWith(paidFor: l));
    }
  }

  Future<void> _getCategories() async {
    final categories =
        (await ApiService.getInstance().getExpenseCategories()) ?? const [];
    final category = state.category;
    if (category != null && !categories.contains(category)) {
      categories.add(category);
    }
    emit(state.copyWith(categories: categories, category: category));
  }
}

class AddUpdateExpenseState extends Equatable {
  final String name;
  final double amount;
  final bool isIncome;
  final int paidBy;
  final List<PaidForModel> paidFor;
  final String? category;
  final List<String> categories;

  const AddUpdateExpenseState({
    this.name = "",
    required this.amount,
    this.isIncome = false,
    required this.paidBy,
    this.category,
    this.paidFor = const [],
    this.categories = const [],
  });

  AddUpdateExpenseState copyWith({
    String? name,
    double? amount,
    int? paidBy,
    bool? isIncome,
    List<PaidForModel>? paidFor,
    String? category,
    List<String>? categories,
  }) =>
      AddUpdateExpenseState(
        name: name ?? this.name,
        amount: amount ?? this.amount,
        isIncome: isIncome ?? this.isIncome,
        category: category ?? this.category,
        paidBy: paidBy ?? this.paidBy,
        paidFor: paidFor ?? this.paidFor,
        categories: categories ?? this.categories,
      );

  AddUpdateExpenseState copyWithCategory({
    required String? category,
    required List<String>? categories,
  }) =>
      AddUpdateExpenseState(
        name: name,
        amount: amount,
        isIncome: isIncome,
        category: category,
        paidBy: paidBy,
        paidFor: paidFor,
        categories: categories ?? this.categories,
      );

  bool isValid() => name.isNotEmpty && amount != 0 && paidFor.isNotEmpty;

  @override
  List<Object?> get props =>
      [name, amount, isIncome, paidBy, category, categories] + paidFor;
}
