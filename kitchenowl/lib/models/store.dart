import 'package:kitchenowl/models/model.dart';

class Store extends Model {
  final int? id;
  final String name;

  const Store({
    this.id,
    this.name = '',
  });

  factory Store.fromJson(Map<String, dynamic> map) {
    return Store(
      id: map['id'],
      name: map['name'],
    );
  }

  Store copyWith({
    String? name,
  }) =>
      Store(
        id: id,
        name: name ?? this.name,
      );

  @override
  List<Object?> get props => [id, name];

  @override
  String toString() {
    return name;
  }

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
