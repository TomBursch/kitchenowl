import 'package:flutter/material.dart';

class NumberSelector extends StatelessWidget {
  /// If non-null, the lower (inclusive) bound for this number.
  final int? lowerBound;

  /// If non-null, the upper (inclusive) bound for this number.
  final int? upperBound;
  final int value;
  final void Function(int) setValue;

  const NumberSelector({
    super.key,
    this.lowerBound,
    this.upperBound,
    required this.value,
    required this.setValue,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        IconButton(
          onPressed: _canDecrease() ? () => setValue(value - 1) : null,
          icon: const Icon(Icons.remove),
        ),
        Text(
          value.toString(),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        IconButton(
          onPressed: _canIncrease() ? () => setValue(value + 1) : null,
          icon: const Icon(Icons.add),
        ),
      ],
    );
  }

  bool _canDecrease() => lowerBound == null || lowerBound! < value;

  bool _canIncrease() => upperBound == null || value < upperBound!;
}
