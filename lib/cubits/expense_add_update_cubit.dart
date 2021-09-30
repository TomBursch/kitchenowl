import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/models/expense.dart';
import 'package:kitchenowl/models/user.dart';
import 'package:kitchenowl/services/api/api_service.dart';

class AddUpdateExpenseCubit extends Cubit<AddUpdateExpenseState> {
  final Expense expense;
  AddUpdateExpenseCubit([this.expense = const Expense()])
      : super(AddUpdateExpenseState(
          amount: expense.amount,
          name: expense.name,
          paidBy: expense.paidById,
          paidFor: expense.paidFor,
        ));

  Future<void> saveRecipe() async {
    if (expense.id == null) {
      if (state.name.isNotEmpty) {
        await ApiService.getInstance().addExpense(Expense(
          amount: expense.amount,
          name: expense.name,
          paidById: expense.paidById,
          paidFor: expense.paidFor,
        ));
      }
    } else {
      await ApiService.getInstance().updateExpense(expense.copyWith(
        name: state.name,
        amount: state.amount,
        paidById: state.paidBy,
        paidFor: state.paidFor,
      ));
    }
  }

  Future<bool> removeRecipe() async {
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

  void addUser(User user) {
    emit(state.copyWith(
        paidFor: List.from(state.paidFor)
          ..add(PaidForModel(
            userId: user.id,
            factor: 1,
          ))));
  }

  bool containsUser(User user) {
    return state.paidFor.map((e) => e.userId).contains(user.id);
  }

  void removeUser(User user) {
    final l = List<PaidForModel>.from(state.paidFor);
    l.removeWhere((e) => e.userId == user.id);
    emit(state.copyWith(paidFor: l));
  }
}

class AddUpdateExpenseState extends Equatable {
  final String name;
  final double amount;
  final int paidBy;
  final List<PaidForModel> paidFor;

  const AddUpdateExpenseState(
      {this.name = "", this.amount, this.paidBy, this.paidFor = const []});

  AddUpdateExpenseState copyWith({
    String name,
    double amount,
    int paidBy,
    List<PaidForModel> paidFor,
  }) =>
      AddUpdateExpenseState(
        name: name ?? this.name,
        amount: amount ?? this.amount,
        paidBy: paidBy ?? this.paidBy,
        paidFor: paidFor ?? this.paidFor,
      );

  @override
  List<Object> get props => [name, amount, paidBy] + paidFor;
}
