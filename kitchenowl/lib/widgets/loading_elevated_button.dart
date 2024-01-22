import 'package:flutter/material.dart';

class LoadingElevatedButton extends StatefulWidget {
  final Widget child;
  final Future Function()? onPressed;
  final ButtonStyle? style;
  final double loadingIndicatorSize;

  const LoadingElevatedButton({
    super.key,
    required this.child,
    this.onPressed,
    this.style,
    this.loadingIndicatorSize = 24,
  });

  @override
  State<LoadingElevatedButton> createState() => _LoadingElevatedButtonState();
}

class _LoadingElevatedButtonState extends State<LoadingElevatedButton> {
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
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
