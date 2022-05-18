import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class SliverOptionsHeader extends StatelessWidget {
  final HeaderButton? left;
  final HeaderButton? right;

  const SliverOptionsHeader({
    Key? key,
    this.left,
    this.right,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
      sliver: SliverToBoxAdapter(
        child: Row(
          children: [
            if (left != null)
              TextButton(
                onPressed: left!.onPressed,
                child: Padding(
                  padding: const EdgeInsets.only(
                    right: 4,
                    left: 1,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      left!.icon,
                      const SizedBox(width: 4),
                      Text(left!.text),
                    ],
                  ),
                ),
              ),
            const Spacer(),
            if (right != null)
              TextButton(
                onPressed: right!.onPressed,
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: 4,
                    right: 1,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(right!.text),
                      const SizedBox(width: 4),
                      right!.icon,
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class HeaderButton extends Equatable {
  final String text;
  final Icon icon;
  final void Function()? onPressed;

  const HeaderButton({this.onPressed, required this.icon, required this.text});

  @override
  List<Object?> get props => [text, icon, onPressed];
}
