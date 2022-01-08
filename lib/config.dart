import 'package:package_info_plus/package_info_plus.dart';

abstract class Config {
  // ignore: constant_identifier_names
  static const int MIN_BACKEND_VERSION = 17;
  static PackageInfo? packageInfo; // Gets loaded by SettingsCubit
}
