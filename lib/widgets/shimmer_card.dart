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
            children: [
              Container(
                constraints: BoxConstraints(
                  maxHeight: Theme.of(context).textTheme.bodyText1!.fontSize!,
                  maxWidth: 200,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  color: Colors.white,
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
