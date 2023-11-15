import 'package:flutter/material.dart';

class LoadingElevatedButtonIcon extends StatefulWidget {
  final Widget label;
  final Widget icon;
  final Future Function()? onPressed;
  final ButtonStyle? style;

  const LoadingElevatedButtonIcon({
    super.key,
    required this.label,
    required this.icon,
    this.onPressed,
    this.style,
  });

  @override
  State<LoadingElevatedButtonIcon> createState() =>
      _LoadingElevatedButtonIconState();
}

class _LoadingElevatedButtonIconState extends State<LoadingElevatedButtonIcon> {
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      style: widget.style,
      icon: widget.icon,
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
      label: isLoading
          ? const SizedBox(
              height: 16,
              width: 16,
              child: CircularProgressIndicator(),
            )
          : widget.label,
    );
  }
}
