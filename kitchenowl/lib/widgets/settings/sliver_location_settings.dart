import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/cubits/settings_cubit.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/services/location_service.dart';
import 'package:kitchenowl/widgets/sliver_expansion_tile.dart';

class SliverLocationSettings extends StatelessWidget {
  const SliverLocationSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsCubit, SettingsState>(
      buildWhen: (prev, curr) => prev.location != curr.location,
      builder: (context, state) {
        final cubit = BlocProvider.of<SettingsCubit>(context);
        final location = state.location;

        return SliverExpansionTile(
          startCollapsed: !location.enabled,
          titleCrossAxisAlignment: CrossAxisAlignment.center,
          title: Row(
            children: [
              const SizedBox(width: 16),
              const Icon(Icons.location_on_rounded),
              const SizedBox(width: 12),
              Text(
                AppLocalizations.of(context)!.locationBasedShoppingLists,
                style: TextTheme.of(context).labelLarge,
              ),
            ],
          ),
          sliver: SliverList.list(
            children: [
              ListTile(
                title: Text(
                  AppLocalizations.of(context)!.locationUseStoreLocations,
                ),
                subtitle: Text(
                  AppLocalizations.of(context)!
                      .locationBasedShoppingListsDescription,
                ),
                leading: const Icon(Icons.share_location_rounded),
                onTap: () => _setEnabled(context, !location.enabled),
                trailing: KitchenOwlSwitch(
                  value: location.enabled,
                  onChanged: (value) => _setEnabled(context, value),
                ),
              ),
              if (location.enabled &&
                  LocationService.isGeofencingSupported) ...[
                ListTile(
                  title: Text(
                    AppLocalizations.of(context)!.locationNotifyOnArrival,
                  ),
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
                    title: Text(
                      AppLocalizations.of(context)!.locationIgnoreEmptyLists,
                    ),
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
                ListTile(
                  title: Text(AppLocalizations.of(context)!.locationAutoSwitch),
                  leading: const Icon(Icons.swap_horiz_rounded),
                  onTap: () =>
                      cubit.setLocationAutoSwitch(!location.autoSwitch),
                  trailing: KitchenOwlSwitch(
                    value: location.autoSwitch,
                    onChanged: cubit.setLocationAutoSwitch,
                  ),
                ),
                if (location.autoSwitch)
                  ListTile(
                    title: Text(
                      AppLocalizations.of(context)!.locationConfirmSwitch,
                    ),
                    leading: const Icon(Icons.help_outline_rounded),
                    onTap: () =>
                        cubit.setLocationConfirmSwitch(!location.confirmSwitch),
                    trailing: KitchenOwlSwitch(
                      value: location.confirmSwitch,
                      onChanged: cubit.setLocationConfirmSwitch,
                    ),
                  ),
              ],
            ],
          ),
        );
      },
    );
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
