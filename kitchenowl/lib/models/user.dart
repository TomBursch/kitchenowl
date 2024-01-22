import 'package:kitchenowl/enums/oidc_provider.dart';
import 'package:kitchenowl/models/model.dart';
import 'package:kitchenowl/models/token.dart';

class User extends Model {
  final int id;
  final String username;
  final String name;
  final String? email;
  final bool emailVerified;
  final String? image;
  final bool serverAdmin;
  final List<Token>? tokens;
  final List<OIDCProivder> oidcLinks;

  const User({
    required this.id,
    required this.name,
    required this.username,
    this.email,
    this.image,
    this.emailVerified = false,
    this.serverAdmin = false,
    this.tokens,
    this.oidcLinks = const [],
  });

  factory User.fromJson(Map<String, dynamic> map) {
    List<Token>? tokens;
    if (map.containsKey('tokens')) {
      tokens = List.from(map['tokens'].map((e) => Token.fromJson(e)));
    }
    List<OIDCProivder> oidcLinks = const [];
    if (map.containsKey('oidc_links')) {
      oidcLinks = List.from(map['oidc_links']
          .map((e) => OIDCProivder.parse(e))
          .where((e) => e != null));
    }

    return User(
      id: map['id'],
      username: map['username'],
      name: map['name'],
      email: map['email'],
      emailVerified: map['email_verified'] ?? false,
      image: map['photo'],
      serverAdmin: map['admin'] ?? false,
      tokens: tokens,
      oidcLinks: oidcLinks,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        email,
        emailVerified,
        username,
        serverAdmin,
        tokens,
        oidcLinks,
      ];

  @override
  Map<String, dynamic> toJson() => {
        "name": name,
        if (image != null) "photo": image,
      };

  @override
  Map<String, dynamic> toJsonWithId() => {
        "id": id,
        "username": username,
        "email_verified": emailVerified,
        "name": name,
        "admin": serverAdmin,
        "oidc_links": oidcLinks.map((e) => e.toString()).toList(),
      };

  bool hasServerAdminRights() => serverAdmin;
}
