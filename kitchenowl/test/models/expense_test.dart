// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables
import 'package:flutter_test/flutter_test.dart';
import 'package:kitchenowl/models/expense.dart';
import 'package:kitchenowl/models/expense_category.dart';

void main() {
  test("Expense should be equal", () {
    // Given
    final e1 = Expense(
      id: 1,
      name: "Name",
      date: DateTime(2023),
      paidById: 3,
      paidFor: [PaidForModel(userId: 5)],
      amount: 105,
      category: ExpenseCategory(id: 4, name: "Name"),
    );
    final e2 = Expense(
      id: 1,
      name: "Name",
      date: DateTime(2023),
      paidById: 3,
      paidFor: [PaidForModel(userId: 5)],
      amount: 105,
      category: ExpenseCategory(id: 4, name: "Name"),
    );
    // Then
    expect(e1 == e2, equals(true));
  });
  test("Expense should not be equal", () {
    // Given
    final e1 = Expense(
      id: 1,
      name: "Name",
      date: DateTime(2023),
      paidById: 3,
      paidFor: [PaidForModel(userId: 5)],
      amount: 105,
      category: ExpenseCategory(id: 4, name: "Name"),
    );
    final e2 = Expense(
      id: 1,
      name: "Name",
      date: DateTime(2023),
      paidById: 3,
      paidFor: [PaidForModel(userId: 5)],
      amount: 0,
      category: ExpenseCategory(id: 4, name: "Name"),
    );
    // Then
    expect(e1 == e2, equals(false));
  });
  test("Expense deep should not be equal", () {
    // Given
    final e1 = Expense(
      id: 1,
      name: "Name",
      date: DateTime(2023),
      paidById: 3,
      paidFor: [PaidForModel(userId: 5)],
      amount: 105,
      category: ExpenseCategory(id: 4, name: "Name"),
    );
    final e2 = Expense(
      id: 1,
      name: "Name",
      date: DateTime(2023),
      paidById: 3,
      paidFor: [PaidForModel(userId: 5)],
      amount: 105,
      category: ExpenseCategory(id: 1, name: "Name"),
    );
    // Then
    expect(e1 == e2, equals(false));
  });
  // test("Expense should de-/serialize", () {
  //   // Given
  //   final e = Expense(
  //     id: 1,
  //     name: "Name",
  //     date: DateTime(2023),
  //     paidById: 3,
  //     paidFor: [PaidForModel(userId: 5)],
  //     amount: 105,
  //     category: ExpenseCategory(id: 4, name: "Name"),
  //   );
  //   // When
  //   final actual = Expense.fromJson(e.toJsonWithId());
  //   // Then
  //   expect(actual, equals(e));
  // });
}
