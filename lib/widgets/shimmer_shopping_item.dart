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
    final color = Theme.of(context).brightness == Brightness.dark
        ? Theme.of(context).cardColor
        : Theme.of(context).disabledColor;

    return (gridStyle ?? true)
        ? Shimmer.fromColors(
            baseColor: color,
            highlightColor: Colors.grey[300]!.withOpacity(.5),
            child: Material(
              color: color,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(4)),
              ),
            ),
          )
        : const ShimmerCard();
  }
}
