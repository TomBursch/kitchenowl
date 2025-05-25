import 'package:flutter/material.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/models/member.dart';
import 'package:kitchenowl/widgets/user_list_tile.dart';

class UpdateMemberBottomSheet extends StatefulWidget {
  final Member member;
  final bool allowEdit;
  final void Function(Member) removeMember;
  final void Function(Member) putMember;

  const UpdateMemberBottomSheet({
    super.key,
    required this.member,
    this.allowEdit = true,
    required this.removeMember,
    required this.putMember,
  });

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
            title: Text(AppLocalizations.of(context)!.reportIssue),
            leading: const Icon(Icons.report_rounded),
            trailing: const Icon(Icons.arrow_forward_ios_rounded),
            enabled: false,
          ),
          if (widget.allowEdit) ...[
            ListTile(
              title: Text(AppLocalizations.of(context)!.parent),
              subtitle: Text(AppLocalizations.of(context)!.parentRights),
              leading: const Icon(
                Icons.admin_panel_settings_rounded,
              ),
              enabled: !widget.member.owner,
              trailing: KitchenOwlSwitch(
                value: isAdmin,
                onChanged: widget.member.owner
                    ? null
                    : (v) {
                        widget.putMember(widget.member.copyWith(admin: v));
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
                      widget.removeMember(widget.member);
                      Navigator.of(context).pop();
                    },
              child: Text(
                AppLocalizations.of(context)!.memberRemove,
              ),
            ),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
