import 'package:kitchenowl/models/model.dart';
import 'package:kitchenowl/models/token.dart';

class User extends Model {
  final int id;
  final String username;
  final String name;
  final bool owner;
  final bool admin;
  final List<Token>? tokens;

  final double balance;

  const User({
    required this.id,
    required this.name,
    required this.username,
    this.owner = false,
    this.admin = false,
    this.tokens,
    this.balance = 0,
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
      owner: map['owner'] ?? false,
      admin: map['admin'] ?? false,
      balance: map['expense_balance'] ?? 0,
      tokens: tokens,
    );
  }

  @override
  List<Object?> get props =>
      [id, name, username, owner, admin, balance, tokens];

  @override
  Map<String, dynamic> toJson() => {
        "name": name,
      };

  @override
  Map<String, dynamic> toJsonWithId() => {
        "id": id,
        "username": username,
        "name": name,
        "owner": owner,
        "admin": admin,
        "expense_balance": balance,
      };

  bool hasAdminRights() => admin || owner;
}
