import 'package:flutter/material.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerShoppingItemWidget extends StatelessWidget {
  final bool? gridStyle;
  const ShimmerShoppingItemWidget({
    super.key,
    this.gridStyle = true,
  });

  @override
  Widget build(BuildContext context) {
    final color = ElevationOverlay.applySurfaceTint(
      Theme.of(context).cardTheme.color ?? Theme.of(context).cardColor,
      Theme.of(context).cardTheme.surfaceTintColor,
      1,
    );

    return (gridStyle ?? true)
        ? Padding(
            padding: const EdgeInsets.all(4),
            child: Shimmer.fromColors(
              baseColor: color,
              highlightColor: Colors.grey[300]!.withOpacity(.5),
              child: Material(
                color: color,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(14)),
                ),
              ),
            ),
          )
        : const ShimmerCard();
  }
}
