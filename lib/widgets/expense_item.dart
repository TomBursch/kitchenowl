import 'dart:io';

import 'package:animations/animations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/cubits/auth_cubit.dart';
import 'package:kitchenowl/enums/update_enum.dart';
import 'package:kitchenowl/models/expense.dart';
import 'package:kitchenowl/models/user.dart';
import 'package:kitchenowl/pages/expense_page.dart';
import 'package:intl/intl.dart';
import 'package:kitchenowl/widgets/expense_category_icon.dart';

class ExpenseItemWidget extends StatelessWidget {
  final Expense expense;
  final List<User> users;
  final void Function()? onUpdated;
  final bool displayPersonalAmount;

  const ExpenseItemWidget({
    Key? key,
    required this.expense,
    required this.users,
    this.onUpdated,
    this.displayPersonalAmount = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double amount = expense.amount;
    if (displayPersonalAmount &&
        BlocProvider.of<AuthCubit>(context).getUser() != null) {
      final i = expense.paidFor.indexWhere(
        (e) => e.userId == BlocProvider.of<AuthCubit>(context).getUser()!.id,
      );
      if (i >= 0) {
        amount = expense.amount *
            expense.paidFor[i].factor /
            expense.paidFor.fold(0, (p, v) => p + v.factor);
      }
    }

    return OpenContainer<UpdateEnum>(
      closedColor: ElevationOverlay.applySurfaceTint(
        Theme.of(context).colorScheme.surface,
        Theme.of(context).colorScheme.surfaceTint,
        1,
      ).withAlpha(0),
      closedElevation: 0,
      openColor: Theme.of(context).scaffoldBackgroundColor,
      closedShape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(
          Radius.circular(14),
        ),
      ),
      closedBuilder: (context, toggle) => Card(
        child: ListTile(
          leading: expense.category != null
              ? ExpenseCategoryIcon(
                  name: expense.category!.name,
                  color: expense.category!.color,
                )
              : null,
          title: Text(expense.name),
          trailing: Text(NumberFormat.simpleCurrency().format(amount)),
          subtitle: (expense.date != null)
              ? Text(DateFormat.yMMMd().format(expense.date!))
              : null,
          onTap: (kIsWeb || Platform.isIOS)
              ? () async {
                  final res = await Navigator.of(context).pushNamed<UpdateEnum>(
                    "/expense/${expense.id}",
                    arguments: [expense, users],
                  );
                  _handleUpdate(res);
                }
              : toggle,
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
