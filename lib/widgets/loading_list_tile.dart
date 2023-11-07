import 'package:flutter/material.dart';

class LoadingListTile extends StatefulWidget {
  final Future Function()? onTap;
  final Widget? leading;
  final Widget? trailing;
  final Widget? title;
  final EdgeInsetsGeometry? contentPadding;

  const LoadingListTile(
      {super.key,
      this.onTap,
      this.leading,
      this.trailing,
      this.title,
      this.contentPadding});

  @override
  State<LoadingListTile> createState() => _LoadingListTileState();
}

class _LoadingListTileState extends State<LoadingListTile> {
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: isLoading ? null : _onTap(),
      leading: widget.leading,
      title: widget.title,
      contentPadding: widget.contentPadding,
      trailing: isLoading
          ? const SizedBox(
              height: 16,
              width: 16,
              child: CircularProgressIndicator(),
            )
          : widget.trailing,
    );
  }

  void Function()? _onTap() {
    return widget.onTap != null && !isLoading
        ? () async {
            setState(() {
              isLoading = true;
            });
            await widget.onTap!();
            if (mounted) {
              setState(() {
                isLoading = false;
              });
            }
          }
        : null;
  }
}
