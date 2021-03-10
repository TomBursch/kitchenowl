import 'package:equatable/equatable.dart';

abstract class Model implements Equatable {
  const Model();

  Map<String, dynamic> toJson();

  Map<String, dynamic> toJsonWithId() => this.toJson();

  @override
  bool get stringify => true;
}
