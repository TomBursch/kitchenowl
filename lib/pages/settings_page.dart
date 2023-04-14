import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:kitchenowl/app.dart';
import 'package:kitchenowl/config.dart';
import 'package:kitchenowl/cubits/auth_cubit.dart';
import 'package:kitchenowl/cubits/household_cubit.dart';
import 'package:kitchenowl/cubits/settings_cubit.dart';
import 'package:kitchenowl/enums/update_enum.dart';
import 'package:kitchenowl/helpers/url_launcher.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/models/household.dart';
import 'package:kitchenowl/pages/household_member_page.dart';
import 'package:kitchenowl/pages/household_update_page.dart';
import 'package:kitchenowl/pages/settings_server_user_page.dart';
import 'package:kitchenowl/pages/settings_user_page.dart';
import 'package:kitchenowl/services/api/api_service.dart';
import 'package:kitchenowl/widgets/user_list_tile.dart';

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

    final body = CustomScrollView(
      primary: true,
      slivers: [
        SliverAppBar(
          title: Text(AppLocalizations.of(context)!.settings),
          pinned: true,
        ),
        SliverList(
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
                                await Navigator.of(context, rootNavigator: true)
                                    .push<UpdateEnum>(MaterialPageRoute(
                              builder: (context) => const SettingsUserPage(),
                            ));
                            if (res == UpdateEnum.updated) {
                              BlocProvider.of<AuthCubit>(context).refreshUser();
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
        BlocBuilder<SettingsCubit, SettingsState>(
          builder: (context, state) => SliverList(
            delegate: SliverChildListDelegate([
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  AppLocalizations.of(context)!.general.toUpperCase(),
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ),
              ListTile(
                title: Text(AppLocalizations.of(context)!.themeMode),
                leading: const Icon(Icons.nights_stay_sharp),
                trailing: SegmentedButton(
                  selected: {state.themeMode},
                  segments: [
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
                    ButtonSegment(
                      value: ThemeMode.system,
                      icon: const Icon(Icons.brightness_medium_outlined),
                      label: Text(AppLocalizations.of(context)!.themeSystem),
                    ),
                  ],
                  onSelectionChanged: (Set<ThemeMode> value) {
                    BlocProvider.of<SettingsCubit>(context)
                        .setTheme(value.first);
                  },
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

                return const SizedBox();
              }),
              if (!kIsWeb)
                ListTile(
                  title: Text(
                    AppLocalizations.of(context)!.forceOfflineMode,
                  ),
                  leading: const Icon(Icons.mobiledata_off_outlined),
                  onTap: () =>
                      BlocProvider.of<AuthCubit>(context).setForcedOfflineMode(
                    !BlocProvider.of<AuthCubit>(context)
                        .state
                        .forcedOfflineMode,
                  ),
                  trailing: BlocBuilder<AuthCubit, AuthState>(
                    buildWhen: (previous, current) =>
                        previous.forcedOfflineMode != current.forcedOfflineMode,
                    builder: (context, state) => KitchenOwlSwitch(
                      value: state.forcedOfflineMode,
                      onChanged: (value) => BlocProvider.of<AuthCubit>(context)
                          .setForcedOfflineMode(value),
                    ),
                  ),
                ),
            ]),
          ),
        ),
        if (widget.household != null)
          SliverList(
            delegate: SliverChildListDelegate([
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
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
        if (!isOffline &&
            widget.household != null &&
            widget.household!.hasAdminRights(user))
          SliverList(
            delegate: SliverChildListDelegate([
              ListTile(
                title: Text(
                  AppLocalizations.of(context)!.settings,
                ),
                leading: const Icon(Icons.house_rounded),
                onTap: () async {
                  final res = await Navigator.of(context).push<UpdateEnum>(
                    MaterialPageRoute(
                      builder: (ctx) => HouseholdUpdatePage(
                        household: widget.household!,
                      ),
                    ),
                  );
                  if (!mounted || res == UpdateEnum.deleted) return;
                  BlocProvider.of<HouseholdCubit>(context).refresh();
                },
              ),
            ]),
          ),
        if (!isOffline && user.hasServerAdminRights())
          SliverList(
            delegate: SliverChildListDelegate([
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
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
            ]),
          ),
        SliverList(
          delegate: SliverChildListDelegate([
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                AppLocalizations.of(context)!.about.toUpperCase(),
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ),
            ListTile(
              title: const Text("GitHub"),
              leading: const Icon(FontAwesomeIcons.github),
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
              title: Text(AppLocalizations.of(context)!.privacyPolicy),
              leading: const Icon(Icons.privacy_tip_rounded),
              onTap: () => openUrl(
                context,
                "https://tombursch.github.io/kitchenowl/about/privacy",
              ),
            ),
            ListTile(
              title: Text(MaterialLocalizations.of(context).licensesPageTitle),
              leading: const Icon(Icons.info_rounded),
              onTap: () => showLicensePage(
                context: context,
                applicationVersion: Config.packageInfoSync?.version,
                applicationLegalese:
                    '\u{a9} ${AppLocalizations.of(context)!.appLegal}',
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: LoadingTextButton(
                  onPressed: BlocProvider.of<AuthCubit>(context).logout,
                  icon: const Icon(Icons.logout),
                  style: const ButtonStyle(
                    foregroundColor: MaterialStatePropertyAll(Colors.redAccent),
                  ),
                  child: Text(AppLocalizations.of(context)!.logout),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
              child: Text(
                "v${Config.packageInfoSync?.version} (${Config.packageInfoSync?.buildNumber})",
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.color
                          ?.withOpacity(.3),
                    ),
                textAlign: TextAlign.center,
              ),
            ),
            Text(
              '\u{a9}${AppLocalizations.of(context)!.appLegal}',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.color
                        ?.withOpacity(.3),
                  ),
              textAlign: TextAlign.center,
            ),
            SizedBox(
              height: MediaQuery.of(context).padding.bottom + 4,
            ),
          ]),
        ),
      ],
    );

    return Theme(
      data: Theme.of(context).copyWith(
        listTileTheme: Theme.of(context).listTileTheme.copyWith(
              contentPadding: const EdgeInsets.only(left: 20, right: 5),
              horizontalTitleGap: 8,
            ),
      ),
      child: Scaffold(
        body: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints.expand(width: 1600),
            child: body,
          ),
        ),
      ),
    );
  }
}
