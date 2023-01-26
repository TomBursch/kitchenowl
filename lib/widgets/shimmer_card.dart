import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerCard extends StatelessWidget {
  final Widget? trailing;
  const ShimmerCard({super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Shimmer.fromColors(
        baseColor: Colors.grey.withOpacity(.4),
        highlightColor: Colors.grey[300]!.withOpacity(.9),
        child: ListTile(
          trailing: trailing ?? const Icon(Icons.arrow_right_rounded),
          title: Row(
            children: const [
              ShimmerText(),
              Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

class ShimmerText extends StatelessWidget {
  final double maxWidth;

  const ShimmerText({super.key, this.maxWidth = 200});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: Theme.of(context).textTheme.bodyLarge!.fontSize!,
        maxWidth: maxWidth,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white,
      ),
    );
  }
}
