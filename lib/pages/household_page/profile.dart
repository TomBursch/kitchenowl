import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:kitchenowl/cubits/auth_cubit.dart';
import 'package:kitchenowl/cubits/household_cubit.dart';
import 'package:kitchenowl/cubits/settings_cubit.dart';
import 'package:kitchenowl/kitchenowl.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user =
        (BlocProvider.of<AuthCubit>(context).state as Authenticated).user;

    final householdCubit = BlocProvider.of<HouseholdCubit>(context);

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
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 6),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!kIsWeb)
                    ListTile(
                      title:
                          Text(AppLocalizations.of(context)!.forceOfflineMode),
                      leading: const Icon(Icons.mobiledata_off_outlined),
                      horizontalTitleGap: 0,
                      contentPadding: const EdgeInsets.only(left: 20, right: 0),
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
                  Card(
                    child: ListTile(
                      title: Text(
                        AppLocalizations.of(context)!.householdSwitch,
                      ),
                      leading: const Icon(Icons.swap_horiz_rounded),
                      minLeadingWidth: 16,
                      onTap: () => context.go("/household"),
                    ),
                  ),
                  Card(
                    child: ListTile(
                      title: Text(
                        AppLocalizations.of(context)!.settings,
                      ),
                      leading: const Icon(Icons.manage_accounts_rounded),
                      minLeadingWidth: 16,
                      onTap: () => context.push(
                        "/settings",
                        extra: householdCubit.state.household,
                      ),
                    ),
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
