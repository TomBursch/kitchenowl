import 'package:flutter/services.dart';
import 'package:kitchenowl/models/nullable.dart';

import 'model.dart';

class ExpenseCategory extends Model {
  final int? id;
  final String name;
  final Color? color;

  const ExpenseCategory({this.id, this.name = "", this.color});

  factory ExpenseCategory.fromJson(Map<String, dynamic> map) => ExpenseCategory(
        id: map['id'],
        name: map['name'] ?? "",
        color: map['color'] != null ? Color(map['color']) : null,
      );

  @override
  List<Object?> get props => [id, name, color];

  @override
  Map<String, dynamic> toJson() => {
        "name": name,
        "color": color?.value,
      };

  @override
  Map<String, dynamic> toJsonWithId() => toJson()
    ..addAll({
      "id": id,
    });

  ExpenseCategory copyWith({String? name, Nullable<Color>? color}) =>
      ExpenseCategory(
        id: id,
        name: name ?? this.name,
        color: (color ?? Nullable(this.color)).value,
      );
}
