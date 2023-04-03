import 'package:flutter/material.dart';

class LoadingIconButton extends StatefulWidget {
  final Widget icon;
  final Color? loadingColor;
  final Future Function()? onPressed;
  final EdgeInsetsGeometry? padding;

  const LoadingIconButton({
    Key? key,
    required this.icon,
    this.loadingColor,
    this.onPressed,
    this.padding,
  }) : super(key: key);

  @override
  State<LoadingIconButton> createState() => _LoadingIconButtonState();
}

class _LoadingIconButtonState extends State<LoadingIconButton> {
  bool isLoading = false;

  @override
  Widget build(BuildContext context) => !isLoading
      ? IconButton(
          onPressed: widget.onPressed != null
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
          icon: widget.icon,
          padding: widget.padding,
        )
      : Padding(
          padding: const EdgeInsets.all(16),
          child: AspectRatio(
            aspectRatio: 1,
            child: CircularProgressIndicator(
              color: widget.loadingColor,
            ),
          ),
        );
}
