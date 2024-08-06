import 'package:flutter/material.dart';

enum LoadingIconButtonVariant { standard, filled, filledTonal, outlined }

class LoadingIconButton extends StatefulWidget {
  final Widget icon;
  final Color? loadingColor;
  final Future Function()? onPressed;
  final EdgeInsetsGeometry? padding;
  final String? tooltip;
  final ButtonStyle? style;
  final LoadingIconButtonVariant variant;

  const LoadingIconButton({
    super.key,
    required this.icon,
    this.loadingColor,
    this.onPressed,
    this.padding,
    this.tooltip,
    this.style,
    this.variant = LoadingIconButtonVariant.standard,
  });

  @override
  State<LoadingIconButton> createState() => _LoadingIconButtonState();
}

class _LoadingIconButtonState extends State<LoadingIconButton> {
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    if (isLoading)
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: AspectRatio(
          aspectRatio: 1,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: CircularProgressIndicator(
              color: widget.loadingColor,
            ),
          ),
        ),
      );

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: switch (widget.variant) {
        LoadingIconButtonVariant.standard => IconButton(
            key: ValueKey(widget.variant),
            tooltip: widget.tooltip,
            style: widget.style,
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
          ),
        LoadingIconButtonVariant.filled => IconButton.filled(
            key: ValueKey(widget.variant),
            tooltip: widget.tooltip,
            style: widget.style,
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
          ),
        LoadingIconButtonVariant.filledTonal => IconButton.filledTonal(
            key: ValueKey(widget.variant),
            tooltip: widget.tooltip,
            style: widget.style,
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
          ),
        LoadingIconButtonVariant.outlined => IconButton.outlined(
            tooltip: widget.tooltip,
            style: widget.style,
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
          ),
      },
    );
  }
}
