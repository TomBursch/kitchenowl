import 'package:flutter/material.dart';

class LoadingTextButton extends StatefulWidget {
  final Widget child;
  final Future Function()? onPressed;
  final ButtonStyle? style;

  const LoadingTextButton({
    Key? key,
    required this.child,
    this.onPressed,
    this.style,
  }) : super(key: key);

  @override
  State<LoadingTextButton> createState() => _LoadingTextButtonState();
}

class _LoadingTextButtonState extends State<LoadingTextButton> {
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      style: widget.style,
      onPressed: widget.onPressed != null && !isLoading
          ? () async {
              setState(() {
                isLoading = true;
              });
              await widget.onPressed!();
              if (mounted) {
                setState(() {
                  isLoading = false;
                });
              }
            }
          : null,
      child: isLoading
          ? const SizedBox(
              height: 16,
              width: 16,
              child: CircularProgressIndicator(),
            )
          : widget.child,
    );
  }
}
