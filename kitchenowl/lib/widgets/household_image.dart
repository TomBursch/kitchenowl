import 'package:flutter/material.dart';
import 'package:flutter_blurhash/flutter_blurhash.dart';
import 'package:kitchenowl/models/household.dart';
import 'package:kitchenowl/pages/household_member_page.dart';
import 'package:kitchenowl/widgets/avatar_list.dart';
import 'package:kitchenowl/widgets/image_provider.dart';
import 'package:transparent_image/transparent_image.dart';

class HouseholdImage extends StatelessWidget {
  final Household household;
  final bool enableMembersTap;

  const HouseholdImage({
    super.key,
    required this.household,
    this.enableMembersTap = true,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        height: 150,
        child: Stack(
          alignment: Alignment.bottomLeft,
          fit: StackFit.loose,
          children: [
            SizedBox.expand(
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
            if (household.member != null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: AvatarList(
                  users: household.member!,
                  onTap: enableMembersTap
                      ? () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (ctx) => HouseholdMemberPage(
                                household: household,
                              ),
                            ),
                          )
                      : null,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
