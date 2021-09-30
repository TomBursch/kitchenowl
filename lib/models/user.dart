import 'package:kitchenowl/models/model.dart';

class User extends Model {
  final int id;
  final String username;
  final String name;
  final bool owner;

  final double balance;

  const User({
    this.id,
    this.name,
    this.username,
    this.owner = false,
    this.balance = 0,
  });

  factory User.fromJson(Map<String, dynamic> map) => User(
        id: map['id'],
        username: map['username'],
        name: map['name'],
        owner: map['owner'] ?? false,
        balance: map['expense_balance'],
      );

  @override
  List<Object> get props => [id, name, username, owner, balance];

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
      };
}
