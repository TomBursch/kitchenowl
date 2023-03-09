import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/models/user.dart';
import 'package:kitchenowl/services/api/api_service.dart';

class SettingsServerCubit extends Cubit<SettingsServerState> {
  SettingsServerCubit() : super(const LoadingSettingsServerState([])) {
    refresh();
  }

  Future<void> refresh() async {
    Future<List<User>?> users = ApiService.getInstance().getAllUsers();

    emit(SettingsServerState(
      await users ?? [],
    ));
  }

  Future<bool> createUser(String username, String name, String password) async {
    if (username.isNotEmpty && name.isNotEmpty && password.isNotEmpty) {
      final res =
          await ApiService.getInstance().createUser(username, name, password);
      refresh();

      return res;
    }

    return false;
  }

  Future<bool> deleteUser(User user) async {
    final res = await ApiService.getInstance().removeUser(user);
    refresh();

    return res;
  }
}

class SettingsServerState extends Equatable {
  final List<User> users;

  const SettingsServerState(
    this.users,
  );

  SettingsServerState copyWith({
    List<User>? users,
  }) =>
      SettingsServerState(
        users ?? this.users,
      );

  @override
  List<Object?> get props => [users];
}

class LoadingSettingsServerState extends SettingsServerState {
  const LoadingSettingsServerState(super.users);

  @override
  SettingsServerState copyWith({
    List<User>? users,
  }) =>
      LoadingSettingsServerState(
        users ?? this.users,
      );
}
