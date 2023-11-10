import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:kitchenowl/config.dart';
import 'package:kitchenowl/helpers/named_bytearray.dart';
import 'package:kitchenowl/models/household.dart';
import 'package:kitchenowl/models/token.dart';
import 'package:socket_io_client/socket_io_client.dart';
import 'package:tuple/tuple.dart';

// Export extensions
export 'user.dart';
export 'item.dart';
export 'shoppinglist.dart';
export 'recipe.dart';
export 'planner.dart';
export 'import_export.dart';
export 'expense.dart';
export 'tag.dart';
export 'upload.dart';
export 'category.dart';
export 'household.dart';

enum Connection {
  disconnected,
  unsupportedBackend,
  unsupportedFrontend,
  connected,
  authenticated,
  undefined,
}

class ApiService {
  // ignore: constant_identifier_names
  static const Duration _TIMEOUT = Duration(seconds: 4);

  // ignore: constant_identifier_names
  static const Duration _TIMEOUT_FILE_UPLOAD = Duration(seconds: 10);

  // ignore: constant_identifier_names
  static const Duration _TIMEOUT_ONBOARDING = Duration(minutes: 10);

  // ignore: constant_identifier_names
  static const String _API_PATH = "/api";

  String householdPath(Household household) => "/household/${household.id}";

  static ApiService? _instance;
  final _client = http.Client();
  late final Socket socket;
  final String baseUrl;
  String? _refreshToken;
  Map<String, String> headers = {};
  Future<void>? _refreshThread;

  static void Function(String)? _handleTokenRotation;
  static Future<String?> Function(String?)? _handleTokenBeforeReauth;

  static final ValueNotifier<Connection> _connectionNotifier =
      ValueNotifier<Connection>(Connection.undefined);

  static final ValueNotifier<Map<String, dynamic>?> _serverInfoNotifier =
      ValueNotifier<Map<String, dynamic>?>(null);

  ApiService._internal(String baseUrl)
      : baseUrl = baseUrl.isNotEmpty ? baseUrl + _API_PATH : "" {
    _connectionNotifier.value = Connection.undefined;
    socket = io(
      baseUrl,
      OptionBuilder()
          .setTransports([
            kIsWeb ? 'polling' : 'websocket',
          ]) // for Flutter or Dart VM
          .disableAutoConnect() // disable auto-connection
          .setExtraHeaders(headers)
          .setReconnectionDelay(2000)
          .setReconnectionDelayMax(6000)
          .build(),
    );
    socket.onConnectError((data) {
      if (connectionStatus != Connection.disconnected) {
        socket.disconnect();
      }
    });
    socket.onReconnect((data) {
      if (connectionStatus == Connection.disconnected) refresh();
    });
    socket.onDisconnect((data) {
      if (connectionStatus != Connection.disconnected) refresh();
    });
  }

  static ApiService getInstance() {
    _instance ??= ApiService._internal('');

    return _instance!;
  }

  Connection get connectionStatus => _connectionNotifier.value;

  Map<String, dynamic>? get serverInfoMap => _serverInfoNotifier.value;

  set refreshToken(String newRefreshToken) => _refreshToken = newRefreshToken;

  bool isConnected() => _connectionNotifier.value != Connection.disconnected;

  bool isAuthenticated() =>
      _connectionNotifier.value == Connection.authenticated;

  void dispose() {
    _instance = null;
    _connectionNotifier.value = Connection.undefined;
    _serverInfoNotifier.value = null;
    _client.close();
    socket.dispose();
  }

  void addListener(void Function() f) {
    _connectionNotifier.addListener(f);
  }

  void removeListener(void Function() f) {
    _connectionNotifier.removeListener(f);
  }

  void addInfoListener(void Function() f) {
    _serverInfoNotifier.addListener(f);
  }

  void removeInfoListener(void Function() f) {
    _serverInfoNotifier.removeListener(f);
  }

  static void setTokenRotationHandler(void Function(String) handler) {
    _handleTokenRotation = handler;
  }

  static void setTokenBeforeReauthHandler(
    Future<String?> Function(String?) handler,
  ) {
    _handleTokenBeforeReauth = handler;
  }

  static Future<void> connectTo(String url, {String? refreshToken}) async {
    getInstance().dispose();
    _instance = ApiService._internal(url);
    _instance!.refreshToken = refreshToken ?? '';
    await _instance!.refresh();
  }

  Future<void> refresh() {
    _refreshThread ??= _refresh();

    return _refreshThread!;
  }

  Future<void> _refresh() async {
    Connection status = Connection.disconnected;
    if (baseUrl.isNotEmpty) {
      final healthy = await getInstance().healthy();
      _serverInfoNotifier.value = healthy.item2;
      if (healthy.item1) {
        if (healthy.item2 != null &&
            healthy.item2!['min_frontend_version'] <=
                (int.tryParse((await Config.packageInfo)?.buildNumber ?? '0') ??
                    0) &&
            (healthy.item2!['version'] ?? 0) >= Config.MIN_BACKEND_VERSION) {
          await getInstance().refreshAuth()
              ? status = Connection.authenticated
              : status = Connection.connected;
        } else {
          status = healthy.item2 == null ||
                  (healthy.item2!['version'] ?? 0) < Config.MIN_BACKEND_VERSION
              ? Connection.unsupportedBackend
              : Connection.unsupportedFrontend;
        }
      }
    }

    getInstance()._setConnectionState(status);
    _refreshThread = null;
  }

  Future<http.Response> get(String url, {bool refreshOnException = true}) =>
      _handleRequest(
        () => _client.get(Uri.parse(baseUrl + url), headers: headers),
        refreshOnException: refreshOnException,
      );

  Future<http.Response> post(
    String url,
    dynamic body, {
    Encoding? encoding,
    Duration? timeout,
  }) =>
      _handleRequest(
        timeout: timeout,
        () => _client.post(
          Uri.parse(baseUrl + url),
          body: body,
          headers: headers,
          encoding: encoding,
        ),
      );

  Future<http.Response> postBytes(String url, NamedByteArray array) =>
      _handleRequest(
        timeout: _TIMEOUT_FILE_UPLOAD,
        () async {
          final request =
              http.MultipartRequest('POST', Uri.parse(baseUrl + url));
          request.headers.addAll(headers);
          request.files.add(http.MultipartFile(
            'file',
            Stream.fromIterable([array.bytes]),
            array.bytes.lengthInBytes,
            filename: array.filename,
          ));

          return http.Response.fromStream(await _client.send(request));
        },
      );

  Future<http.Response> put(
    String url,
    dynamic body, {
    Encoding? encoding,
    Duration? timeout,
  }) =>
      _handleRequest(
        timeout: timeout,
        () => _client.put(
          Uri.parse(baseUrl + url),
          body: body,
          headers: headers,
          encoding: encoding,
        ),
      );

  Future<http.Response> delete(
    String url, {
    dynamic body,
    Encoding? encoding,
  }) =>
      _handleRequest(() async {
        final request = http.Request(
          'DELETE',
          Uri.parse(baseUrl + url),
        );
        request.headers.addAll(headers);
        if (encoding != null) request.encoding = encoding;
        if (body != null) request.body = body;

        return http.Response.fromStream(await _client.send(request));
      });

  Future<http.Response> _handleRequest(
    Future<http.Response> Function() request, {
    bool refreshOnException = true,
    Duration? timeout,
  }) async {
    try {
      http.Response response = await request().timeout(timeout ?? _TIMEOUT);

      if ((!isConnected() && refreshOnException) ||
          response.statusCode == 401) {
        await refresh();
        if (response.statusCode == 401 && isAuthenticated()) {
          response = await request();
        }
      }

      return response;
    } catch (e) {
      if (refreshOnException) await refresh();
    }

    return http.Response('', 500);
  }

  void _setConnectionState(Connection newState) {
    if (newState == Connection.authenticated && socket.disconnected) {
      socket.io.options?['extraHeaders'] = headers;
      socket.connect();
    } else if (newState != Connection.authenticated && !socket.disconnected) {
      socket.disconnect();
    }
    _connectionNotifier.value = newState;
  }

  Future<Tuple2<bool, Map<String, dynamic>?>> healthy() async {
    try {
      final res = await get(
        '/health/8M4F88S8ooi4sMbLBfkkV7ctWwgibW6V',
        refreshOnException: false,
      );
      if (res.statusCode == 200) {
        return Tuple2(
          jsonDecode(res.body)['msg'] == 'OK',
          jsonDecode(res.body),
        );
      } else {
        debugPrint("Health check: Response code ${res.statusCode}");
      }
    } catch (ex) {
      debugPrint("Health check: ${ex.toString()}");
    }

    return const Tuple2(false, null);
  }

  Future<bool> refreshAuth() async {
    if (_handleTokenBeforeReauth != null) {
      _refreshToken = await _handleTokenBeforeReauth!(_refreshToken);
    }
    if (_refreshToken == null || _refreshToken!.isEmpty) return false;
    final _headers = Map<String, String>.from(headers);
    _headers['Authorization'] = 'Bearer $_refreshToken';
    try {
      final res = await _client
          .get(
            Uri.parse('$baseUrl/auth/refresh'),
            headers: _headers,
          )
          .timeout(_TIMEOUT);

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        headers['Authorization'] = 'Bearer ${body['access_token']}';
        _refreshToken = body['refresh_token'];
        if (_handleTokenRotation != null) {
          _handleTokenRotation!(_refreshToken!);
        }
        _setConnectionState(Connection.authenticated);

        return true;
      }
    } catch (_) {}

    return false;
  }

  Future<String?> login(String username, String password) async {
    final res = await post(
      '/auth',
      jsonEncode({
        'username': username,
        'password': password,
        if (await Config.deviceName != null) 'device': await Config.deviceName,
      }),
    );
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      headers['Authorization'] = 'Bearer ${body['access_token']}';
      _refreshToken = body['refresh_token'];
      _setConnectionState(Connection.authenticated);

      return _refreshToken;
    }

    return null;
  }

  Future<bool> logout() async {
    if (isAuthenticated()) {
      final res = await delete('/auth');
      socket.disconnect();
      if (res.statusCode == 200) refreshToken = '';

      return res.statusCode == 200;
    }

    return true;
  }

  Future<bool> isOnboarding() async {
    final res = await get('/onboarding');
    if (res.statusCode != 200) return false;
    final body = jsonDecode(res.body);

    return body['onboarding'] as bool;
  }

  Future<(String?, String?)> signup({
    required String username,
    required String name,
    required String password,
    required String email,
  }) async {
    final Map<String, dynamic> sendBody = {
      'username': username,
      'name': name,
      'password': password,
      if (email.isNotEmpty) 'email': email,
      if (await Config.deviceName != null) 'device': await Config.deviceName,
    };

    final res = await post(
      '/auth/signup',
      jsonEncode(sendBody),
    );
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      headers['Authorization'] = 'Bearer ${body['access_token']}';
      _refreshToken = body['refresh_token'];
      _setConnectionState(Connection.authenticated);

      return (_refreshToken, null);
    }

    return (null, res.body);
  }

  Future<String?> onboarding(
    String username,
    String name,
    String password,
  ) async {
    if (!(await isOnboarding())) return null;
    final Map<String, dynamic> sendBody = {
      'username': username,
      'name': name,
      'password': password,
      if (await Config.deviceName != null) 'device': await Config.deviceName,
    };

    final res = await post(
      '/onboarding',
      jsonEncode(sendBody),
      timeout: _TIMEOUT_ONBOARDING,
    );
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      headers['Authorization'] = 'Bearer ${body['access_token']}';
      _refreshToken = body['refresh_token'];
      _setConnectionState(Connection.authenticated);

      return _refreshToken;
    }

    return null;
  }

  Future<String?> createLongLivedToken(String name) async {
    final res = await post('/auth/llt', jsonEncode({'device': name}));
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);

      return body['longlived_token'];
    }

    return null;
  }

  Future<bool> deleteLongLivedToken(Token token) async {
    final res = await delete('/auth/llt/${token.id}');

    return res.statusCode == 200;
  }

  Future<Map<String, String>?> getSupportedLanguages() async {
    final res = await get(
      '/health/8M4F88S8ooi4sMbLBfkkV7ctWwgibW6V/supported-languages',
    );
    if (res.statusCode != 200) return null;

    return Map<String, String>.from((jsonDecode(res.body)));
  }

  Future<(String?, String?)> loginOIDC(String state, String code) async {
    final res = await post(
      '/auth/callback',
      jsonEncode({
        'state': state,
        'code': code,
        if (await Config.deviceName != null) 'device': await Config.deviceName,
      }),
    );
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      headers['Authorization'] = 'Bearer ${body['access_token']}';
      _refreshToken = body['refresh_token'];
      _setConnectionState(Connection.authenticated);

      return (_refreshToken, null);
    }

    return (null, res.body);
  }

  Future<(String?, String?, String?)> getLoginOIDCUrl(
      [String? provider]) async {
    final res =
        await get('/auth/oidc${provider != null ? "?provider=$provider" : ""}');
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);

      return (
        body["login_url"] as String?,
        body["state"] as String?,
        body["nonce"] as String?
      );
    }

    return (null, null, null);
  }
}
