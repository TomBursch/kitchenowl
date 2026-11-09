import 'package:collection/collection.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/cubits/household_add_update/household_update_cubit.dart';
import 'package:kitchenowl/cubits/settings_cubit.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/models/shoppinglist.dart';
import 'package:kitchenowl/services/location_service.dart';
import 'package:kitchenowl/widgets/dismissible_card.dart';
import 'package:kitchenowl/widgets/shopping_list/location_edit_dialog.dart';
import 'package:sliver_tools/sliver_tools.dart';

class HouseholdSettingsShoppinglistLocationsPage extends StatelessWidget {
  final int shoppingListId;

  const HouseholdSettingsShoppinglistLocationsPage({
    super.key,
    required this.shoppingListId,
  });

  Future<void> _addOrEdit(
    BuildContext context,
    ShoppingList shoppingList, [
    int? index,
  ]) async {
    final res = await showDialog<ShoppingListLocation>(
      context: context,
      builder: (context) => LocationEditDialog(
        location: index != null ? shoppingList.locations[index] : null,
      ),
    );
    if (res == null || !context.mounted) return;

    final locations = List.of(shoppingList.locations);
    if (index != null) {
      locations[index] = res;
    } else {
      locations.add(res);
    }
    BlocProvider.of<HouseholdUpdateCubit>(context).updateShoppingList(
      shoppingList.copyWith(locations: locations),
      updateLocations: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HouseholdUpdateCubit, HouseholdUpdateState>(
      builder: (context, state) {
        final shoppingList =
            state.shoppingLists.firstWhereOrNull((e) => e.id == shoppingListId);

        return Scaffold(
          floatingActionButton: shoppingList == null
              ? null
              : FloatingActionButton.extended(
                  onPressed: () => _addOrEdit(context, shoppingList),
                  icon: const Icon(Icons.add_location_alt_rounded),
                  label: Text(
                    AppLocalizations.of(context)!.shoppingListLocationAdd,
                  ),
                ),
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppLocalizations.of(context)!.shoppingListLocations),
                    if (shoppingList != null)
                      Text(
                        shoppingList.name,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
              if (shoppingList != null)
                SliverCrossAxisConstrained(
                  maxCrossAxisExtent: 600,
                  child: SliverPadding(
                    padding: const EdgeInsets.fromLTRB(0, 0, 0, 96),
                    sliver: SliverList.list(
                      children: [
                        if (LocationService.isGeofencingSupported)
                          _ArrivalNotificationsTile(
                            shoppingListId: shoppingListId,
                          ),
                        if (shoppingList.locations.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.location_off_outlined,
                                  size: 48,
                                  color: Theme.of(context).disabledColor,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  AppLocalizations.of(context)!
                                      .shoppingListLocationsEmpty,
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        for (final (i, location)
                            in shoppingList.locations.indexed)
                          DismissibleCard(
                            key: ValueKey(location),
                            confirmDismiss: (_) async => true,
                            onDismissed: (_) {
                              BlocProvider.of<HouseholdUpdateCubit>(context)
                                  .updateShoppingList(
                                shoppingList.copyWith(
                                  locations: List.of(shoppingList.locations)
                                    ..removeAt(i),
                                ),
                                updateLocations: true,
                              );
                            },
                            title: Text(
                              (location.name?.isNotEmpty ?? false)
                                  ? location.name!
                                  : '${location.latitude.toStringAsFixed(5)}, ${location.longitude.toStringAsFixed(5)}',
                            ),
                            subtitle: Text(
                              [
                                if (location.name?.isNotEmpty ?? false)
                                  '${location.latitude.toStringAsFixed(5)}, ${location.longitude.toStringAsFixed(5)}',
                                '${AppLocalizations.of(context)!.radius}: ${location.radius} m',
                              ].join(' · '),
                            ),
                            trailing:
                                const Icon(Icons.edit_location_alt_rounded),
                            onTap: () => _addOrEdit(context, shoppingList, i),
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _ArrivalNotificationsTile extends StatelessWidget {
  final int shoppingListId;

  const _ArrivalNotificationsTile({required this.shoppingListId});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsCubit, SettingsState>(
      buildWhen: (prev, curr) => prev.location != curr.location,
      builder: (context, state) {
        final enabled = state.location.enabled && state.location.notify;
        final value = enabled &&
            !state.location.mutedShoppingLists.contains(shoppingListId);

        return ListTile(
          leading: const Icon(Icons.notifications_active_rounded),
          title: Text(
            AppLocalizations.of(context)!.locationArrivalNotificationsForList,
          ),
          subtitle: Text(AppLocalizations.of(context)!.locationOnlyThisDevice),
          enabled: enabled,
          onTap: enabled
              ? () => BlocProvider.of<SettingsCubit>(context)
                  .setShoppingListLocationMuted(shoppingListId, value)
              : null,
          trailing: KitchenOwlSwitch(
            value: value,
            onChanged: enabled
                ? (value) => BlocProvider.of<SettingsCubit>(context)
                    .setShoppingListLocationMuted(shoppingListId, !value)
                : null,
          ),
        );
      },
    );
  }
}
