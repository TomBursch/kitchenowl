import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/helpers/named_bytearray.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/models/expense.dart';
import 'package:kitchenowl/models/user.dart';
import 'package:kitchenowl/services/api/api_service.dart';

class AddUpdateExpenseCubit extends Cubit<AddUpdateExpenseState> {
  final Expense expense;
  AddUpdateExpenseCubit([this.expense = const Expense(paidById: 0)])
      : super(AddUpdateExpenseState(
          amount: expense.amount.abs(),
          isIncome: expense.amount < 0,
          name: expense.name,
          paidBy: expense.paidById,
          paidFor: expense.paidFor,
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
        await ApiService.getInstance().addExpense(Expense(
          amount: amount,
          name: _state.name,
          image: image ?? expense.image,
          paidById: _state.paidBy,
          paidFor: _state.paidFor,
          category: _state.category,
        ));
      } else {
        await ApiService.getInstance().updateExpense(expense.copyWith(
          name: state.name,
          amount: amount,
          image: image,
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
  final NamedByteArray? image;
  final int paidBy;
  final List<PaidForModel> paidFor;
  final String? category;
  final List<String> categories;

  const AddUpdateExpenseState({
    this.name = "",
    required this.amount,
    this.isIncome = false,
    this.image,
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
    NamedByteArray? image,
    List<PaidForModel>? paidFor,
    String? category,
    List<String>? categories,
  }) =>
      AddUpdateExpenseState(
        name: name ?? this.name,
        amount: amount ?? this.amount,
        isIncome: isIncome ?? this.isIncome,
        image: image ?? this.image,
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
  List<Object?> get props => [
        name,
        amount,
        isIncome,
        image,
        paidBy,
        category,
        categories,
        paidFor,
      ];
}
