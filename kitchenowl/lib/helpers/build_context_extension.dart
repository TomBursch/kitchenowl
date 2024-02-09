import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

extension ReadOrNull on BuildContext {
  T? readOrNull<T>() {
    try {
      return read<T>();
    } on ProviderNotFoundException catch (_) {
      return null;
    }
  }
}
