import 'package:flutter/material.dart';
import 'package:kitchenowl/models/household.dart';
import 'package:kitchenowl/widgets/image_provider.dart';

class HouseholdCircleAvatar extends StatelessWidget {
  final Household household;
  final double? radius;
  final TextScaler? textScaler;

  const HouseholdCircleAvatar({
    super.key,
    required this.household,
    this.radius,
    this.textScaler,
  });

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      foregroundImage: household.image?.isEmpty ?? true
          ? null
          : getImageProvider(
              context,
              household.image!,
            ),
      child: household.name.isNotEmpty
          ? Text(
              household.name.substring(0, 1),
              textScaler: textScaler,
            )
          : null,
      radius: radius,
    );
  }
}
