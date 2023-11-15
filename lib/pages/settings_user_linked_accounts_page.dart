import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/cubits/settings_user_cubit.dart';
import 'package:kitchenowl/enums/oidc_provider.dart';
import 'package:kitchenowl/kitchenowl.dart';

class SettingsLinkedAccountsPage extends StatelessWidget {
  final List<OIDCProivder> oidcProvider;
  final SettingsUserCubit cubit;

  const SettingsLinkedAccountsPage(
      {super.key, required this.cubit, required this.oidcProvider});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.accountsLinked),
      ),
      body: BlocBuilder<SettingsUserCubit, SettingsUserState>(
        bloc: cubit,
        buildWhen: (prev, curr) => prev.user?.oidcLinks != curr.user?.oidcLinks,
        builder: (context, state) => CustomScrollView(
          slivers: [
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  return ListTile(
                    leading: oidcProvider[i].toIcon(context),
                    title: Text(oidcProvider[i].toLocalizedString()),
                    trailing: (state.user?.oidcLinks
                                .contains(oidcProvider[i]) ??
                            false)
                        ? LoadingElevatedButton(
                            child: Text(AppLocalizations.of(context)!.unlink),
                          )
                        : LoadingElevatedButton(
                            onPressed: (oidcProvider[i] != OIDCProivder.apple ||
                                    (!kIsWeb &&
                                        (Platform.isIOS || Platform.isMacOS)))
                                ? () => oidcProvider[i].login(context)
                                : null,
                            child: Text(AppLocalizations.of(context)!.link),
                          ),
                  );
                },
                childCount: oidcProvider.length,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
