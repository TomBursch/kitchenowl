import 'package:flutter/services.dart';

class UsernameTextInputFormater extends TextInputFormatter {
  static final RegExp _regEx =
      RegExp("""(^\$)|(^[!-?A-~]+\$)""", caseSensitive: false);

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    return _regEx.hasMatch(newValue.text)
        ? newValue.copyWith(text: newValue.text.toLowerCase())
        : oldValue;
  }
}
