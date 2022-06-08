import 'package:kitchenowl/enums/token_type_enum.dart';
import 'package:kitchenowl/models/model.dart';

class Token extends Model {
  final int id;
  final String name;
  final TokenTypeEnum type;

  const Token({
    required this.id,
    this.name = '',
    required this.type,
  });

  factory Token.fromJson(Map<String, dynamic> map) {
    final TokenTypeEnum type;
    if (map['type'] == 'refresh') {
      type = TokenTypeEnum.refresh;
    } else if (map['type'] == 'llt') {
      type = TokenTypeEnum.longlived;
    } else {
      type = TokenTypeEnum.access;
    }

    return Token(
      id: map['id'],
      name: map['name'],
      type: type,
    );
  }

  Token copyWith({
    String? name,
  }) =>
      Token(
        id: id,
        name: name ?? this.name,
        type: type,
      );

  @override
  List<Object?> get props => [id, name, type];

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
