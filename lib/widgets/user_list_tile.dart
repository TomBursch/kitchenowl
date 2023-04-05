import 'package:flutter/material.dart';
import 'package:kitchenowl/models/user.dart';
import 'package:kitchenowl/widgets/image_provider.dart';

class UserListTile extends StatelessWidget {
  final User user;
  final bool disabled;
  final void Function()? onTap;
  final Widget? trailing;

  const UserListTile({
    super.key,
    required this.user,
    this.disabled = false,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        foregroundImage: user.image.isEmpty
            ? null
            : getImageProvider(
                context,
                user.image,
              ),
        child: Text(user.name.substring(0, 1)),
      ),
      enabled: !disabled,
      title: Text(user.name),
      subtitle: Text("@${user.username}"),
      trailing: trailing,
      onTap: onTap,
    );
  }
}
