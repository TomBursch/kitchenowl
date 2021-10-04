import 'package:flutter/material.dart';
import 'package:kitchenowl/enums/update_enum.dart';
import 'package:kitchenowl/models/expense.dart';
import 'package:kitchenowl/models/user.dart';
import 'package:kitchenowl/pages/expense_page.dart';
import 'package:intl/intl.dart';

class ExpenseItemWidget extends StatelessWidget {
  final Expense expense;
  final List<User> users;
  final void Function() onUpdated;

  const ExpenseItemWidget({
    Key key,
    @required this.expense,
    this.users,
    this.onUpdated,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(expense.name),
        trailing: Text(NumberFormat.simpleCurrency().format(expense.amount)),
        subtitle: (expense.createdAt != null)
            ? Text(expense.createdAt.toString())
            : null,
        onTap: () async {
          final res =
              await Navigator.of(context).push<UpdateEnum>(MaterialPageRoute(
                  builder: (context) => ExpensePage(
                        expense: expense,
                        users: users,
                      )));
          if (onUpdated != null &&
              (res == UpdateEnum.updated || res == UpdateEnum.deleted)) {
            onUpdated();
          }
        },
      ),
    );
  }
}
