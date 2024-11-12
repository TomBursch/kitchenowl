import 'package:flutter/material.dart';
import 'package:flutter_blurhash/flutter_blurhash.dart';
import 'package:kitchenowl/models/household.dart';
import 'package:kitchenowl/widgets/image_provider.dart';
import 'package:transparent_image/transparent_image.dart';

class HouseholdImage extends StatelessWidget {
  final Household household;

  const HouseholdImage({super.key, required this.household});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        height: 150,
        child: FadeInImage(
          fit: BoxFit.cover,
          placeholder: household.imageHash != null
              ? BlurHashImage(household.imageHash!)
              : MemoryImage(kTransparentImage) as ImageProvider,
          image: getImageProvider(
            context,
            household.image!,
          ),
        ),
      ),
    );
  }
}
