import 'dart:io';

import 'package:dynamic_system_colors/dynamic_system_colors.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:kitchenowl/app.dart';
import 'package:kitchenowl/config.dart';
import 'package:kitchenowl/cubits/auth_cubit.dart';
import 'package:kitchenowl/cubits/server_info_cubit.dart';
import 'package:kitchenowl/cubits/settings_cubit.dart';
import 'package:kitchenowl/enums/update_enum.dart';
import 'package:kitchenowl/helpers/url_launcher.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/models/household.dart';
import 'package:kitchenowl/pages/analytics_page.dart';
import 'package:kitchenowl/pages/household_member_page.dart';
import 'package:kitchenowl/pages/household_update_page.dart';
import 'package:kitchenowl/pages/reports_list_page.dart';
import 'package:kitchenowl/pages/settings_server_user_page.dart';
import 'package:kitchenowl/services/api/api_service.dart';
import 'package:kitchenowl/services/notification_service.dart';
import 'package:kitchenowl/styles/colors.dart';
import 'package:kitchenowl/widgets/settings/color_button.dart';
import 'package:kitchenowl/widgets/sliver_expansion_tile.dart';
import 'package:kitchenowl/widgets/user_list_tile.dart';
import 'package:sliver_tools/sliver_tools.dart';
import 'package:unifiedpush_ui/unifiedpush_ui.dart';

class SettingsPage extends StatefulWidget {
  final Household? household;

  const SettingsPage({
    super.key,
    this.household,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    if (BlocProvider.of<AuthCubit>(context).state is! Authenticated) {
      return const SizedBox();
    }

    final user =
        (BlocProvider.of<AuthCubit>(context).state as Authenticated).user;
    final isOffline = App.isOffline;

    final String privacyPolicyUrl = (App.serverInfo is ConnectedServerInfoState)
        ? (App.serverInfo as ConnectedServerInfoState).privacyPolicyUrl ??
            "https://kitchenowl.org/privacy"
        : "https://kitchenowl.org/privacy";

    final String termsUrl = (App.serverInfo is ConnectedServerInfoState)
        ? (App.serverInfo as ConnectedServerInfoState).termsUrl ??
            "https://kitchenowl.org/terms"
        : "https://kitchenowl.org/terms";

    final body = CustomScrollView(
      primary: true,
      slivers: [
        SliverAppBar(
          title: Text(AppLocalizations.of(context)!.settings),
          pinned: true,
          leading: Navigator.canPop(context)
              ? null
              : BackButton(
                  onPressed: () => context.go("/"),
                ),
        ),
        SliverCrossAxisConstrained(
          maxCrossAxisExtent: 1600,
          child: SliverList(
            delegate: SliverChildListDelegate([
              Theme(
                data: Theme.of(context),
                child: BlocBuilder<AuthCubit, AuthState>(
                  builder: (context, state) {
                    if (state is! Authenticated) return const SizedBox();

                    return UserListTile(
                      user: state.user,
                      trailing: const Icon(Icons.arrow_forward_ios_rounded),
                      onTap: !isOffline
                          ? () async {
                              final res =
                                  await context.push("/settings/account");
                              if (res == UpdateEnum.updated) {
                                BlocProvider.of<AuthCubit>(context)
                                    .refreshUser();
                              }
                            }
                          : null,
                    );
                  },
                ),
              ),
              const Divider(),
            ]),
          ),
        ),
        SliverCrossAxisConstrained(
          maxCrossAxisExtent: 1600,
          child: BlocBuilder<SettingsCubit, SettingsState>(
            builder: (context, state) => SliverList(
              delegate: SliverChildListDelegate([
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 2),
                  child: Text(
                    AppLocalizations.of(context)!.general.toUpperCase(),
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ),
                ListTile(
                  title: Text(AppLocalizations.of(context)!.themeMode),
                  leading: const Icon(Icons.nights_stay_sharp),
                  titleAlignment: ListTileTitleAlignment.top,
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: SegmentedButton(
                      selected: {state.themeMode},
                      segments: [
                        ButtonSegment(
                          value: ThemeMode.system,
                          icon: const Icon(Icons.brightness_medium_outlined),
                          label:
                              Text(AppLocalizations.of(context)!.themeSystem),
                        ),
                        ButtonSegment(
                          value: ThemeMode.light,
                          icon: const Icon(Icons.light_mode_rounded),
                          label: Text(AppLocalizations.of(context)!.themeLight),
                        ),
                        ButtonSegment(
                          value: ThemeMode.dark,
                          icon: const Icon(Icons.dark_mode_rounded),
                          label: Text(AppLocalizations.of(context)!.themeDark),
                        ),
                      ],
                      onSelectionChanged: (Set<ThemeMode> value) {
                        BlocProvider.of<SettingsCubit>(context)
                            .setTheme(value.first);
                      },
                    ),
                  ),
                ),
                DynamicColorBuilder(builder: (dynamicLight, dynamicDark) {
                  if (dynamicLight != null && dynamicDark != null) {
                    return ListTile(
                      title: Text(
                        AppLocalizations.of(context)!.dynamicAccentColor,
                      ),
                      onTap: () => BlocProvider.of<SettingsCubit>(context)
                          .setUseDynamicAccentColor(!state.dynamicAccentColor),
                      leading: const Icon(Icons.color_lens_rounded),
                      trailing: KitchenOwlSwitch(
                        value: state.dynamicAccentColor,
                        onChanged: (value) =>
                            BlocProvider.of<SettingsCubit>(context)
                                .setUseDynamicAccentColor(value),
                      ),
                    );
                  }

                  return ListTile(
                    title: Text(
                      AppLocalizations.of(context)!.dynamicAccentColor,
                    ),
                    leading: const Icon(Icons.color_lens_rounded),
                  );
                }),
                if (!state.dynamicAccentColor)
                  SingleChildScrollView(
                    primary: false,
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        const SizedBox(width: 52),
                        ColorButton(
                          color: AppColors.green,
                          selected: state.accentColor == null,
                          onTap: () => BlocProvider.of<SettingsCubit>(context)
                              .setAccentColor(null),
                        ),
                        for (final color in AppColors.accentColorOptions)
                          ColorButton(
                            color: color,
                            selected: state.accentColor?.value == color.value,
                            onTap: () => BlocProvider.of<SettingsCubit>(context)
                                .setAccentColor(color),
                          ),
                      ],
                    ),
                  ),
                ListTile(
                  title: Text(AppLocalizations.of(context)!.shoppingListStyle),
                  leading: const Icon(Icons.shopping_bag_rounded),
                  titleAlignment: ListTileTitleAlignment.top,
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: SegmentedButton(
                      selected: {state.shoppingListListView},
                      segments: [
                        ButtonSegment(
                          value: false,
                          icon: const Icon(Icons.grid_view_rounded),
                          label: Text(AppLocalizations.of(context)!.grid),
                        ),
                        ButtonSegment(
                          value: true,
                          icon: const Icon(Icons.list_rounded),
                          label: Text(AppLocalizations.of(context)!.list),
                        ),
                      ],
                      onSelectionChanged: (Set<bool> value) {
                        BlocProvider.of<SettingsCubit>(context)
                            .setShoppingListListView(value.first);
                      },
                    ),
                  ),
                ),
                if (!state.shoppingListListView)
                  ListTile(
                    title: Text(AppLocalizations.of(context)!.itemSize),
                    leading: const Icon(Icons.grid_view_rounded),
                    titleAlignment: ListTileTitleAlignment.top,
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: SegmentedButton(
                        selected: {state.gridSize},
                        segments: [
                          ButtonSegment(
                            value: GridSize.small,
                            icon: const Icon(Icons.grid_4x4_rounded),
                            label: Text(AppLocalizations.of(context)!.smaller),
                          ),
                          ButtonSegment(
                            value: GridSize.normal,
                            icon: const Icon(Icons.grid_3x3_rounded),
                            label:
                                Text(AppLocalizations.of(context)!.defaultWord),
                          ),
                          ButtonSegment(
                            value: GridSize.large,
                            icon: const Icon(Icons.crop_square_rounded),
                            label: Text(AppLocalizations.of(context)!.larger),
                          ),
                        ],
                        onSelectionChanged: (Set<GridSize> value) {
                          BlocProvider.of<SettingsCubit>(context)
                              .setGridSize(value.first);
                        },
                      ),
                    ),
                  ),
                ListTile(
                  title:
                      Text(AppLocalizations.of(context)!.itemRemoveInteraction),
                  leading: const Icon(Icons.touch_app_rounded),
                  titleAlignment: ListTileTitleAlignment.top,
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: SegmentedButton(
                      selected: {state.shoppingListTapToRemove},
                      segments: [
                        ButtonSegment(
                          value: true,
                          icon: const Icon(Icons.touch_app_rounded),
                          label: Text(AppLocalizations.of(context)!.tap),
                        ),
                        ButtonSegment(
                          value: false,
                          icon: const Icon(Icons.done_all_rounded),
                          label: Text(AppLocalizations.of(context)!.confirm),
                        ),
                      ],
                      onSelectionChanged: (Set<bool> value) {
                        BlocProvider.of<SettingsCubit>(context)
                            .setShoppingListTapToRemove(value.first);
                      },
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ),
        SliverCrossAxisConstrained(
          maxCrossAxisExtent: 1600,
          child: BlocBuilder<SettingsCubit, SettingsState>(
            builder: (context, state) => SliverExpansionTile(
              startCollapsed: true,
              titleCrossAxisAlignment: CrossAxisAlignment.center,
              title: Row(
                children: [
                  const SizedBox(width: 16),
                  Icon(Icons.more_horiz_rounded),
                  const SizedBox(width: 12),
                  Text(
                    AppLocalizations.of(context)!.more,
                    style: TextTheme.of(context).labelLarge,
                  ),
                ],
              ),
              sliver: SliverList.list(
                children: [
                  ListTile(
                    title: Text(
                      AppLocalizations.of(context)!.rememberLastShoppingList,
                    ),
                    leading: const Icon(Icons.restore_rounded),
                    onTap: () => BlocProvider.of<SettingsCubit>(context)
                        .setRestoreLastShoppinglist(
                      !BlocProvider.of<SettingsCubit>(context)
                          .state
                          .restoreLastShoppingList,
                    ),
                    trailing: KitchenOwlSwitch(
                      value: state.restoreLastShoppingList,
                      onChanged: (value) =>
                          BlocProvider.of<SettingsCubit>(context)
                              .setRestoreLastShoppinglist(value),
                    ),
                  ),
                  ListTile(
                    title: Text(
                      AppLocalizations.of(context)!.itemsRecent,
                    ),
                    leading: const Icon(Icons.numbers_rounded),
                    trailing: NumberSelector(
                      value: state.recentItemsCount,
                      setValue: BlocProvider.of<SettingsCubit>(context)
                          .setRecentItemsCount,
                      defaultValue: 9,
                      lowerBound: 0,
                      upperBound: 120,
                    ),
                  ),
                  ListTile(
                    title: Text(
                      AppLocalizations.of(context)!.recentItemsCategorize,
                    ),
                    leading: const Icon(Icons.category_rounded),
                    onTap: () => BlocProvider.of<SettingsCubit>(context)
                        .setRecentItemsCategorize(
                      !BlocProvider.of<SettingsCubit>(context)
                          .state
                          .recentItemsCategorize,
                    ),
                    trailing: KitchenOwlSwitch(
                      value: state.recentItemsCategorize,
                      onChanged: (value) =>
                          BlocProvider.of<SettingsCubit>(context)
                              .setRecentItemsCategorize(value),
                    ),
                  ),
                  if (!kIsWeb)
                    ListTile(
                      title: Text(
                        AppLocalizations.of(context)!.forceOfflineMode,
                      ),
                      leading: const Icon(Icons.mobiledata_off_outlined),
                      onTap: () => BlocProvider.of<AuthCubit>(context)
                          .setForcedOfflineMode(
                        !BlocProvider.of<AuthCubit>(context)
                            .state
                            .forcedOfflineMode,
                      ),
                      trailing: BlocBuilder<AuthCubit, AuthState>(
                        buildWhen: (previous, current) =>
                            previous.forcedOfflineMode !=
                            current.forcedOfflineMode,
                        builder: (context, state) => KitchenOwlSwitch(
                          value: state.forcedOfflineMode,
                          onChanged: (value) =>
                              BlocProvider.of<AuthCubit>(context)
                                  .setForcedOfflineMode(value),
                        ),
                      ),
                    ),
                  if (!kIsWeb && (Platform.isAndroid || Platform.isLinux))
                    ListTile(
                      title: Text(
                        AppLocalizations.of(context)!.server,
                      ),
                      leading: const Icon(Icons.notifications_rounded),
                      onTap: () async {
                        state.notificationDistributor != null
                            ? await NotificationService.getInstance()
                                .unregister()
                            : await UnifiedPushUi(
                                context: context,
                                instances: [NotificationService.instanceName],
                                unifiedPushFunctions:
                                    NotificationService.getInstance(),
                                showNoDistribDialog: true,
                                onNoDistribDialogDismissed: () {},
                              ).registerAppWithDialog();
                        BlocProvider.of<SettingsCubit>(context)
                            .refreshNotificationDistributor();
                      },
                      trailing: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Text(state.notificationDistributor ??
                            AppLocalizations.of(context)!.none),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        if (widget.household != null)
          SliverCrossAxisConstrained(
            maxCrossAxisExtent: 1600,
            child: SliverList(
              delegate: SliverChildListDelegate([
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 2),
                  child: Text(
                    AppLocalizations.of(context)!.household.toUpperCase(),
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ),
                ListTile(
                  title: Text(AppLocalizations.of(context)!.householdSwitch),
                  leading: const Icon(Icons.swap_horiz_rounded),
                  onTap: () => context.go("/household"),
                ),
                if (!isOffline)
                  ListTile(
                    title: Text(AppLocalizations.of(context)!.householdLeave),
                    leading: const Icon(Icons.person_remove_rounded),
                    onTap: () async {
                      final confirm = await askForConfirmation(
                        context: context,
                        title: Text(
                          AppLocalizations.of(context)!.householdLeave,
                        ),
                        content: Text(
                          AppLocalizations.of(context)!
                              .householdLeaveConfirmation(
                            widget.household!.name,
                          ),
                        ),
                        confirmText: AppLocalizations.of(context)!.yes,
                      );
                      if (confirm) {
                        ApiService.getInstance().removeHouseholdMember(
                          widget.household!,
                          BlocProvider.of<AuthCubit>(context).getUser()!,
                        );
                        context.go("/household");
                      }
                    },
                  ),
                ListTile(
                  title: Text(
                    AppLocalizations.of(context)!.members,
                  ),
                  leading: const Icon(Icons.group_rounded),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (ctx) => HouseholdMemberPage(
                        household: widget.household!,
                      ),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        if (!isOffline &&
            widget.household != null &&
            widget.household!.hasAdminRights(user))
          SliverCrossAxisConstrained(
            maxCrossAxisExtent: 1600,
            child: SliverList(
              delegate: SliverChildListDelegate([
                ListTile(
                  title: Text(
                    AppLocalizations.of(context)!.settings,
                  ),
                  leading: const Icon(Icons.house_rounded),
                  onTap: () => Navigator.of(context).push<UpdateEnum>(
                    MaterialPageRoute(
                      builder: (ctx) => HouseholdUpdatePage(
                        household: widget.household!,
                      ),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        if (!isOffline && user.hasServerAdminRights())
          SliverCrossAxisConstrained(
            maxCrossAxisExtent: 1600,
            child: SliverList(
              delegate: SliverChildListDelegate([
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 2),
                  child: Text(
                    "${AppLocalizations.of(context)!.server.toUpperCase()} (${Uri.parse(ApiService.getInstance().baseUrl).authority})",
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ),
                ListTile(
                  title: Text(
                    AppLocalizations.of(context)!.users,
                  ),
                  leading: const Icon(Icons.groups_2_rounded),
                  onTap: () => Navigator.of(context, rootNavigator: true).push(
                    MaterialPageRoute(
                      builder: (context) => const SettingsServerUserPage(),
                    ),
                  ),
                ),
                ListTile(
                  title: const Text("Analytics"),
                  leading: const Icon(Icons.analytics_rounded),
                  onTap: () => Navigator.of(context, rootNavigator: true).push(
                    MaterialPageRoute(
                      builder: (context) => const AnalyticsPage(),
                    ),
                  ),
                ),
                ListTile(
                  title: const Text("Reports"),
                  leading: const Icon(Icons.report_rounded),
                  onTap: () => Navigator.of(context, rootNavigator: true).push(
                    MaterialPageRoute(
                      builder: (context) => const ReportsListPage(),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        SliverCrossAxisConstrained(
          maxCrossAxisExtent: 1600,
          child: SliverList(
            delegate: SliverChildListDelegate([
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 2),
                child: Text(
                  AppLocalizations.of(context)!.about.toUpperCase(),
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ),
              ListTile(
                title: const Text("GitHub"),
                leading: const Icon(Icons.source_rounded),
                onTap: () => openUrl(
                  context,
                  "https://github.com/tombursch/kitchenowl",
                ),
              ),
              ListTile(
                title: Text(AppLocalizations.of(context)!.reportIssue),
                leading: const Icon(Icons.bug_report_rounded),
                onTap: () => openUrl(
                  context,
                  "https://github.com/TomBursch/kitchenowl/issues/new/choose",
                ),
              ),
              ListTile(
                title: Text(AppLocalizations.of(context)!.helpTranslate),
                leading: const Icon(Icons.translate_rounded),
                onTap: () => openUrl(
                  context,
                  "https://hosted.weblate.org/engage/kitchenowl",
                ),
              ),
              if (kIsWeb || !Platform.isIOS)
                ListTile(
                  title: Text(AppLocalizations.of(context)!.supportDevelopment),
                  leading: const Icon(Icons.volunteer_activism_rounded),
                  onTap: () => openUrl(
                    context,
                    "https://liberapay.com/tombursch",
                  ),
                ),
              ListTile(
                title: Text(AppLocalizations.of(context)!.terms),
                leading: const Icon(Icons.attach_file_rounded),
                onTap: () => openUrl(context, termsUrl),
              ),
              ListTile(
                title: Text(AppLocalizations.of(context)!.privacyPolicy),
                leading: const Icon(Icons.privacy_tip_rounded),
                onTap: () => openUrl(context, privacyPolicyUrl),
              ),
              ListTile(
                title:
                    Text(MaterialLocalizations.of(context).licensesPageTitle),
                leading: const Icon(Icons.info_rounded),
                onTap: () => showLicensePage(
                  context: context,
                  applicationVersion: Config.packageInfoSync?.version,
                  applicationLegalese:
                      '\u{a9} 2025 KitchenOwl\nKitchenOwl is Free Software: You can use, study share and improve it at your will. Specifically you can redistribute and/or modify it under the terms of the AGPL-3.0 License.',
                ),
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: LoadingTextButton(
                    onPressed: BlocProvider.of<AuthCubit>(context).logout,
                    icon: const Icon(Icons.logout),
                    style: const ButtonStyle(
                      foregroundColor: WidgetStatePropertyAll(Colors.redAccent),
                      iconColor: WidgetStatePropertyAll(Colors.redAccent),
                    ),
                    child: Text(AppLocalizations.of(context)!.logout),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
                child: SelectableText(
                  "v${Config.packageInfoSync?.version} (${Config.packageInfoSync?.buildNumber})${App.serverInfo is ConnectedServerInfoState ? " | Server v${(App.serverInfo as ConnectedServerInfoState).version}" : ""}",
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.color
                            ?.withAlpha(76),
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
              Text(
                '\u{a9} 2025 KitchenOwl',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.color
                          ?.withAlpha(76),
                    ),
                textAlign: TextAlign.center,
              ),
              SizedBox(
                height: MediaQuery.paddingOf(context).bottom + 4,
              ),
            ]),
          ),
        ),
      ],
    );

    return Theme(
      data: Theme.of(context).copyWith(
        listTileTheme: Theme.of(context).listTileTheme.copyWith(
              contentPadding: const EdgeInsets.only(left: 16, right: 5),
            ),
      ),
      child: Scaffold(
        body: Align(
          alignment: Alignment.topCenter,
          child: body,
        ),
      ),
    );
  }
}
