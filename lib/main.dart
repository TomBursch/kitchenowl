import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl_standalone.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_web_plugins/url_strategy.dart';
import 'app.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  if (!kIsWeb) await findSystemLocale(); //BUG in package for web?
  runApp(App());
}
