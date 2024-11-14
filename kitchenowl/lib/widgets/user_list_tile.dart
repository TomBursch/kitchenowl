import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/cubits/auth_cubit.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/models/user.dart';

class UserListTile extends StatelessWidget {
  final User user;
  final bool disabled;
  final void Function()? onTap;
  final Widget? trailing;
  final bool markSelf;
  final EdgeInsetsGeometry? contentPadding;
  final bool showEmail;

  const UserListTile({
    super.key,
    required this.user,
    this.disabled = false,
    this.onTap,
    this.trailing,
    this.markSelf = false,
    this.contentPadding,
    this.showEmail = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: contentPadding,
      leading: CircleAvatar(
        foregroundImage: user.image?.isEmpty ?? true
            ? null
            : getImageProvider(
                context,
                user.image!,
              ),
        child: user.name.isNotEmpty ? Text(user.name.substring(0, 1)) : null,
      ),
      enabled: !disabled,
      title: Text(user.name +
          (markSelf &&
                  (user.id ==
                      (BlocProvider.of<AuthCubit>(
                        context,
                      ).state as Authenticated)
                          .user
                          .id)
              ? ' (${AppLocalizations.of(context)!.you})'
              : '')),
      subtitle: Text("@${user.username}" +
          (showEmail
              ? "\n${user.email ?? AppLocalizations.of(context)!.none}"
              : "")),
      isThreeLine: showEmail,
      trailing: trailing,
      onTap: onTap,
    );
  }
}
