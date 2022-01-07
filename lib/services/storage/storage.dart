import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class Storage {
  Future<void> delete({String key});
  Future<String> read({String key});
  Future<void> write({String key, String value});
}

class SecureStorage extends Storage {
  final _storage = const FlutterSecureStorage();
  static SecureStorage _instance;

  SecureStorage._internal();
  static SecureStorage getInstance() {
    _instance ??= SecureStorage._internal();
    return _instance;
  }

  bool _platformSupportsSecureStorage() => !kIsWeb;

  @override
  Future<void> delete({String key}) async {
    if (_platformSupportsSecureStorage()) {
      await _storage.delete(key: key);
    }
  }

  @override
  Future<String> read({String key}) async {
    if (_platformSupportsSecureStorage()) {
      return await _storage.read(key: key);
    }
    return '';
  }

  @override
  Future<void> write({String key, String value}) async {
    if (_platformSupportsSecureStorage()) {
      await _storage.write(key: key, value: value);
    }
  }
}

class PreferenceStorage extends Storage {
  final _storage = SharedPreferences.getInstance();
  static PreferenceStorage _instance;

  PreferenceStorage._internal();
  static PreferenceStorage getInstance() {
    _instance ??= PreferenceStorage._internal();
    return _instance;
  }

  @override
  Future<void> delete({String key}) async => (await _storage).remove(key);

  @override
  Future<String> read({String key}) async => (await _storage).getString(key);
  Future<int> readInt({String key}) async => (await _storage).getInt(key);
  Future<bool> readBool({String key}) async => (await _storage).getBool(key);

  @override
  Future<void> write({String key, String value}) async =>
      (await _storage).setString(key, value);
  Future<void> writeInt({String key, int value}) async =>
      (await _storage).setInt(key, value);
  Future<void> writeBool({String key, bool value}) async =>
      (await _storage).setBool(key, value);
}