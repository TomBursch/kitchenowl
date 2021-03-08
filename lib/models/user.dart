import 'package:kitchenowl/models/model.dart';

class User extends Model {
  final int id;
  final String username;
  final String name;
  final bool owner;

  const User({this.id, this.name, this.username, this.owner = false});

  factory User.fromJson(Map<String, dynamic> map) => User(
        id: map['id'],
        name: map['name'],
        username: map['username'],
        owner: map['owner'] ?? false,
      );

  @override
  List<Object> get props => [this.id, this.name, this.username, this.owner];

  @override
  Map<String, dynamic> toJson() => {
        "name": this.id,
      };
}
