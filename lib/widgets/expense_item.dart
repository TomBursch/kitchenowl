import 'dart:io';

import 'package:animations/animations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:kitchenowl/enums/update_enum.dart';
import 'package:kitchenowl/models/expense.dart';
import 'package:kitchenowl/models/user.dart';
import 'package:kitchenowl/pages/expense_page.dart';
import 'package:intl/intl.dart';

class ExpenseItemWidget extends StatelessWidget {
  final Expense expense;
  final List<User> users;
  final void Function()? onUpdated;

  const ExpenseItemWidget({
    Key? key,
    required this.expense,
    required this.users,
    this.onUpdated,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return OpenContainer<UpdateEnum>(
      closedColor: ElevationOverlay.applySurfaceTint(
        Theme.of(context).colorScheme.surface,
        Theme.of(context).colorScheme.surfaceTint,
        1,
      ).withAlpha(0),
      openColor: Theme.of(context).scaffoldBackgroundColor,
      closedShape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(
          Radius.circular(14),
        ),
      ),
      closedBuilder: (context, toggle) => Card(
        child: ListTile(
          title: Text(expense.name),
          trailing: Text(NumberFormat.simpleCurrency().format(expense.amount)),
          subtitle: (expense.createdAt != null)
              ? Text(DateFormat.yMMMd().format(expense.createdAt!))
              : null,
          onTap: (kIsWeb || !Platform.isIOS)
              ? toggle
              : () async {
                  final res = await Navigator.of(context)
                      .push<UpdateEnum>(MaterialPageRoute(
                    builder: (context) => ExpensePage(
                      expense: expense,
                      users: users,
                    ),
                  ));
                  _handleUpdate(res);
                },
        ),
      ),
      onClosed: _handleUpdate,
      openBuilder: (context, toggle) => ExpensePage(
        expense: expense,
        users: users,
      ),
    );
  }

  void _handleUpdate(UpdateEnum? res) {
    if (onUpdated != null &&
        (res == UpdateEnum.updated || res == UpdateEnum.deleted)) {
      onUpdated!();
    }
  }
}
