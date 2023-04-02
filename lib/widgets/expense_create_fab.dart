import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/cubits/expense_list_cubit.dart';
import 'package:kitchenowl/cubits/household_cubit.dart';
import 'package:kitchenowl/enums/update_enum.dart';
import 'package:kitchenowl/pages/expense_add_update_page.dart';
import 'package:kitchenowl/widgets/kitchenowl_fab.dart';

class ExpenseCreateFab extends StatelessWidget {
  const ExpenseCreateFab({super.key});

  @override
  Widget build(BuildContext context) {
    return KitchenOwlFab(
      openBuilder: (BuildContext ctx, VoidCallback _) {
        return AddUpdateExpensePage(
          household: BlocProvider.of<HouseholdCubit>(context).state.household,
        );
      },
      onClosed: (data) {
        if (data == UpdateEnum.updated) {
          BlocProvider.of<ExpenseListCubit>(context).refresh();
          BlocProvider.of<HouseholdCubit>(context).refresh();
        }
      },
    );
  }
}
