import 'dart:convert';

import 'package:kitchenowl/models/user.dart';
import 'package:kitchenowl/services/api/api_service.dart';

extension UserApi on ApiService {
  static const baseRoute = '/user';

  Future<User?> getUser() async {
    if (!isAuthenticated()) return null;
    final res = await get(baseRoute);
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);

      return User.fromJson(body);
    }

    return null;
  }

  Future<User?> getUserById(int userId) async {
    if (!isAuthenticated()) return null;
    final res = await get(baseRoute + '/$userId');
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);

      return User.fromJson(body);
    }

    return null;
  }

  Future<List<User>?> getAllUsers() async {
    if (!isAuthenticated()) return null;
    final res = await get(baseRoute + '/all');
    if (res.statusCode == 200) {
      final body = List.from(jsonDecode(res.body));

      return body.map((e) => User.fromJson(e)).toList();
    }

    return null;
  }

  Future<bool> updateUser({String? name, String? password}) async {
    if (!isAuthenticated()) return false;

    final body = {};
    if (name != null) body['name'] = name;
    if (password != null) body['password'] = password;

    final res = await post(baseRoute + '', jsonEncode(body));

    return res.statusCode == 200;
  }

  Future<bool> updateUserById(
    int userId, {
    String? name,
    String? password,
    bool? admin,
  }) async {
    if (!isAuthenticated()) return false;

    final body = {};
    if (name != null) body['name'] = name;
    if (password != null) body['password'] = password;
    if (admin != null) body['admin'] = admin;

    final res = await post(baseRoute + '/$userId', jsonEncode(body));

    return res.statusCode == 200;
  }

  Future<bool> createUser(String username, String name, String password) async {
    final res = await post(
      baseRoute + '/new',
      jsonEncode({
        'username': username,
        'name': name,
        'password': password,
      }),
    );

    return res.statusCode == 200;
  }

  Future<bool> removeUser(User user) async {
    final res = await delete(baseRoute + '/${user.id}');

    return res.statusCode == 200;
  }
}
