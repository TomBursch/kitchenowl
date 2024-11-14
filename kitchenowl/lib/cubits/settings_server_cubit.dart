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
      state.filter,
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
    final res = await ApiService.getInstance().deleteUser(user);
    refresh();

    return res;
  }

  void filter(String query) {
    emit(
      state.copyWith(
        filter: query,
      ),
    );
  }
}

class SettingsServerState extends Equatable {
  final List<User> users;
  final String filter;

  const SettingsServerState(
    this.users, [
    this.filter = "",
  ]);

  SettingsServerState copyWith({
    List<User>? users,
    String? filter,
  }) =>
      SettingsServerState(
        users ?? this.users,
        filter ?? this.filter,
      );

  @override
  List<Object?> get props => [users, filter];
}

class LoadingSettingsServerState extends SettingsServerState {
  const LoadingSettingsServerState(super.users);

  @override
  SettingsServerState copyWith({
    List<User>? users,
    String? filter,
  }) =>
      LoadingSettingsServerState(
        users ?? this.users,
      );
}
