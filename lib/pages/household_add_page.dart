import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/cubits/auth_cubit.dart';
import 'package:kitchenowl/cubits/household_add_update/household_add_cubit.dart';
import 'package:kitchenowl/enums/update_enum.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/models/member.dart';
import 'package:kitchenowl/models/user.dart';
import 'package:kitchenowl/pages/user_search_page.dart';
import 'package:kitchenowl/widgets/settings_household/sliver_household_feature_settings.dart';
import 'package:kitchenowl/widgets/user_list_tile.dart';

class HouseholdAddPage extends StatefulWidget {
  final String? locale;

  const HouseholdAddPage({super.key, this.locale});

  @override
  State<HouseholdAddPage> createState() => _HouseholdAddPageState();
}

class _HouseholdAddPageState extends State<HouseholdAddPage> {
  late final HouseholdAddCubit cubit;

  @override
  void initState() {
    super.initState();
    cubit = HouseholdAddCubit(
      widget.locale,
      BlocProvider.of<AuthCubit>(context).getUser()!,
    );
  }

  @override
  void dispose() {
    cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: cubit,
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.householdNew),
        ),
        body: CustomScrollView(
          primary: true,
          slivers: [
            SliverList(
              delegate: SliverChildListDelegate([
                BlocBuilder<HouseholdAddCubit, HouseholdAddState>(
                  bloc: cubit,
                  buildWhen: (previous, current) =>
                      previous.image != current.image,
                  builder: (context, state) => ImageSelector(
                    image: state.image,
                    setImage: cubit.setImage,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: TextField(
                    onChanged: (s) => cubit.setName(s),
                    textInputAction: TextInputAction.next,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.name,
                    ),
                  ),
                ),
              ]),
            ),
            const SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverHouseholdFeatureSettings<HouseholdAddCubit,
                  HouseholdAddState>(
                askConfirmation: false,
                languageCanBeChanged: true,
                showProfile: false,
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${AppLocalizations.of(context)!.members}:',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    LoadingIconButton(
                      icon: const Icon(Icons.add),
                      tooltip: AppLocalizations.of(context)!.memberAdd,
                      onPressed: () async {
                        final user = await Navigator.of(context)
                            .push<User>(MaterialPageRoute(
                          builder: (ctx) => UserSearchPage(
                            disabledUser: cubit.state.members,
                          ),
                        ));
                        if (user == null) return;

                        return cubit.addMember(Member.fromUser(user));
                      },
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
            ),
            BlocBuilder<HouseholdAddCubit, HouseholdAddState>(
              bloc: cubit,
              buildWhen: (previous, current) =>
                  previous.members.length != current.members.length,
              builder: (context, state) => SliverList(
                delegate: SliverChildBuilderDelegate(
                  childCount: state.members.length,
                  (context, i) => Dismissible(
                    key: ValueKey<Member>(state.members[i]),
                    confirmDismiss: (direction) async {
                      return !state.members[i].hasAdminRights();
                    },
                    onDismissed: (direction) {
                      cubit.removeMember(state.members[i]);
                    },
                    child: UserListTile(
                      user: state.members[i],
                      markSelf: true,
                      trailing: state.members[i].hasAdminRights()
                          ? Icon(
                              Icons.admin_panel_settings_rounded,
                              color: state.members[i].owner
                                  ? Colors.redAccent
                                  : null,
                            )
                          : null,
                    ),
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverToBoxAdapter(
                child: BlocBuilder<HouseholdAddCubit, HouseholdAddState>(
                  bloc: cubit,
                  builder: (context, state) => LoadingElevatedButton(
                    onPressed: state.isValid()
                        ? () async {
                            await cubit.create();
                            if (!mounted) return;
                            Navigator.of(context).pop(UpdateEnum.updated);
                          }
                        : null,
                    child: Text(
                      AppLocalizations.of(context)!.add,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
