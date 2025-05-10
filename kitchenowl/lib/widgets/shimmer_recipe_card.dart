import 'package:flutter/material.dart';
import 'package:kitchenowl/widgets/shimmer_card.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerRecipeCard extends StatelessWidget {
  const ShimmerRecipeCard({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: getValueForScreenType(
        context: context,
        mobile: 250,
        tablet: 275,
        desktop: 275,
      ),
      child: Card(
        child: Shimmer.fromColors(
            baseColor: Colors.grey.withAlpha(102),
            highlightColor: Colors.grey[300]!.withAlpha(230),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 3,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: Colors.white,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Chip(
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          label: const SizedBox(width: 40),
                        ),
                        const SizedBox(height: 4),
                        ShimmerText(),
                        const SizedBox(height: 4),
                        ShimmerText(
                          maxWidth: 100,
                        ),
                        Spacer(),
                      ],
                    ),
                  ),
                ),
              ],
            )),
      ),
    );
  }
}
