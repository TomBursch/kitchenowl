import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl_standalone.dart';
import 'app.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future main() async {
  try {
    await dotenv.load();
  } catch (_) {}
  if (!kIsWeb) await findSystemLocale(); //BUG in package for web?
  runApp(App());
}
