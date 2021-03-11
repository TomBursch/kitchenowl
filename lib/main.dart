import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'app.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart' as DotEnv;

Future main() async {
  try {
    await DotEnv.load(fileName: ".env");
  } catch (e) {}
  await PackageInfo.fromPlatform();
  runApp(App());
}
