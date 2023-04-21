import 'package:flutter/material.dart';
import 'package:kitchenowl/enums/timeframe.dart';

class TimeframeDropdownButton extends StatelessWidget {
  final Timeframe value;
  final void Function(Timeframe?) onChanged;

  const TimeframeDropdownButton({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicWidth(
      child: InputDecorator(
        decoration: InputDecoration(
          isCollapsed: true,
          contentPadding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
          fillColor: Theme.of(context).hoverColor,
          filled: true,
          border: const OutlineInputBorder(
            borderSide: BorderSide.none,
            borderRadius: BorderRadius.all(Radius.circular(30)),
          ),
        ),
        child: DropdownButton<Timeframe>(
          value: value,
          items: Timeframe.values
              .map(
                (e) => DropdownMenuItem(
                  value: e,
                  child: Text(
                    e.toLocalizedString(context),
                  ),
                ),
              )
              .toList(),
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
          ),
          underline: const SizedBox(),
          isDense: true,
          onChanged: onChanged,
        ),
      ),
    );
  }
}
