import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:kitchenowl/cubits/auth_cubit.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/models/household.dart';

class HouseholdCard extends StatelessWidget {
  final Household household;

  const HouseholdCard({super.key, required this.household});

  @override
  Widget build(BuildContext context) {
    final user = BlocProvider.of<AuthCubit>(context).getUser();
    final member = household.member?.firstWhereOrNull(
      (m) => user?.id == m.id,
    );

    return Card(
      child: InkWell(
        onTap: () => context.go(
          '/household/${household.id}',
          extra: household,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (household.image != null)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(14),
                ),
                child: SizedBox(
                  height: 150,
                  child: Image(
                    fit: BoxFit.cover,
                    image: getImageProvider(
                      context,
                      household.image!,
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
              child: Text(
                household.name,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            if (user != null &&
                member != null &&
                (household.featureExpenses ?? false) &&
                member.balance != 0)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                child: Text(
                  "${AppLocalizations.of(context)!.balances}: ${NumberFormat.simpleCurrency().format(member.balance)}",
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
