import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/cubits/shoppinglist_cubit.dart';

class ShoppingListConfirmRememoveFab extends StatelessWidget {
  const ShoppingListConfirmRememoveFab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ShoppinglistCubit, ShoppinglistCubitState>(
      builder: (context, state) {
        if (state.selectedListItems.isEmpty ||
            state is SearchShoppinglistCubitState) return const SizedBox();

        return FloatingActionButton(
          onPressed: context.read<ShoppinglistCubit>().confirmRemove,
          child: const Icon(Icons.done_all_rounded),
        );
      },
    );
  }
}
