import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:kitchenowl/cubits/household_add_update/household_update_cubit.dart';
import 'package:kitchenowl/kitchenowl.dart';

class SliverHouseholdDangerZone extends StatelessWidget {
  const SliverHouseholdDangerZone({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.redAccent,
            width: 2,
          ),
        ),
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${AppLocalizations.of(context)!.dangerZone}:',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            LoadingElevatedButton(
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all<Color>(
                  Colors.redAccent,
                ),
                foregroundColor: MaterialStateProperty.all<Color>(
                  Colors.white,
                ),
              ),
              onPressed: () async {
                final confirm = await askForConfirmation(
                  context: context,
                  title: Text(
                    AppLocalizations.of(context)!.householdDelete,
                  ),
                  content: Text(
                    AppLocalizations.of(context)!.householdDeleteConfirmation(
                      BlocProvider.of<HouseholdUpdateCubit>(context)
                          .household
                          .name,
                    ),
                  ),
                );
                if (confirm) {
                  if (await BlocProvider.of<HouseholdUpdateCubit>(context)
                      .deleteHousehold()) {
                    context.go('/household');
                  }
                }
              },
              child: Text(AppLocalizations.of(context)!.householdDelete),
            ),
          ],
        ),
      ),
    );
  }
}
