import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class Storage {
  Future<void> delete({required String key});
  Future<String?> read({required String key});
  Future<void> write({required String key, required String value});
}

class SecureStorage extends Storage {
  final _storage = const FlutterSecureStorage();
  static SecureStorage? _instance;

  SecureStorage._internal();
  static SecureStorage getInstance() {
    _instance ??= SecureStorage._internal();
    return _instance!;
  }

  bool _platformSupportsSecureStorage() => !kIsWeb;

  @override
  Future<void> delete({required String key}) async {
    if (_platformSupportsSecureStorage()) {
      await _storage.delete(key: key);
    }
  }

  @override
  Future<String?> read({required String key}) async {
    if (_platformSupportsSecureStorage()) {
      return await _storage.read(key: key);
    }
    return '';
  }

  @override
  Future<void> write({required String key, required String value}) async {
    if (_platformSupportsSecureStorage()) {
      await _storage.write(key: key, value: value);
    }
  }
}

class PreferenceStorage extends Storage {
  final _storage = SharedPreferences.getInstance();
  static PreferenceStorage? _instance;

  PreferenceStorage._internal();
  static PreferenceStorage getInstance() {
    _instance ??= PreferenceStorage._internal();
    return _instance!;
  }

  @override
  Future<void> delete({required String key}) async =>
      (await _storage).remove(key);

  @override
  Future<String?> read({required String key}) async =>
      (await _storage).getString(key);
  Future<int?> readInt({required String key}) async =>
      (await _storage).getInt(key);
  Future<bool?> readBool({required String key}) async =>
      (await _storage).getBool(key);

  @override
  Future<void> write({required String key, required String value}) async =>
      (await _storage).setString(key, value);
  Future<void> writeInt({required String key, required int value}) async =>
      (await _storage).setInt(key, value);
  Future<void> writeBool({required String key, required bool value}) async =>
      (await _storage).setBool(key, value);
}
