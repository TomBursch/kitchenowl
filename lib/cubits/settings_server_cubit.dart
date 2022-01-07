import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/models/tag.dart';
import 'package:kitchenowl/models/user.dart';
import 'package:kitchenowl/services/api/api_service.dart';

class SettingsServerCubit extends Cubit<SettingsServerState> {
  SettingsServerCubit() : super(const SettingsServerState([], {})) {
    refresh();
  }

  Future<void> refresh() async {
    emit(SettingsServerState(await ApiService.getInstance().getAllUsers(),
        await ApiService.getInstance().getAllTags()));
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

  Future<bool> addTag(String name) async {
    final res = ApiService.getInstance().addTag(Tag(name: name));
    refresh();
    return res;
  }

  Future<bool> deleteTag(Tag tag) async {
    final res = ApiService.getInstance().deleteTag(tag);
    refresh();
    return res;
  }
}

class SettingsServerState extends Equatable {
  final List<User> users;
  final Set<Tag> tags;

  const SettingsServerState(this.users, this.tags);

  @override
  List<Object> get props => [users, tags];
}
