import 'package:equatable/equatable.dart';

/// A genric class for wrapping nullables
/// This can be used in copyWith to allow assign null as a value
class Nullable<T> extends Equatable {
  final T? value;

  const Nullable(this.value);

  const Nullable.empty() : value = null;

  T? or(T? alternative) => value ?? alternative;

  @override
  List<Object?> get props => [value];

  @override
  bool? get stringify => true;
}
