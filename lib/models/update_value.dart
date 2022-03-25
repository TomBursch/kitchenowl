import 'package:equatable/equatable.dart';
import 'package:kitchenowl/enums/update_enum.dart';

class UpdateValue<T> extends Equatable {
  final UpdateEnum state;
  final T? data;

  const UpdateValue(this.state, [this.data]);

  @override
  List<Object?> get props => [state, data];
}
