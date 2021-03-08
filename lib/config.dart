import 'package:package_info_plus/package_info_plus.dart';

abstract class Config {
  static const int MIN_BACKEND_VERSION = 1;
  static PackageInfo packageInfo; // Gets loaded by SettingsCubit
}
