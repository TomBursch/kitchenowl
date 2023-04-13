import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
import 'package:kitchenowl/pages/household_update_page.dart';
import 'package:kitchenowl/pages/settings_server_user_page.dart';
import 'package:kitchenowl/pages/settings_user_page.dart';
import 'package:kitchenowl/services/api/api_service.dart';
import 'package:kitchenowl/widgets/user_list_tile.dart';

class ProfilePage extends StatelessWidget {
  final Household? household;

  const ProfilePage({super.key, this.household});

  @override
  Widget build(BuildContext context) {
    final user =
        (BlocProvider.of<AuthCubit>(context).state as Authenticated).user;
    final isOffline = App.isOffline;

    return Theme(
      data: Theme.of(context).copyWith(
        listTileTheme: Theme.of(context).listTileTheme.copyWith(
              contentPadding: const EdgeInsets.only(left: 20, right: 5),
              horizontalTitleGap: 0,
            ),
      ),
      child: Scaffold(
        body: CustomScrollView(
          primary: true,
          slivers: [
            SliverAppBar(title: Text(AppLocalizations.of(context)!.profile)),
            SliverList(
              delegate: SliverChildListDelegate([
                Theme(
                  data: Theme.of(context),
                  child: UserListTile(
                    user: user,
                    trailing: const Icon(Icons.arrow_forward_ios_rounded),
                    onTap: () =>
                        Navigator.of(context, rootNavigator: true).push(
                      MaterialPageRoute(
                        builder: (context) => const SettingsUserPage(),
                      ),
                    ),
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
                      AppLocalizations.of(context)!.features.toUpperCase(),
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
                          label:
                              Text(AppLocalizations.of(context)!.themeSystem),
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
                ]),
              ),
            ),
            SliverList(
              delegate: SliverChildListDelegate([
                if (household != null)
                  Card(
                    child: ListTile(
                      title:
                          Text(AppLocalizations.of(context)!.householdSwitch),
                      leading: const Icon(Icons.swap_horiz_rounded),
                      onTap: () => context.go("/household"),
                    ),
                  ),
                if (!isOffline)
                  Row(
                    children: [
                      if (household != null)
                        Expanded(
                          child: Card(
                            child: ListTile(
                              title: Text(
                                AppLocalizations.of(context)!.household,
                              ),
                              leading: const Icon(Icons.house_rounded),
                              onTap: () async {
                                final res = await Navigator.of(
                                  context,
                                  rootNavigator: true,
                                ).push<UpdateEnum>(
                                  MaterialPageRoute(
                                    builder: (ctx) => HouseholdUpdatePage(
                                      household: household!,
                                    ),
                                  ),
                                );
                                if (res == UpdateEnum.deleted) return;
                                BlocProvider.of<HouseholdCubit>(context)
                                    .refresh();
                              },
                            ),
                          ),
                        ),
                    ],
                  ),
              ]),
            ),
            if (user.hasServerAdminRights())
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
                    onTap: () =>
                        Navigator.of(context, rootNavigator: true).push(
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
                  leading: const Icon(Icons.source_rounded), //TODO
                  onTap: () => openUrl(
                    context,
                    "https://github.com/tombursch/kitchenowl",
                  ),
                ),
                ListTile(
                  title: Text(AppLocalizations.of(context)!.about), //TODO
                  leading: const Icon(Icons.bug_report_rounded),
                  onTap: () => openUrl(
                    context,
                    "https://github.com/TomBursch/kitchenowl/issues/new/choose",
                  ),
                ),
                ListTile(
                  title: Text(AppLocalizations.of(context)!.about), //TODO
                  leading: const Icon(Icons.privacy_tip_rounded),
                  onTap: () => openUrl(
                    context,
                    "https://tombursch.github.io/kitchenowl/about/app-privacy-policy/",
                  ),
                ),
                ListTile(
                  title:
                      Text(MaterialLocalizations.of(context).licensesPageTitle),
                  leading: const Icon(Icons.info_rounded),
                  onTap: () => showLicensePage(
                    context: context,
                    applicationVersion: Config.packageInfoSync?.version,
                    applicationLegalese:
                        '\u{a9} ${AppLocalizations.of(context)!.appLegal}',
                  ),
                ),
                LoadingTextButton(
                  onPressed: BlocProvider.of<AuthCubit>(context).logout,
                  icon: const Icon(Icons.logout),
                  style: const ButtonStyle(
                    foregroundColor: MaterialStatePropertyAll(Colors.redAccent),
                  ),
                  child: Text(AppLocalizations.of(context)!.logout),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 16, 8, 4),
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
              ]),
            ),
          ],
        ),
      ),
    );
  }
}
