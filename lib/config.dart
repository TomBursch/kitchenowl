import 'package:package_info_plus/package_info_plus.dart';

abstract class Config {
  // ignore: constant_identifier_names
  static const int MIN_BACKEND_VERSION = 23;
  static Future<PackageInfo?>? _packageInfo; // Gets loaded by SettingsCubit
  static PackageInfo? _packageInfoSync;

  static set packageInfo(Future<PackageInfo?>? value) {
    value?.then((value) => _packageInfoSync = value);
    _packageInfo = value;
  }

  static Future<PackageInfo?>? get packageInfo => _packageInfo;

  static PackageInfo? get packageInfoSync => _packageInfoSync;
}
