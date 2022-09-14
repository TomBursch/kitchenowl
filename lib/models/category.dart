import 'model.dart';

class Category extends Model {
  final int? id;
  final String name;

  const Category({this.id, this.name = ""});

  factory Category.fromJson(Map<String, dynamic> map) => Category(
        id: map['id'],
        name: map['name'] ?? "",
      );

  @override
  List<Object?> get props => [id, name];

  @override
  Map<String, dynamic> toJson() => {
        "name": name,
      };

  Category copyWith({String? name}) => Category(
        id: id,
        name: name ?? this.name,
      );
}
