import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl_standalone.dart';
import 'app.dart';

Future main() async {
  if (!kIsWeb) await findSystemLocale(); //BUG in package for web?
  runApp(App());
}
