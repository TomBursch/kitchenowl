import 'package:flutter/services.dart';
// import 'package:intl/intl.dart';

class CurrencyTextInputFormater extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.replaceFirst(".", "").length > 9) return oldValue;
    final number =
        (double.tryParse(newValue.text.replaceFirst(".", "")) ?? 0) / 100;
    // final oldNumber = double.tryParse(oldValue.text) ?? 0;
    // final addedNumber =
    //     double.tryParse(newValue.text[newValue.selection.baseOffset - 1]) ??
    //         0;
    // if (true) number = oldNumber * 10 + addedNumber / 100;
    final text = number.toStringAsFixed(2);
    return TextEditingValue(
        text: text,
        selection: TextSelection(
          baseOffset: newValue.selection.baseOffset.clamp(0, text.length),
          extentOffset: newValue.selection.baseOffset.clamp(0, text.length),
        ));
  }
}
