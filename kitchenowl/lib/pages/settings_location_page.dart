import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/app.dart';
import 'package:kitchenowl/cubits/auth_cubit.dart';
import 'package:kitchenowl/cubits/household_add_update/household_update_cubit.dart';
import 'package:kitchenowl/cubits/settings_cubit.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/models/household.dart';
import 'package:kitchenowl/models/shoppinglist.dart';
import 'package:kitchenowl/pages/settings_household/household_settings_shoppinglist_locations_page.dart';
import 'package:kitchenowl/services/location_service.dart';
import 'package:sliver_tools/sliver_tools.dart';

class SettingsLocationPage extends StatefulWidget {
  final Household? household;

  const SettingsLocationPage({super.key, this.household});

  /// Short summary of the current settings, e.g. for the settings overview
  static String summary(
    BuildContext context,
    ShoppingListLocationSettings settings,
  ) {
    if (!settings.enabled) return AppLocalizations.of(context)!.locationOff;
    final parts = [
      if (settings.notify && LocationService.isGeofencingSupported)
        AppLocalizations.of(context)!.locationNotifications,
      if (settings.autoSwitch)
        AppLocalizations.of(context)!.locationAutoSwitchShort,
    ];

    return parts.isEmpty
        ? AppLocalizations.of(context)!.locationOn
        : parts.join(', ');
  }

  @override
  State<SettingsLocationPage> createState() => _SettingsLocationPageState();
}

class _SettingsLocationPageState extends State<SettingsLocationPage> {
  HouseholdUpdateCubit? householdCubit;

  @override
  void initState() {
    super.initState();
    if (widget.household != null && !App.isOffline) {
      householdCubit = HouseholdUpdateCubit(widget.household!);
    }
  }

  @override
  void dispose() {
    householdCubit?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.locationBasedShoppingLists),
      ),
      body: BlocBuilder<SettingsCubit, SettingsState>(
        buildWhen: (prev, curr) => prev.location != curr.location,
        builder: (context, state) => CustomScrollView(
          slivers: [
            SliverCrossAxisConstrained(
              maxCrossAxisExtent: 600,
              child: SliverList.list(
                children: _buildSettings(context, state.location),
              ),
            ),
            if (householdCubit != null && state.location.enabled)
              SliverCrossAxisConstrained(
                maxCrossAxisExtent: 600,
                child: _SliverShoppingLists(
                  cubit: householdCubit!,
                  household: widget.household!,
                  settings: state.location,
                ),
              ),
            SliverToBoxAdapter(
              child: SizedBox(height: MediaQuery.paddingOf(context).bottom),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildSettings(
    BuildContext context,
    ShoppingListLocationSettings location,
  ) {
    final cubit = BlocProvider.of<SettingsCubit>(context);

    return [
      ListTile(
        title: Text(AppLocalizations.of(context)!.locationUseStoreLocations),
        subtitle: Text(
          AppLocalizations.of(context)!.locationBasedShoppingListsDescription,
        ),
        leading: const Icon(Icons.share_location_rounded),
        onTap: () => _setEnabled(context, !location.enabled),
        trailing: KitchenOwlSwitch(
          value: location.enabled,
          onChanged: (value) => _setEnabled(context, value),
        ),
      ),
      if (location.enabled && LocationService.isGeofencingSupported) ...[
        const Divider(),
        ListTile(
          title: Text(AppLocalizations.of(context)!.locationNotifyOnArrival),
          leading: const Icon(Icons.notifications_active_rounded),
          onTap: () => cubit.setLocationNotify(!location.notify),
          trailing: KitchenOwlSwitch(
            value: location.notify,
            onChanged: cubit.setLocationNotify,
          ),
        ),
        if (location.notify) ...[
          const _BackgroundPermissionHint(),
          ListTile(
            title: Text(
              AppLocalizations.of(context)!.locationNotifyOncePerVisit,
            ),
            leading: const Icon(Icons.notifications_paused_rounded),
            onTap: () => cubit.setLocationNotifyOncePerVisit(
              !location.notifyOncePerVisit,
            ),
            trailing: KitchenOwlSwitch(
              value: location.notifyOncePerVisit,
              onChanged: cubit.setLocationNotifyOncePerVisit,
            ),
          ),
          ListTile(
            title: Text(AppLocalizations.of(context)!.locationIgnoreEmptyLists),
            leading: const Icon(Icons.playlist_remove_rounded),
            onTap: () => cubit.setLocationIgnoreEmptyLists(
              !location.ignoreEmptyLists,
            ),
            trailing: KitchenOwlSwitch(
              value: location.ignoreEmptyLists,
              onChanged: cubit.setLocationIgnoreEmptyLists,
            ),
          ),
        ],
      ],
      if (location.enabled) ...[
        const Divider(),
        ListTile(
          title: Text(AppLocalizations.of(context)!.locationAutoSwitch),
          leading: const Icon(Icons.swap_horiz_rounded),
          onTap: () => cubit.setLocationAutoSwitch(!location.autoSwitch),
          trailing: KitchenOwlSwitch(
            value: location.autoSwitch,
            onChanged: cubit.setLocationAutoSwitch,
          ),
        ),
        if (location.autoSwitch)
          ListTile(
            title: Text(AppLocalizations.of(context)!.locationConfirmSwitch),
            leading: const Icon(Icons.help_outline_rounded),
            onTap: () =>
                cubit.setLocationConfirmSwitch(!location.confirmSwitch),
            trailing: KitchenOwlSwitch(
              value: location.confirmSwitch,
              onChanged: cubit.setLocationConfirmSwitch,
            ),
          ),
      ],
    ];
  }

  Future<void> _setEnabled(BuildContext context, bool enabled) async {
    final granted =
        await BlocProvider.of<SettingsCubit>(context).setLocationEnabled(
      enabled,
    );
    if (!granted && context.mounted) {
      showSnackbar(
        context: context,
        width: null,
        content: Text(AppLocalizations.of(context)!.locationUnavailable),
      );
    }
  }
}

/// Overview of the household's shopping lists with their locations
class _SliverShoppingLists extends StatelessWidget {
  final HouseholdUpdateCubit cubit;
  final Household household;
  final ShoppingListLocationSettings settings;

  const _SliverShoppingLists({
    required this.cubit,
    required this.household,
    required this.settings,
  });

  @override
  Widget build(BuildContext context) {
    final user = BlocProvider.of<AuthCubit>(context).getUser();
    final canEdit = user != null && household.hasAdminRights(user);
    final canMute = settings.notify && LocationService.isGeofencingSupported;

    return BlocBuilder<HouseholdUpdateCubit, HouseholdUpdateState>(
      bloc: cubit,
      builder: (context, state) {
        final shoppingLists = state.shoppingLists;

        return SliverList.list(
          children: [
            const Divider(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 2),
              child: Text(
                AppLocalizations.of(context)!.shoppingLists.toUpperCase(),
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ),
            if (state is LoadingHouseholdUpdateState)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
            for (final shoppingList in shoppingLists)
              _ShoppingListTile(
                shoppingList: shoppingList,
                muted: settings.mutedShoppingLists.contains(shoppingList.id),
                canMute: canMute,
                onTap: canEdit
                    ? () => Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => BlocProvider.value(
                            value: cubit,
                            child: HouseholdSettingsShoppinglistLocationsPage(
                              shoppingListId: shoppingList.id!,
                            ),
                          ),
                        ))
                    : null,
              ),
            if (state is! LoadingHouseholdUpdateState)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Text(
                  [
                    canEdit
                        ? AppLocalizations.of(context)!.locationListsHint
                        : AppLocalizations.of(context)!
                            .locationListsHintNoAdmin,
                    if (canMute)
                      AppLocalizations.of(context)!.locationListsMuteHint,
                  ].join(' '),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ShoppingListTile extends StatelessWidget {
  final ShoppingList shoppingList;
  final bool muted;
  final bool canMute;
  final VoidCallback? onTap;

  const _ShoppingListTile({
    required this.shoppingList,
    required this.muted,
    required this.canMute,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasLocations = shoppingList.locations.isNotEmpty;

    return ListTile(
      leading: Icon(
        hasLocations ? Icons.location_on_rounded : Icons.location_off_outlined,
      ),
      title: Text(shoppingList.name),
      subtitle: Text(
        AppLocalizations.of(context)!
            .shoppingListLocationsCount(shoppingList.locations.length),
      ),
      onTap: onTap,
      trailing: canMute && hasLocations
          ? Tooltip(
              message: AppLocalizations.of(context)!
                  .locationArrivalNotificationsForList,
              child: KitchenOwlSwitch(
                value: !muted,
                onChanged: (value) => BlocProvider.of<SettingsCubit>(context)
                    .setShoppingListLocationMuted(shoppingList.id!, !value),
              ),
            )
          : null,
    );
  }
}

class _BackgroundPermissionHint extends StatefulWidget {
  const _BackgroundPermissionHint();

  @override
  State<_BackgroundPermissionHint> createState() =>
      _BackgroundPermissionHintState();
}

class _BackgroundPermissionHintState extends State<_BackgroundPermissionHint>
    with WidgetsBindingObserver {
  bool hasPermission = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _check();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _check();
  }

  Future<void> _check() async {
    final res = await LocationService.hasBackgroundPermission();
    if (mounted) setState(() => hasPermission = res);
  }

  @override
  Widget build(BuildContext context) {
    if (hasPermission) return const SizedBox();

    return ListTile(
      leading: Icon(
        Icons.warning_amber_rounded,
        color: Theme.of(context).colorScheme.error,
      ),
      title: Text(
        AppLocalizations.of(context)!.locationBackgroundPermissionHint,
      ),
      onTap: () async {
        await LocationService.requestPermission(background: true);
        if (!await LocationService.hasBackgroundPermission()) {
          await LocationService.openAppSettings();
        }
        _check();
      },
    );
  }
}
