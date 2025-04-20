import 'package:flutter/material.dart';
import 'package:kitchenowl/models/user.dart';
import 'package:kitchenowl/widgets/image_provider.dart';

class UserCircleAvatar extends StatelessWidget {
  final User user;
  final double? radius;
  final TextScaler? textScaler;

  const UserCircleAvatar({
    super.key,
    required this.user,
    this.radius,
    this.textScaler,
  });

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      foregroundImage: user.image?.isEmpty ?? true
          ? null
          : getImageProvider(
              context,
              user.image!,
            ),
      child: user.name.isNotEmpty
          ? Text(
              user.name.substring(0, 1),
              textScaler: textScaler,
            )
          : null,
      radius: radius,
    );
  }
}
