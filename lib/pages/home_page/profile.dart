import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/app.dart';
import 'package:kitchenowl/config.dart';
import 'package:kitchenowl/cubits/auth_cubit.dart';
import 'package:kitchenowl/cubits/settings_cubit.dart';
import 'package:kitchenowl/pages/settings_server_page.dart';
import 'package:kitchenowl/pages/settings_shoppinglists_page.dart';
import 'package:kitchenowl/pages/settings_user_page.dart';
import 'package:kitchenowl/kitchenowl.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({Key? key}) : super(key: key);

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
              Icon(
                Icons.account_circle_rounded,
                size: 90,
                color: Theme.of(context).colorScheme.secondary,
              ),
              Text(
                user.name,
                style: Theme.of(context).textTheme.headline5,
                textAlign: TextAlign.center,
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
                    trailing: DropdownButton(
                      value: state.themeMode,
                      items: [
                        DropdownMenuItem(
                          value: ThemeMode.light,
                          child: Text(AppLocalizations.of(context)!.themeLight),
                        ),
                        DropdownMenuItem(
                          value: ThemeMode.dark,
                          child: Text(AppLocalizations.of(context)!.themeDark),
                        ),
                        DropdownMenuItem(
                          value: ThemeMode.system,
                          child:
                              Text(AppLocalizations.of(context)!.themeSystem),
                        ),
                      ],
                      onChanged: (ThemeMode? value) {
                        if (value != null) {
                          BlocProvider.of<SettingsCubit>(context)
                              .setTheme(value);
                        }
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
                      contentPadding: const EdgeInsets.only(left: 20, right: 0),
                      trailing: KitchenOwlSwitch(
                        value: state.forcedOfflineMode,
                        onChanged: (value) =>
                            BlocProvider.of<SettingsCubit>(context)
                                .setForcedOfflineMode(value),
                      ),
                    ),
                  if (!isOffline && user.hasAdminRights())
                    Row(
                      children: [
                        Expanded(
                          child: Card(
                            clipBehavior: Clip.antiAlias,
                            child: ListTile(
                              title: Text(
                                AppLocalizations.of(context)!.shoppingLists,
                                maxLines: 1,
                              ),
                              leading: const Icon(Icons.shopping_bag),
                              minLeadingWidth: 16,
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const SettingsShoppinglistsPage(),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Card(
                            child: ListTile(
                              title: Text(AppLocalizations.of(context)!.server),
                              leading: const Icon(Icons.account_tree_rounded),
                              minLeadingWidth: 16,
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const SettingsServerPage(),
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
                              onTap: () => Navigator.of(context).push(
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
