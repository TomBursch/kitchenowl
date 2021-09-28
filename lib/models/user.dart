import 'package:kitchenowl/models/model.dart';

class User extends Model {
  final int id;
  final String username;
  final String name;
  final bool owner;

  const User({this.id, this.name, this.username, this.owner = false});

  factory User.fromJson(Map<String, dynamic> map) => User(
        id: map['id'],
        username: map['username'],
        name: map['name'],
        owner: map['owner'] ?? false,
      );

  @override
  List<Object> get props => [id, name, username, owner];

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
