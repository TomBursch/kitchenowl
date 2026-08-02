import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class Storage {
  Future<void> delete({required String key});
  Future<String?> read({required String key});
  Future<void> write({required String key, required String value});
}

class SecureStorage extends Storage {
  final _storage = const FlutterSecureStorage(
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );
  static SecureStorage? _instance;

  SecureStorage._internal();
  static SecureStorage getInstance() {
    // Flutter web: `flutter_secure_storage` ^10.x relies on
    // `window.crypto.subtle`, which the browser only exposes inside a
    // "secure context". The browser hard-codes that list to `https://*`,
    // `http://localhost`, `http://127.0.0.1`, `http://[::1]` and
    // `http://*.localhost`. Custom DNS names such as `kitchenowl.dev.local`
    // do NOT qualify, no matter what they resolve to — see
    // https://developer.mozilla.org/en-US/docs/Web/Security/Secure_Contexts
    //
    // When served over plain HTTP from any other host (e.g.
    // `http://10.0.0.3:1081` or `http://kitchenowl.dev.local`), reads and
    // writes silently fail and the persisted refresh token is lost on every
    // reload, kicking the user back to /signin. We therefore always fall
    // back to `SharedPreferences` (localStorage) on web. That stores the
    // refresh token in clear text — same protection level as a normal
    // session cookie, and equivalent in practice to the IndexedDB-backed
    // path that `flutter_secure_storage_web` itself uses (its AES-GCM key is
    // also stored unencrypted on the same origin).
    if (kIsWeb) {
      _instance ??= _WebFallbackSecureStorage();
    } else {
      _instance ??= SecureStorage._internal();
    }

    return _instance!;
  }

  @override
  Future<void> delete({required String key}) async {
    return _storage.containsKey(key: key).then((v) {
      if (v) return _storage.delete(key: key);
    });
  }

  @override
  Future<String?> read({required String key}) async {
    return await _storage.read(key: key);
  }

  @override
  Future<void> write({required String key, required String value}) async {
    await _storage.write(key: key, value: value);
  }
}

/// Web-only fallback that persists secrets via `SharedPreferences`
/// (localStorage). Used because `flutter_secure_storage` requires a secure
/// context on web — see [SecureStorage.getInstance].
///
/// On first read for a given key the implementation also probes the
/// underlying `FlutterSecureStorage` once and migrates any value it finds
/// into the fallback store. This keeps existing sessions of users that
/// previously ran the app under `http://localhost` (where `crypto.subtle`
/// IS available, so `flutter_secure_storage_web` worked) intact when they
/// switch to a non-secure-context URL.
class _WebFallbackSecureStorage extends SecureStorage {
  _WebFallbackSecureStorage() : super._internal();

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  // Tracks which keys we already attempted the legacy migration for in this
  // process, so the migration probe runs at most once per key per session.
  final Set<String> _migrated = <String>{};

  @override
  Future<void> delete({required String key}) async {
    final prefs = await _prefs;
    await prefs.remove(_prefixed(key));
    // Also clear any legacy entry so a stale value can't resurface via the
    // migration path on the next read.
    try {
      if (await _storage.containsKey(key: key)) {
        await _storage.delete(key: key);
      }
    } catch (_) {
      // Secure context unavailable — nothing to clean up.
    }
    _migrated.add(key);
  }

  @override
  Future<String?> read({required String key}) async {
    final prefs = await _prefs;
    final existing = prefs.getString(_prefixed(key));
    if (existing != null) return existing;
    if (_migrated.contains(key)) return null;
    _migrated.add(key);
    // One-shot probe of the legacy native-style backend. On a non-secure
    // context this either throws or returns null; either way we move on.
    try {
      final legacy = await _storage.read(key: key);
      if (legacy != null && legacy.isNotEmpty) {
        await prefs.setString(_prefixed(key), legacy);
        // Best-effort cleanup of the now-migrated legacy entry.
        try {
          await _storage.delete(key: key);
        } catch (_) {/* ignore */}
        return legacy;
      }
    } catch (_) {
      // crypto.subtle missing or other browser restriction — ignore.
    }
    return null;
  }

  @override
  Future<void> write({required String key, required String value}) async {
    final prefs = await _prefs;
    await prefs.setString(_prefixed(key), value);
    _migrated.add(key);
  }

  // Namespaced to avoid collisions with PreferenceStorage keys.
  String _prefixed(String key) => 'secure.$key';
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
  Future<double?> readDouble({required String key}) async =>
      (await _storage).getDouble(key);
  Future<bool?> readBool({required String key}) async =>
      (await _storage).getBool(key);

  @override
  Future<void> write({required String key, required String value}) async =>
      (await _storage).setString(key, value);
  Future<void> writeInt({required String key, required int value}) async =>
      (await _storage).setInt(key, value);
  Future<void> writeDouble(
          {required String key, required double value}) async =>
      (await _storage).setDouble(key, value);
  Future<void> writeBool({required String key, required bool value}) async =>
      (await _storage).setBool(key, value);
}
