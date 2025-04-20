import 'dart:math';

import 'package:flutter/material.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/models/user.dart';
import 'package:kitchenowl/widgets/user_circle_avatar.dart';

class AvatarList extends StatelessWidget {
  final List<User> users;
  final double radius;
  final double overlap;
  final int? avatarLimit;
  final TextScaler? textScaler;

  const AvatarList({
    super.key,
    required this.users,
    this.radius = 25,
    this.avatarLimit = 6,
    this.overlap = 0.8,
    this.textScaler,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: (avatarLimit != null && avatarLimit! < users.length
                  ? avatarLimit! + 1
                  : users.length) *
              radius *
              (2 - overlap) +
          radius * overlap,
      child: Stack(
        children: [
          if (avatarLimit != null && avatarLimit! < users.length)
            Transform(
              transform: Matrix4.translationValues(
                // radius - overlap
                avatarLimit! * radius * (2 - overlap),
                0,
                0,
              ),
              child: CircleAvatar(
                child: Text("+${users.length - avatarLimit!}"),
                backgroundColor:
                    Theme.of(context).colorScheme.secondaryContainer,
                radius: radius,
              ),
            ),
          for (int i = (avatarLimit != null
                      ? min(avatarLimit!, users.length)
                      : users.length) -
                  1;
              i >= 0;
              i--)
            Container(
              transform: Matrix4.translationValues(
                // radius - overlap
                i * radius * (2 - overlap),
                0,
                0,
              ),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black54,
                    offset: Offset(2, 2),
                    blurRadius: 3,
                  )
                ],
              ),
              child: UserCircleAvatar(
                user: users[i],
                radius: radius,
              ),
            ),
        ],
      ),
    );
  }
}
