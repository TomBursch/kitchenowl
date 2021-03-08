import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:kitchenowl/config.dart';
import 'package:tuple/tuple.dart';

// Export extensions
export 'user.dart';
export 'item.dart';
export 'shoppinglist.dart';
export 'recipe.dart';

enum Connection {
  disconnected,
  unsupported,
  connected,
  authenticated,
  undefined
}

class ApiService {
  static const Duration _TIMEOUT = const Duration(seconds: 3);
  static ApiService _instance;
  final _client = http.Client();
  final String baseUrl;
  String _refreshToken;

  static ValueNotifier<Connection> _connectionNotifier =
      ValueNotifier<Connection>(Connection.undefined);
  Map<String, String> headers = {};

  ApiService._internal(this.baseUrl) {
    _connectionNotifier.value = Connection.undefined;
  }

  static ApiService getInstance() {
    if (_instance == null) {
      _instance = ApiService._internal('');
    }
    return _instance;
  }

  Connection get connectionStatus => _connectionNotifier.value;

  set refreshToken(String newRefreshToken) =>
      this._refreshToken = newRefreshToken;

  bool isConnected() => _connectionNotifier.value != Connection.disconnected;

  bool isAuthenticated() =>
      _connectionNotifier.value == Connection.authenticated;

  void dispose() {
    _instance = null;
    _connectionNotifier.value = Connection.undefined;
    _client.close();
  }

  void addListener(void Function() f) {
    _connectionNotifier.addListener(f);
  }

  void removeListener(void Function() f) {
    _connectionNotifier.removeListener(f);
  }

  static Future<void> connectTo(String url, {String refreshToken}) async {
    getInstance().dispose();
    _instance = ApiService._internal(
      url ?? '',
    );
    _instance.refreshToken = refreshToken ?? '';
    await _instance.refresh();
  }

  Future<void> refresh() async {
    if (baseUrl.isNotEmpty) {
      final healthy = await _instance.healthy();
      if (healthy.item1) {
        if (healthy.item2['min_frontend_version'] <=
                (int.tryParse(Config.packageInfo?.buildNumber) ?? 0) &&
            (healthy.item2['version'] ?? 0) >= Config.MIN_BACKEND_VERSION) {
          if (await _instance.refreshAuth()) {
            return _instance._setConnectionState(Connection.authenticated);
          } else {
            return _instance._setConnectionState(Connection.connected);
          }
        } else {
          return _instance._setConnectionState(Connection.unsupported);
        }
      }
    }
    return _instance._setConnectionState(Connection.disconnected);
  }

  Future<http.Response> get(String url, {bool refreshOnException}) =>
      _handleRequest(
        () => this._client.get(Uri.parse(this.baseUrl + url), headers: headers),
        refreshOnException: refreshOnException,
      );

  Future<http.Response> post(String url, dynamic body, {Encoding encoding}) =>
      _handleRequest(() => this._client.post(Uri.parse(this.baseUrl + url),
          body: body, headers: headers, encoding: encoding));

  Future<http.Response> delete(String url, {dynamic body, Encoding encoding}) =>
      _handleRequest(() async {
        final request = http.Request(
          'DELETE',
          Uri.parse(this.baseUrl + url),
        );
        request.headers.addAll(this.headers);
        if (encoding != null) request.encoding = encoding;
        if (body != null) request.body = body;
        return http.Response.fromStream(await this._client.send(request));
      });

  Future<http.Response> _handleRequest(Future<http.Response> Function() request,
      {bool refreshOnException = true}) async {
    try {
      http.Response response = await request().timeout(_TIMEOUT);
      if (response.statusCode == 401) {
        await refresh();
        if (this.isAuthenticated()) response = await request();
      }
      return response;
    } catch (e) {
      if (refreshOnException) await refresh();
    }
    return http.Response('', 500);
  }

  void _setConnectionState(Connection newState) {
    _connectionNotifier.value = newState;
  }

  Future<Tuple2<bool, Map<String, dynamic>>> healthy() async {
    try {
      final res = await get('/health/8M4F88S8ooi4sMbLBfkkV7ctWwgibW6V');
      if (res.statusCode == 200)
        return Tuple2(
          jsonDecode(res.body)['msg'] == 'OK',
          jsonDecode(res.body),
        );
    } catch (e) {}
    return Tuple2(false, null);
  }

  Future<bool> refreshAuth() async {
    final _headers = Map<String, String>.from(headers);
    _headers['Authorization'] = 'Bearer ' + _refreshToken;
    final res = await this
        ._client
        .get(Uri.parse(this.baseUrl + '/auth/refresh'), headers: _headers);
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      this.headers['Authorization'] = 'Bearer ' + body['access_token'];
      _setConnectionState(Connection.authenticated);
      return true;
    }
    return false;
  }

  Future<String> login(String username, String password) async {
    final res = await post(
        '/auth', jsonEncode({'username': username, 'password': password}));
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      this.headers['Authorization'] = 'Bearer ' + body['access_token'];
      _refreshToken = body['refresh_token'];
      _setConnectionState(Connection.authenticated);
      return _refreshToken;
    }
    return null;
  }

  Future<bool> isOnboarding() async {
    final res = await get('/onboarding');
    if (res.statusCode != 200) return false;
    final body = jsonDecode(res.body);
    return body['onboarding'] as bool;
  }

  Future<String> onboarding(
      String username, String name, String password) async {
    if (!(await isOnboarding())) return null;
    final res = await post(
        '/onboarding',
        jsonEncode({
          'username': username,
          'name': name,
          'password': password,
        }));
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      this.headers['Authorization'] = 'Bearer ' + body['access_token'];
      _refreshToken = body['refresh_token'];
      _setConnectionState(Connection.authenticated);
      return _refreshToken;
    }
    return null;
  }
}
