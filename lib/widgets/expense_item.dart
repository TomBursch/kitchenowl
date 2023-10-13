import 'dart:io';

import 'package:animations/animations.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:kitchenowl/cubits/auth_cubit.dart';
import 'package:kitchenowl/cubits/household_cubit.dart';
import 'package:kitchenowl/enums/update_enum.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/models/expense.dart';
import 'package:kitchenowl/models/household.dart';
import 'package:kitchenowl/pages/expense_page.dart';
import 'package:intl/intl.dart';
import 'package:kitchenowl/widgets/expense_category_icon.dart';
import 'package:tuple/tuple.dart';

class ExpenseItemWidget extends StatelessWidget {
  final Expense expense;
  final void Function()? onUpdated;
  final bool displayPersonalAmount;

  const ExpenseItemWidget({
    Key? key,
    required this.expense,
    this.onUpdated,
    this.displayPersonalAmount = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double amount = expense.amount;
    final household = context.read<HouseholdCubit>().state.household;
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
      useRootNavigator: true,
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
          title: Row(
            children: [
              Expanded(child: Text(expense.name)),
              Text(NumberFormat.simpleCurrency().format(amount)),
            ],
          ),
          subtitle: Row(
            children: [
              (expense.date != null)
                  ? Expanded(
                      child: Text(DateFormat.yMMMd().format(expense.date!)),
                    )
                  : const Spacer(),
              Text(
                "${expense.isIncome ? AppLocalizations.of(context)!.expenseReceivedBy : AppLocalizations.of(context)!.expensePaidBy} ${household.member?.firstWhereOrNull(
                      (e) => e.id == expense.paidById,
                    )?.name ?? AppLocalizations.of(context)!.other}",
              ),
            ],
          ),
          onTap: (kIsWeb || Platform.isIOS)
              ? () async {
                  final household =
                      BlocProvider.of<HouseholdCubit>(context).state.household;
                  context.push(
                    "/household/${household.id}/expenses/${expense.id}",
                    extra: Tuple2<Household, Expense>(household, expense),
                  );
                  // _handleUpdate(res);
                }
              : toggle,
        ),
      ),
      onClosed: _handleUpdate,
      openBuilder: (ctx, toggle) => ExpensePage(
        household: BlocProvider.of<HouseholdCubit>(context).state.household,
        expense: expense,
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
