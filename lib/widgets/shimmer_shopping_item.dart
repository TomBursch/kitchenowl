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
    return (gridStyle ?? true)
        ? Material(
            color: Theme.of(context).brightness == Brightness.dark
                ? Theme.of(context).cardColor
                : Theme.of(context).disabledColor,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(4)),
            ),
            child: Shimmer.fromColors(
              baseColor: Colors.grey[350]!.withOpacity(.4),
              highlightColor: Colors.grey[300]!.withOpacity(.9),
              child: Center(
                child: Container(
                  constraints: BoxConstraints(
                    maxHeight: Theme.of(context).textTheme.bodyText1!.fontSize!,
                    maxWidth: 100,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          )
        : const ShimmerCard();
  }
}
