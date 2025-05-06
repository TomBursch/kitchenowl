import 'package:equatable/equatable.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/models/expense_category.dart';
import 'package:kitchenowl/models/household.dart';
import 'package:kitchenowl/services/api/api_service.dart';

class AddUpdateExpenseCategoryCubit
    extends Cubit<AddUpdateExpenseCategoryState> {
  final Household household;
  final ExpenseCategory category;

  AddUpdateExpenseCategoryCubit(
    this.household, [
    this.category = const ExpenseCategory(),
  ]) : super(AddUpdateExpenseCategoryState(
          name: category.name,
          color: category.color,
        ));

  Future<void> saveCategory() async {
    final _state = state;
    if (_state.isValid()) {
      await ApiService.getInstance().addExpenseCategory(
        household,
        ExpenseCategory(
          name: _state.name,
          color: _state.color,
        ),
      );
    }
  }

  void setName(String name) {
    emit(state.copyWith(name: name));
  }

  void setColor(Nullable<Color> color) {
    emit(state.copyWith(color: color.map<Color>((c) => c?.withAlpha(255))));
  }
}

class AddUpdateExpenseCategoryState extends Equatable {
  final String name;
  final Color? color;

  const AddUpdateExpenseCategoryState({
    this.name = "",
    this.color,
  });

  AddUpdateExpenseCategoryState copyWith({
    String? name,
    Nullable<Color>? color,
  }) =>
      AddUpdateExpenseCategoryState(
        name: name ?? this.name,
        color: (color ?? Nullable(this.color)).value,
      );

  bool isValid() => name.isNotEmpty && (color == null || color!.a == 1.0);

  @override
  List<Object?> get props => [
        name,
        color,
      ];
}
