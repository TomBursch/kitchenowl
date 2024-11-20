import 'package:flutter/services.dart';
import 'package:kitchenowl/models/nullable.dart';

import 'model.dart';

class ExpenseCategory extends Model {
  final int? id;
  final String name;
  final Color? color;
  final double? budget;

  const ExpenseCategory({this.id, this.name = "", this.color, this.budget});

  factory ExpenseCategory.fromJson(Map<String, dynamic> map) => ExpenseCategory(
        id: map['id'],
        name: map['name'] ?? "",
        budget: map['budget'],
        color: map['color'] != null ? Color(map['color']) : null,
      );

  @override
  List<Object?> get props => [id, name, color, budget];

  @override
  Map<String, dynamic> toJson() => {
        "name": name,
        "color": color?.value,
        "budget": budget,
      };

  @override
  Map<String, dynamic> toJsonWithId() => toJson()
    ..addAll({
      "id": id,
    });

  ExpenseCategory copyWith({
    String? name,
    Nullable<Color>? color,
    Nullable<double>? budget,
  }) =>
      ExpenseCategory(
        id: id,
        name: name ?? this.name,
        color: (color ?? Nullable(this.color)).value,
        budget: (budget ?? Nullable(this.budget)).value,
      );
}
