import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:kitchenowl/app.dart';
import 'package:kitchenowl/cubits/household_cubit.dart';
import 'package:kitchenowl/cubits/shoppinglist_cubit.dart';
import 'package:kitchenowl/kitchenowl.dart';

class ShoppingListFab extends StatelessWidget {
  const ShoppingListFab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ShoppinglistCubit, ShoppinglistCubitState>(
      builder: (context, state) {
        final hasSelectedItems = state.selectedListItems.isNotEmpty &&
            state is! SearchShoppinglistCubitState;
        final showConfirmFab =
            !App.settings.shoppingListTapToRemove && hasSelectedItems;

        // Check if loyalty cards feature is enabled
        final household = context.read<HouseholdCubit>().state.household;
        final showLoyaltyCardsFab = household.featureLoyaltyCards ?? true;

        if (!showConfirmFab && !showLoyaltyCardsFab) {
          return const SizedBox();
        }

        if (showConfirmFab && showLoyaltyCardsFab) {
          // Show both FABs in a column
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FloatingActionButton.small(
                heroTag: 'loyaltyCardsFab',
                onPressed: () => _openLoyaltyCards(context, household),
                tooltip: AppLocalizations.of(context)!.loyaltyCards,
                child: const Icon(Icons.wallet_rounded),
              ),
              const SizedBox(height: 16),
              FloatingActionButton(
                heroTag: 'confirmRemoveFab',
                onPressed: context.read<ShoppinglistCubit>().confirmRemove,
                child: const Icon(Icons.done_all_rounded),
              ),
            ],
          );
        }

        if (showConfirmFab) {
          return FloatingActionButton(
            heroTag: 'confirmRemoveFab',
            onPressed: context.read<ShoppinglistCubit>().confirmRemove,
            child: const Icon(Icons.done_all_rounded),
          );
        }

        // Only show loyalty cards FAB
        return FloatingActionButton(
          heroTag: 'loyaltyCardsFab',
          onPressed: () => _openLoyaltyCards(context, household),
          tooltip: AppLocalizations.of(context)!.loyaltyCards,
          child: const Icon(Icons.wallet_rounded),
        );
      },
    );
  }

  void _openLoyaltyCards(BuildContext context, dynamic household) {
    context.push('/household/${household.id}/loyalty-cards');
  }
}

