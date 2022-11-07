import 'package:flutter/material.dart';
import 'package:kitchenowl/helpers/debouncer.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:responsive_builder/responsive_builder.dart';

class SearchTextField extends StatefulWidget {
  final TextEditingController controller;
  final Future<void> Function(String) onSearch;
  final void Function()? onSubmitted;
  final TextInputAction? textInputAction;
  final bool autofocus;
  final bool clearOnSubmit;
  final InputDecoration? decoration;
  final bool alwaysExpanded;

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
    this.alwaysExpanded = false,
  });

  @override
  State<SearchTextField> createState() => _SearchTextFieldState();
}

class _SearchTextFieldState extends State<SearchTextField> {
  Debouncer? _debouncer;
  late bool showSuffix;
  late bool expanded;
  late FocusNode focusNode;

  @override
  void initState() {
    super.initState();
    showSuffix = widget.controller.text.isNotEmpty;
    widget.controller.addListener(_onControllerChanged);
    _debouncer =
        Debouncer(duration: Duration(milliseconds: widget.searchDelay));
    focusNode = FocusNode();
    expanded = widget.alwaysExpanded;
    if (!widget.alwaysExpanded) {
      focusNode.addListener(() {
        setState(() {
          expanded = focusNode.hasFocus || widget.controller.text.isNotEmpty;
        });
      });
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    focusNode.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    setState(() {
      showSuffix = widget.controller.text.isNotEmpty;
      expanded = widget.alwaysExpanded ||
          focusNode.hasFocus ||
          widget.controller.text.isNotEmpty;
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
    return Align(
      alignment: Alignment.centerLeft,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: expanded
            ? MediaQuery.of(context).size.width
            : getValueForScreenType(
                context: context,
                mobile: double.infinity,
                tablet: 450,
                desktop: 550,
              ),
        child: TextField(
          controller: widget.controller,
          focusNode: focusNode,
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
        ),
      ),
    );
  }
}
