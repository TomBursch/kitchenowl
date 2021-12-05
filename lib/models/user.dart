import 'package:kitchenowl/models/model.dart';

class User extends Model {
  final int id;
  final String username;
  final String name;
  final bool owner;
  final bool admin;

  final double balance;

  const User({
    this.id,
    this.name,
    this.username,
    this.owner = false,
    this.admin = false,
    this.balance = 0,
  });

  factory User.fromJson(Map<String, dynamic> map) => User(
        id: map['id'],
        username: map['username'],
        name: map['name'],
        owner: map['owner'] ?? false,
        admin: map['admin'] ?? false,
        balance: map['expense_balance'] ?? 0,
      );

  @override
  List<Object> get props => [id, name, username, owner, admin, balance];

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
