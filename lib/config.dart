import 'package:package_info/package_info.dart';

abstract class Config {
  static const int MIN_BACKEND_VERSION = 1;
  static PackageInfo packageInfo; // Gets loaded by SettingsCubit
}
