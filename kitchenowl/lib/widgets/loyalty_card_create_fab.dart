import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/cubits/household_cubit.dart';
import 'package:kitchenowl/cubits/loyalty_card_list_cubit.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/pages/loyalty_card_add_update_page.dart';

class LoyaltyCardCreateFab extends StatelessWidget {
  const LoyaltyCardCreateFab({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      heroTag: 'loyaltyCardCreateFab',
      onPressed: () async {
        final household =
            BlocProvider.of<HouseholdCubit>(context).state.household;
        final result = await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => LoyaltyCardAddUpdatePage(
              household: household,
            ),
          ),
        );
        if (result != null && context.mounted) {
          BlocProvider.of<LoyaltyCardListCubit>(context).refresh();
        }
      },
      icon: const Icon(Icons.add),
      label: Text(AppLocalizations.of(context)!.loyaltyCardAdd),
    );
  }
}

