import 'package:kitchenowl/models/model.dart';

class ShoppingList extends Model {
  final int? id;
  final String name;

  const ShoppingList({this.id, required this.name});

  factory ShoppingList.fromJson(Map<String, dynamic> map) => ShoppingList(
        id: map['id'],
        name: map['name'],
      );

  ShoppingList copyWith({
    String? name,
  }) =>
      ShoppingList(
        id: id,
        name: name ?? this.name,
      );

  @override
  List<Object?> get props => [id, name];

  @override
  Map<String, dynamic> toJson() => {
        "name": name,
      };

  @override
  Map<String, dynamic> toJsonWithId() => toJson()
    ..addAll({
      "id": id,
    });
}
