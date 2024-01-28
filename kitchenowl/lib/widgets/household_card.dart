import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_blurhash/flutter_blurhash.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:kitchenowl/cubits/auth_cubit.dart';
import 'package:kitchenowl/cubits/household_list_cubit.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/models/household.dart';
import 'package:transparent_image/transparent_image.dart';

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
          '/household/${household.id}/${household.viewOrdering?.firstOrNull.toString()}',
          extra: household,
        ),
        onLongPress: () => showModalBottomSheet<void>(
          context: context,
          showDragHandle: true,
          builder: (ctx) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.home_rounded),
                  title: Text(household.name),
                  subtitle: household.member == null
                      ? null
                      : Text(
                          "${AppLocalizations.of(ctx)!.members}: ${household.member!.length}",
                        ),
                ),
                const Divider(),
                LoadingElevatedButton(
                  onPressed: member == null
                      ? null
                      : () async {
                          await BlocProvider.of<HouseholdListCubit>(context)
                              .leaveHousehold(household, member);
                          Navigator.of(ctx).pop();
                        },
                  child: Text(AppLocalizations.of(ctx)!.householdLeave),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (household.image?.isNotEmpty ?? false)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(14),
                ),
                child: SizedBox(
                  height: 150,
                  child: FadeInImage(
                    fit: BoxFit.cover,
                    placeholder: household.imageHash != null
                        ? BlurHashImage(household.imageHash!)
                        : MemoryImage(kTransparentImage) as ImageProvider,
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
