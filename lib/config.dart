import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

abstract class Config {
  // ignore: constant_identifier_names
  static const int MIN_BACKEND_VERSION = 36;
  static Future<PackageInfo?>? _packageInfo; // Gets loaded by SettingsCubit
  static PackageInfo? _packageInfoSync;
  static Future<BaseDeviceInfo>? deviceInfo;

  static set packageInfo(Future<PackageInfo?>? value) {
    value?.then((value) => _packageInfoSync = value);
    _packageInfo = value;
  }

  static Future<PackageInfo?>? get packageInfo => _packageInfo;

  static PackageInfo? get packageInfoSync => _packageInfoSync;

  static Future<String?> get deviceName async {
    if (await deviceInfo == null) return null;
    final map = (await deviceInfo)!.toMap();

    return map['prettyName'] ?? // linux
        map['name'] ?? // ios
        map['userAgent'] ?? // web
        map['computerName'] ?? // windows & mac
        map['model']; // android
  }
}
