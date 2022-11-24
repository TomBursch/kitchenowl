import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class OptionsHeader extends StatelessWidget {
  final HeaderButton? left;
  final HeaderButton? right;
  final EdgeInsets padding;

  const OptionsHeader({
    Key? key,
    this.left,
    this.right,
    this.padding = const EdgeInsets.fromLTRB(16, 0, 16, 6),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
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
