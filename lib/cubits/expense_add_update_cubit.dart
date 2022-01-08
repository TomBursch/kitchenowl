import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
        ));

  Future<void> saveExpense() async {
    if (state.isValid()) {
      if (expense.id == null) {
        await ApiService.getInstance().addExpense(Expense(
          amount: state.amount,
          name: state.name,
          paidById: state.paidBy,
          paidFor: state.paidFor,
        ));
      } else {
        await ApiService.getInstance().updateExpense(expense.copyWith(
          name: state.name,
          amount: state.amount,
          paidById: state.paidBy,
          paidFor: state.paidFor,
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

  void setPaidBy(User user) {
    emit(state.copyWith(paidBy: user.id));
  }

  void setPaidById(int userId) {
    emit(state.copyWith(paidBy: userId));
  }

  void addUser(User user) {
    if (!containsUser(user)) {
      emit(state.copyWith(
          paidFor: List.from(state.paidFor)
            ..add(PaidForModel(
              userId: user.id,
              factor: 1,
            ))));
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
    if (i > 0) {
      l[i] = PaidForModel(userId: user.id, factor: factor);
      emit(state.copyWith(paidFor: l));
    }
  }
}

class AddUpdateExpenseState extends Equatable {
  final String name;
  final double amount;
  final int paidBy;
  final List<PaidForModel> paidFor;

  const AddUpdateExpenseState({
    this.name = "",
    required this.amount,
    required this.paidBy,
    this.paidFor = const [],
  });

  AddUpdateExpenseState copyWith({
    String? name,
    double? amount,
    int? paidBy,
    List<PaidForModel>? paidFor,
  }) =>
      AddUpdateExpenseState(
        name: name ?? this.name,
        amount: amount ?? this.amount,
        paidBy: paidBy ?? this.paidBy,
        paidFor: paidFor ?? this.paidFor,
      );

  bool isValid() => name.isNotEmpty && amount != 0 && paidFor.isNotEmpty;

  @override
  List<Object?> get props => [name, amount, paidBy] + paidFor;
}
