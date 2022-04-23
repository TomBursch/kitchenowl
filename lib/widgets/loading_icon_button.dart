import 'package:flutter/material.dart';

class LoadingIconButton extends StatefulWidget {
  final Widget icon;
  final Future Function()? onPressed;

  const LoadingIconButton({Key? key, required this.icon, this.onPressed})
      : super(key: key);

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
                  setState(() {
                    isLoading = false;
                  });
                }
              : null,
          icon: widget.icon,
        )
      : const Padding(
          padding: EdgeInsets.all(16),
          child: AspectRatio(
            aspectRatio: 1,
            child: CircularProgressIndicator.adaptive(),
          ),
        );
}
