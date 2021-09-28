import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/models/user.dart';
import 'package:kitchenowl/services/api/api_service.dart';

class SettingsServerCubit extends Cubit<SettingsServerState> {
  SettingsServerCubit() : super(const SettingsServerState([])) {
    refresh();
  }

  Future<void> refresh() async {
    emit(SettingsServerState(await ApiService.getInstance().getAllUsers()));
  }

  Future<bool> createUser(String username, String name, String password) async {
    final res = ApiService.getInstance().createUser(username, name, password);
    refresh();
    return res;
  }

  Future<bool> deleteUser(User user) async {
    final res = ApiService.getInstance().removeUser(user);
    refresh();
    return res;
  }
}

class SettingsServerState extends Equatable {
  final List<User> users;

  const SettingsServerState(this.users);

  @override
  List<Object> get props => [users];
}
