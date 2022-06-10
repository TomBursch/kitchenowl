import 'package:flutter/material.dart';

class LoadingElevatedButton extends StatefulWidget {
  final Widget child;
  final Future Function()? onPressed;
  final ButtonStyle? style;

  const LoadingElevatedButton({
    Key? key,
    required this.child,
    this.onPressed,
    this.style,
  }) : super(key: key);

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
          ? const SizedBox(
              height: 16,
              width: 16,
              child: CircularProgressIndicator(),
            )
          : widget.child,
    );
  }
}
