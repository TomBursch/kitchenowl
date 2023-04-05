import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/cubits/household_add_update/household_update_cubit.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/models/member.dart';
import 'package:kitchenowl/widgets/user_list_tile.dart';

class UpdateMemberBottomSheet extends StatefulWidget {
  final Member member;

  const UpdateMemberBottomSheet({super.key, required this.member});

  @override
  State<UpdateMemberBottomSheet> createState() =>
      _UpdateMemberBottomSheetState();
}

class _UpdateMemberBottomSheetState extends State<UpdateMemberBottomSheet> {
  late bool isAdmin;

  @override
  void initState() {
    super.initState();
    isAdmin = widget.member.hasAdminRights();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          UserListTile(
            user: widget.member,
          ),
          const Divider(),
          ListTile(
            title: Text(AppLocalizations.of(context)!.admin),
            leading: const Icon(
              Icons.admin_panel_settings_rounded,
            ),
            trailing: KitchenOwlSwitch(
              value: isAdmin,
              onChanged: widget.member.owner
                  ? null
                  : (v) {
                      BlocProvider.of<HouseholdUpdateCubit>(context)
                          .putMember(widget.member.copyWith(admin: v));
                      setState(() {
                        isAdmin = v;
                      });
                    },
            ),
          ),
          ElevatedButton(
            onPressed: widget.member.owner
                ? null
                : () {
                    BlocProvider.of<HouseholdUpdateCubit>(context)
                        .removeMember(widget.member);
                    Navigator.of(context).pop();
                  },
            child: Text(
              AppLocalizations.of(context)!.memberRemove,
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
    ;
  }
}
