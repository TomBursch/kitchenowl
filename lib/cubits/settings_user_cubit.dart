import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/cubits/auth_cubit.dart';
import 'package:kitchenowl/models/user.dart';
import 'package:kitchenowl/services/api/api_service.dart';

class SettingsUserCubit extends Cubit<SettingsUserState> {
  final int userId;
  SettingsUserCubit(this.userId) : super(const SettingsUserState(null)) {
    refresh();
  }

  Future<void> refresh() async {
    User user;
    if (userId != null) {
      user = await ApiService.getInstance().getUserById(userId);
    } else {
      user = await ApiService.getInstance().getUser();
    }
    emit(SettingsUserState(user));
  }

  Future<void> updateUser({
    BuildContext context,
    String name,
    String username,
    String password,
  }) async {
    bool res = false;
    if (userId != null) {
      res = await ApiService.getInstance().updateUserById(
        userId,
        name: name,
        password: password,
      );
    } else {
      res = await ApiService.getInstance().updateUser(
        name: name,
        password: password,
      );
    }
    if (res) {
      if (userId == null &&
          context != null &&
          BlocProvider.of<AuthCubit>(context) != null) {
        BlocProvider.of<AuthCubit>(context).refreshUser();
      }
      await refresh();
    }
  }
}

class SettingsUserState extends Equatable {
  final User user;

  const SettingsUserState(this.user);

  @override
  List<Object> get props => [user];
}
