import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/cubits/expense_list_cubit.dart';
import 'package:kitchenowl/enums/update_enum.dart';
import 'package:kitchenowl/pages/expense_add_update_page.dart';

class ExpenseCreateFab extends StatelessWidget {
  const ExpenseCreateFab({super.key});

  @override
  Widget build(BuildContext context) {
    return OpenContainer(
      useRootNavigator: true,
      transitionType: ContainerTransitionType.fade,
      openBuilder: (BuildContext ctx, VoidCallback _) {
        return AddUpdateExpensePage(
          household: BlocProvider.of<ExpenseListCubit>(context).household,
          users: BlocProvider.of<ExpenseListCubit>(context).state.users,
        );
      },
      openColor: Theme.of(context).scaffoldBackgroundColor,
      onClosed: (data) {
        if (data == UpdateEnum.updated) {
          BlocProvider.of<ExpenseListCubit>(context).refresh();
        }
      },
      closedElevation: 4.0,
      closedShape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(
          Radius.circular(14),
        ),
      ),
      closedColor:
          Theme.of(context).floatingActionButtonTheme.backgroundColor ??
              Theme.of(context).colorScheme.secondary,
      closedBuilder: (
        BuildContext context,
        VoidCallback openContainer,
      ) {
        return SizedBox(
          height: 56,
          width: 56,
          child: Center(
            child: Icon(
              Icons.add,
              color: Theme.of(context).colorScheme.onSecondary,
            ),
          ),
        );
      },
    );
  }
}
