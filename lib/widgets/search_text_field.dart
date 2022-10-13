import 'package:flutter/material.dart';
import 'package:kitchenowl/helpers/debouncer.dart';
import 'package:kitchenowl/kitchenowl.dart';

class SearchTextField extends StatefulWidget {
  final TextEditingController controller;
  final Future<void> Function(String) onSearch;
  final void Function()? onSubmitted;
  final TextInputAction? textInputAction;
  final bool autofocus;
  final bool clearOnSubmit;
  final InputDecoration? decoration;

  /// Search dealy in milliseconds.
  /// Set it to 0 to remove the debouncer
  final int searchDelay;

  const SearchTextField({
    super.key,
    required this.controller,
    required this.onSearch,
    this.onSubmitted,
    this.textInputAction,
    this.autofocus = false,
    this.clearOnSubmit = true,
    this.searchDelay = 200,
    this.decoration,
  });

  @override
  State<SearchTextField> createState() => _SearchTextFieldState();
}

class _SearchTextFieldState extends State<SearchTextField> {
  Debouncer? _debouncer;
  late bool showSuffix;

  @override
  void initState() {
    super.initState();
    showSuffix = widget.controller.text.isNotEmpty;
    widget.controller.addListener(_onControllerChanged);
    _debouncer =
        Debouncer(duration: Duration(milliseconds: widget.searchDelay));
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    setState(() {
      showSuffix = widget.controller.text.isNotEmpty;
    });
  }

  void _onChanged(String s) {
    if (_debouncer != null) {
      _debouncer?.run(() => widget.onSearch(s));
    } else {
      widget.onSearch(s);
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      onChanged: _onChanged,
      textInputAction: widget.textInputAction ?? TextInputAction.done,
      onEditingComplete: widget.clearOnSubmit
          ? () {
              _debouncer?.cancel();
              widget.onSearch('');
            }
          : null,
      onSubmitted: widget.onSubmitted != null
          ? (_) {
              _debouncer?.cancel();
              widget.onSubmitted!();
            }
          : null,
      autofocus: widget.autofocus,
      scrollPadding: EdgeInsets.zero,
      maxLines: 1,
      textAlignVertical: TextAlignVertical.center,
      decoration: widget.decoration?.applyDefaults(InputDecorationTheme(
            isDense: true,
            border: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(14)),
            ),
            fillColor: Theme.of(context).colorScheme.background,
          )) ??
          InputDecoration(
            isDense: true,
            fillColor: Theme.of(context).colorScheme.background,
            border: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(14)),
            ),
            prefixIcon: const Icon(Icons.search),
            suffixIcon: showSuffix
                ? IconButton(
                    onPressed: () {
                      _debouncer?.cancel();
                      if (widget.controller.text.isNotEmpty) {
                        widget.controller.clear();
                        widget.onSearch('');
                      }
                      FocusScope.of(context).unfocus();
                    },
                    icon: const Icon(
                      Icons.close,
                      color: Colors.grey,
                    ),
                  )
                : null,
            labelText: AppLocalizations.of(context)!.searchHint,
          ),
    );
  }
}
