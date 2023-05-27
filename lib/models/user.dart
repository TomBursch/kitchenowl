import 'package:kitchenowl/models/model.dart';
import 'package:kitchenowl/models/token.dart';

class User extends Model {
  final int id;
  final String username;
  final String name;
  final String? email;
  final String image;
  final bool serverAdmin;
  final List<Token>? tokens;

  const User({
    required this.id,
    required this.name,
    required this.username,
    this.email,
    this.image = "",
    this.serverAdmin = false,
    this.tokens,
  });

  factory User.fromJson(Map<String, dynamic> map) {
    List<Token>? tokens;
    if (map.containsKey('tokens')) {
      tokens = List.from(map['tokens'].map((e) => Token.fromJson(e)));
    }

    return User(
      id: map['id'],
      username: map['username'],
      name: map['name'],
      email: map['email'],
      image: map['photo'] ?? '',
      serverAdmin: map['admin'] ?? false,
      tokens: tokens,
    );
  }

  @override
  List<Object?> get props => [id, name, email, username, serverAdmin, tokens];

  @override
  Map<String, dynamic> toJson() => {
        "name": name,
        if (image.isNotEmpty) "photo": image,
      };

  @override
  Map<String, dynamic> toJsonWithId() => {
        "id": id,
        "username": username,
        "name": name,
        "admin": serverAdmin,
      };

  bool hasServerAdminRights() => serverAdmin;
}
