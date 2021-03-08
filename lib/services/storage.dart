import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class Storage {
  Future<void> delete({String key});
  Future<String> read({String key});
  Future<void> write({String key, String value});
}

class SecureStorage extends Storage {
  final _storage = new FlutterSecureStorage();
  static SecureStorage _instance;

  SecureStorage._internal();
  static SecureStorage getInstance() {
    if (_instance == null) _instance = SecureStorage._internal();
    return _instance;
  }

  Future<void> delete({String key}) => _storage.delete(key: key);

  Future<String> read({String key}) => _storage.read(key: key);

  Future<void> write({String key, String value}) =>
      _storage.write(key: key, value: value);
}

class PreferenceStorage extends Storage {
  final _storage = SharedPreferences.getInstance();
  static PreferenceStorage _instance;

  PreferenceStorage._internal();
  static PreferenceStorage getInstance() {
    if (_instance == null) _instance = PreferenceStorage._internal();
    return _instance;
  }

  Future<void> delete({String key}) async => (await _storage).remove(key);

  Future<String> read({String key}) async => (await _storage).getString(key);
  Future<int> readInt({String key}) async => (await _storage).getInt(key);
  Future<bool> readBool({String key}) async => (await _storage).getBool(key);

  Future<void> write({String key, String value}) async =>
      (await _storage).setString(key, value);
  Future<void> writeInt({String key, int value}) async =>
      (await _storage).setInt(key, value);
  Future<void> writeBool({String key, bool value}) async =>
      (await _storage).setBool(key, value);
}
