import 'package:collection/collection.dart';
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
import 'package:kitchenowl/pages/household_update_page.dart';
import 'package:kitchenowl/pages/settings_server_user_page.dart';
import 'package:kitchenowl/pages/settings_user_page.dart';
import 'package:kitchenowl/kitchenowl.dart';

class MorePage extends StatelessWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user =
        (BlocProvider.of<AuthCubit>(context).state as Authenticated).user;
    final isOffline = App.isOffline;

    return CustomScrollView(
      primary: true,
      physics: const ClampingScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 64, 16, 16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              CircleAvatar(
                foregroundImage: user.image.isEmpty
                    ? null
                    : getImageProvider(
                        context,
                        user.image,
                      ),
                radius: 45,
                child: Text(user.name.substring(0, 1), textScaleFactor: 2),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  user.name,
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
              ),
            ]),
          ),
        ),
        BlocBuilder<SettingsCubit, SettingsState>(
          builder: (context, state) => SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ListTile(
                    title: Text(AppLocalizations.of(context)!.themeMode),
                    leading: const Icon(Icons.nights_stay_sharp),
                    contentPadding: const EdgeInsets.only(left: 20, right: 5),
                    horizontalTitleGap: 0,
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
                        horizontalTitleGap: 0,
                        contentPadding:
                            const EdgeInsets.only(left: 20, right: 0),
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
                      title:
                          Text(AppLocalizations.of(context)!.forceOfflineMode),
                      leading: const Icon(Icons.mobiledata_off_outlined),
                      horizontalTitleGap: 0,
                      contentPadding: const EdgeInsets.only(left: 20, right: 0),
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
                  Card(
                    child: ListTile(
                      title:
                          Text(AppLocalizations.of(context)!.householdSwitch),
                      leading: const Icon(Icons.swap_horiz_rounded),
                      minLeadingWidth: 16,
                      onTap: () => context.go("/household"),
                    ),
                  ),
                  if (!isOffline)
                    Row(
                      children: [
                        BlocBuilder<HouseholdCubit, HouseholdState>(
                          builder: ((context, state) {
                            if (!(state.household.member
                                    ?.firstWhereOrNull(
                                      (e) => user.id == e.id,
                                    )
                                    ?.hasAdminRights() ??
                                true)) return const SizedBox();

                            return Expanded(
                              child: Card(
                                child: ListTile(
                                  title: Text(
                                    AppLocalizations.of(context)!.household,
                                  ),
                                  leading: const Icon(Icons.house_rounded),
                                  minLeadingWidth: 16,
                                  onTap: () async {
                                    final res = await Navigator.of(
                                      context,
                                      rootNavigator: true,
                                    ).push<UpdateEnum>(
                                      MaterialPageRoute(
                                        builder: (ctx) => HouseholdUpdatePage(
                                          household: state.household,
                                        ),
                                      ),
                                    );
                                    if (res == UpdateEnum.deleted) return;
                                    BlocProvider.of<HouseholdCubit>(context)
                                        .refresh();
                                  },
                                ),
                              ),
                            );
                          }),
                        ),
                        if (user.hasServerAdminRights())
                          Expanded(
                            child: Card(
                              child: ListTile(
                                title:
                                    Text(AppLocalizations.of(context)!.server),
                                leading: const Icon(Icons.account_tree_rounded),
                                minLeadingWidth: 16,
                                onTap: () =>
                                    Navigator.of(context, rootNavigator: true)
                                        .push(
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const SettingsServerUserPage(),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  Row(
                    children: [
                      if (!isOffline)
                        Expanded(
                          child: Card(
                            child: ListTile(
                              shape: Theme.of(context).cardTheme.shape,
                              title: Text(AppLocalizations.of(context)!.user),
                              leading: const Icon(Icons.person),
                              minLeadingWidth: 16,
                              onTap: () =>
                                  Navigator.of(context, rootNavigator: true)
                                      .push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const SettingsUserPage(),
                                ),
                              ),
                            ),
                          ),
                        ),
                      Expanded(
                        child: Card(
                          child: ListTile(
                            title: Text(AppLocalizations.of(context)!.about),
                            leading: const Icon(Icons.privacy_tip_rounded),
                            minLeadingWidth: 16,
                            onTap: () => showAboutDialog(
                              context: context,
                              applicationVersion:
                                  Config.packageInfoSync?.version,
                              applicationLegalese:
                                  '\u{a9} ${AppLocalizations.of(context)!.appLegal}',
                              applicationIcon: ConstrainedBox(
                                constraints: const BoxConstraints.expand(
                                  width: 64,
                                  height: 64,
                                ),
                                child: Image.asset(
                                  'assets/icon/icon.png',
                                ),
                              ),
                              children: [
                                const SizedBox(height: 24),
                                Text(
                                  AppLocalizations.of(context)!.appDescription,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  LoadingTextButton(
                    onPressed: BlocProvider.of<AuthCubit>(context).logout,
                    icon: const Icon(Icons.logout),
                    child: Text(AppLocalizations.of(context)!.logout),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
