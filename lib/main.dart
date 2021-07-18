import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'app.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future main() async {
  try {
    await dotenv.load();
  } catch (e) {}
  await PackageInfo.fromPlatform();
  runApp(App());
}
