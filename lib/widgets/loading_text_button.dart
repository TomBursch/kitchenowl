import 'package:flutter/material.dart';

class LoadingTextButton extends StatefulWidget {
  final Widget child;
  final Future Function()? onPressed;
  final ButtonStyle? style;
  final Widget? icon;

  const LoadingTextButton({
    super.key,
    required this.child,
    this.onPressed,
    this.style,
    this.icon,
  });

  @override
  State<LoadingTextButton> createState() => _LoadingTextButtonState();
}

class _LoadingTextButtonState extends State<LoadingTextButton> {
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    if (widget.icon == null || isLoading) {
      return TextButton(
        style: widget.style,
        onPressed: _onPressed(),
        child: isLoading
            ? const SizedBox(
                height: 16,
                width: 16,
                child: CircularProgressIndicator(),
              )
            : widget.child,
      );
    }

    return TextButton.icon(
      style: widget.style,
      onPressed: _onPressed(),
      icon: widget.icon!,
      label: widget.child,
    );
  }

  void Function()? _onPressed() {
    return widget.onPressed != null && !isLoading
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
        : null;
  }
}
