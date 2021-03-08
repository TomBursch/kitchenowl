import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/config.dart';
import 'package:kitchenowl/cubits/auth_cubit.dart';
import 'package:kitchenowl/cubits/settings_cubit.dart';
import 'package:kitchenowl/pages/settings_server_page.dart';
import 'package:kitchenowl/pages/settings_shoppinglists_page.dart';
import 'package:kitchenowl/pages/settings_user_page.dart';
import 'package:kitchenowl/kitchenowl.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: CustomScrollView(
        physics: ClampingScrollPhysics(),
        slivers: [
          SliverFillRemaining(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 64, 16, 16),
              child: Column(
                children: [
                  Icon(
                    Icons.account_circle_rounded,
                    size: 90,
                    color: Theme.of(context).accentColor,
                  ),
                  Text(
                    (BlocProvider.of<AuthCubit>(context).state as Authenticated)
                        .user
                        .name,
                    style: Theme.of(context).textTheme.headline5,
                    textAlign: TextAlign.center,
                  ),
                  Spacer(),
                  ListTile(
                    title: Text(AppLocalizations.of(context).darkmode),
                    leading: Icon(Icons.nights_stay_sharp),
                    contentPadding: EdgeInsets.only(left: 20, right: 0),
                    trailing: Transform.scale(
                      scale: 0.9,
                      child: CupertinoSwitch(
                        value: Theme.of(context).brightness == Brightness.dark,
                        activeColor: Theme.of(context).accentColor,
                        onChanged: (value) {
                          BlocProvider.of<SettingsCubit>(context).setTheme(
                              value ? ThemeMode.dark : ThemeMode.light);
                        },
                      ),
                    ),
                  ),
                  Card(
                    child: ListTile(
                      title: Text(AppLocalizations.of(context).shoppingLists),
                      leading: Icon(Icons.shopping_bag),
                      trailing: Icon(Icons.arrow_right_rounded),
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => SettingsShoppinglistsPage())),
                    ),
                  ),
                  Card(
                    child: ListTile(
                      title: Text(AppLocalizations.of(context).user),
                      leading: Icon(Icons.person),
                      trailing: Icon(Icons.arrow_right_rounded),
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => SettingsUserPage())),
                    ),
                  ),
                  if ((BlocProvider.of<AuthCubit>(context).state
                          as Authenticated)
                      .user
                      .owner)
                    Card(
                      child: ListTile(
                        title: Text(AppLocalizations.of(context).server),
                        leading: Icon(Icons.account_tree_rounded),
                        trailing: Icon(Icons.arrow_right_rounded),
                        onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (context) => SettingsServerPage())),
                      ),
                    ),
                  Card(
                    child: ListTile(
                      title: Text(AppLocalizations.of(context).about),
                      leading: Icon(Icons.privacy_tip_rounded),
                      trailing: Icon(Icons.arrow_right_rounded),
                      onTap: () => showAboutDialog(
                          context: context,
                          applicationVersion: Config.packageInfo?.version,
                          applicationLegalese:
                              '\u{a9} ' + AppLocalizations.of(context).appLegal,
                          applicationIcon: ConstrainedBox(
                            constraints:
                                BoxConstraints.expand(width: 64, height: 64),
                            child: Image.asset(
                              'assets/icon/icon.png',
                            ),
                          ),
                          children: [
                            const SizedBox(height: 24),
                            Text(
                              AppLocalizations.of(context).appDescription,
                            )
                          ]),
                    ),
                  ),
                  TextButton(
                    onPressed: () =>
                        BlocProvider.of<AuthCubit>(context).logout(),
                    child: Text(AppLocalizations.of(context).logout),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
