import 'package:flutter/cupertino.dart';
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
                  ListTile(
                    title: Text(AppLocalizations.of(context)!.forceOfflineMode),
                    leading: const Icon(Icons.mobiledata_off_outlined),
                    contentPadding: const EdgeInsets.only(left: 20, right: 0),
                    trailing: Transform.scale(
                      scale: 0.9,
                      child: CupertinoSwitch(
                        value: state.forcedOfflineMode,
                        activeColor: Theme.of(context).colorScheme.secondary,
                        onChanged: (value) =>
                            BlocProvider.of<SettingsCubit>(context)
                                .setForcedOfflineMode(value),
                      ),
                    ),
                  ),
                  if (!isOffline)
                    Card(
                      child: ListTile(
                        title:
                            Text(AppLocalizations.of(context)!.shoppingLists),
                        leading: const Icon(Icons.shopping_bag),
                        trailing: const Icon(Icons.arrow_right_rounded),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                const SettingsShoppinglistsPage(),
                          ),
                        ),
                      ),
                    ),
                  if (!isOffline)
                    Card(
                      child: ListTile(
                        title: Text(AppLocalizations.of(context)!.user),
                        leading: const Icon(Icons.person),
                        trailing: const Icon(Icons.arrow_right_rounded),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const SettingsUserPage(),
                          ),
                        ),
                      ),
                    ),
                  if (!isOffline && user.hasAdminRights())
                    Card(
                      child: ListTile(
                        title: Text(AppLocalizations.of(context)!.server),
                        leading: const Icon(Icons.account_tree_rounded),
                        trailing: const Icon(Icons.arrow_right_rounded),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const SettingsServerPage(),
                          ),
                        ),
                      ),
                    ),
                  Card(
                    child: ListTile(
                      title: Text(AppLocalizations.of(context)!.about),
                      leading: const Icon(Icons.privacy_tip_rounded),
                      trailing: const Icon(Icons.arrow_right_rounded),
                      onTap: () => showAboutDialog(
                        context: context,
                        applicationVersion: Config.packageInfo?.version,
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
                  TextButton(
                    onPressed: () =>
                        BlocProvider.of<AuthCubit>(context).logout(),
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
