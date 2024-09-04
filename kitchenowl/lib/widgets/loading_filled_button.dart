import 'package:flutter/material.dart';

class LoadingFilledButton extends StatefulWidget {
  final Widget child;
  final Future Function()? onPressed;
  final ButtonStyle? style;
  final double loadingIndicatorSize;

  const LoadingFilledButton({
    super.key,
    required this.child,
    this.onPressed,
    this.style,
    this.loadingIndicatorSize = 24,
  });

  @override
  State<LoadingFilledButton> createState() => _LoadingFilledButtonState();
}

class _LoadingFilledButtonState extends State<LoadingFilledButton> {
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
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
          ? SizedBox(
              height: widget.loadingIndicatorSize,
              width: widget.loadingIndicatorSize,
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: CircularProgressIndicator(),
              ),
            )
          : widget.child,
    );
  }
}
