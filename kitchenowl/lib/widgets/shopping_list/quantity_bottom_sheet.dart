import 'package:collection/collection.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:kitchenowl/item_icons.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/models/item.dart';

/// Asks for the quantity of an item before adding it.
///
/// Pops the new description, an empty string to add the item without one,
/// or null when dismissed.
class QuantityBottomSheet extends StatefulWidget {
  final Item item;
  final String? initialDescription;
  final List<String> units;

  const QuantityBottomSheet({
    super.key,
    required this.item,
    required this.units,
    this.initialDescription,
  });

  @override
  State<QuantityBottomSheet> createState() => _QuantityBottomSheetState();
}

class _QuantityBottomSheetState extends State<QuantityBottomSheet> {
  static final _leadingNumber = RegExp(r'^\s*(\d+(?:[.,]\d+)?)\s*(.*)$');

  final quantityController = TextEditingController();
  final noteController = TextEditingController();
  late final List<String> units;
  String? unit;

  @override
  void initState() {
    super.initState();
    units = List.of(widget.units);
    _parse(widget.initialDescription);
    quantityController.selection = TextSelection(
      baseOffset: 0,
      extentOffset: quantityController.text.length,
    );
  }

  @override
  void dispose() {
    quantityController.dispose();
    noteController.dispose();
    super.dispose();
  }

  /// Splits a description like "500 g, red" into quantity, unit and note.
  void _parse(String? description) {
    if (description == null || description.trim().isEmpty) return;
    final match = _leadingNumber.firstMatch(description);
    if (match == null) {
      noteController.text = description.trim();
      return;
    }
    quantityController.text = match[1]!.replaceAll(',', '.');
    String rest = match[2]!;
    final comma = rest.indexOf(',');
    if (comma >= 0) {
      noteController.text = rest.substring(comma + 1).trim();
      rest = rest.substring(0, comma);
    }
    rest = rest.trim();
    // "x" is how the server writes a plain count, like "3x"
    if (rest.isEmpty || rest.toLowerCase() == 'x') return;
    unit = units.firstWhereOrNull((e) => e.toLowerCase() == rest.toLowerCase());
    if (unit == null) {
      // Keep units that are not in the list, like "2 jars" from the search
      units.add(rest);
      unit = rest;
    }
  }

  String _description() {
    final quantity = quantityController.text.trim().replaceAll(',', '.');
    final note = noteController.text.trim();

    return [
      if (quantity.isNotEmpty) unit != null ? '$quantity $unit' : quantity,
      if (quantity.isEmpty && unit != null) unit!,
      if (note.isNotEmpty) note,
    ].join(', ');
  }

  double _step() => switch (unit?.toLowerCase()) {
        'g' || 'mg' || 'ml' => 100,
        'kg' || 'l' => 0.5,
        'cl' => 10,
        _ => 1,
      };

  void _changeQuantity(int direction) {
    final current =
        double.tryParse(quantityController.text.replaceAll(',', '.')) ?? 0;
    double value = current + direction * _step();
    if (value < 0) value = 0;
    // Avoid floating point leftovers like 0.30000000000000004
    value = (value * 1000).roundToDouble() / 1000;
    quantityController.text = value <= 0
        ? ''
        : value == value.roundToDouble()
            ? value.toInt().toString()
            : value.toString();
    setState(() {});
  }

  void _done() => Navigator.of(context).pop(_description());

  @override
  Widget build(BuildContext context) {
    final description = _description();

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  if (ItemIcons.get(widget.item) != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Icon(ItemIcons.get(widget.item), size: 28),
                    ),
                  Expanded(
                    child: Text(
                      widget.item.name,
                      style: Theme.of(context).textTheme.titleLarge,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _StepButton(
                    icon: Icons.remove_rounded,
                    onPressed: () => _changeQuantity(-1),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 128,
                    child: TextField(
                      controller: quantityController,
                      autofocus: true,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        // Digits with at most one decimal separator
                        TextInputFormatter.withFunction(
                          (oldValue, newValue) =>
                              RegExp(r'^\d*[.,]?\d*$').hasMatch(newValue.text)
                                  ? newValue
                                  : oldValue,
                        ),
                      ],
                      textInputAction: TextInputAction.done,
                      onChanged: (_) => setState(() {}),
                      onSubmitted: (_) => _done(),
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  _StepButton(
                    icon: Icons.add_rounded,
                    onPressed: () => _changeQuantity(1),
                  ),
                ],
              ),
              if (units.isNotEmpty) ...[
                const SizedBox(height: 12),
                ScrollConfiguration(
                  behavior: ScrollConfiguration.of(context)
                      .copyWith(scrollbars: false),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    primary: false,
                    child: Row(
                      children: [
                        for (final u in units)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              showCheckmark: false,
                              label: Text(
                                u,
                                style: TextStyle(
                                  color: unit == u
                                      ? Theme.of(context).colorScheme.onPrimary
                                      : null,
                                ),
                              ),
                              selected: unit == u,
                              selectedColor:
                                  Theme.of(context).colorScheme.secondary,
                              onSelected: (selected) =>
                                  setState(() => unit = selected ? u : null),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              TextField(
                controller: noteController,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.done,
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _done(),
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)!.quantityNote,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
                onPressed: _done,
                child: Text(
                  description.isEmpty
                      ? AppLocalizations.of(context)!.add
                      : '${AppLocalizations.of(context)!.add} · $description',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(''),
                child: Text(AppLocalizations.of(context)!.addWithoutQuantity),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final void Function() onPressed;

  const _StepButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      onPressed: onPressed,
      icon: Icon(icon),
      iconSize: 40,
      style: IconButton.styleFrom(fixedSize: const Size.square(72)),
    );
  }
}
