import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/cubits/auth_cubit.dart';
import 'package:kitchenowl/enums/update_enum.dart';
import 'package:kitchenowl/models/user.dart';
import 'package:kitchenowl/services/api/api_service.dart';

class SettingsUserCubit extends Cubit<SettingsUserState> {
  final int userId;
  SettingsUserCubit(this.userId)
      : super(const SettingsUserState(null, false, UpdateEnum.unchanged)) {
    refresh();
  }

  Future<void> refresh() async {
    User user;
    if (userId != null) {
      user = await ApiService.getInstance().getUserById(userId);
    } else {
      user = await ApiService.getInstance().getUser();
    }
    emit(state.copyWith(user: user, setAdmin: user?.admin));
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
        admin: (state.setAdmin != state.user.admin) ? state.setAdmin : null,
      );
    } else {
      res = await ApiService.getInstance().updateUser(
        name: name,
        password: password,
      );
    }
    if (res) {
      emit(state.copyWith(updateState: UpdateEnum.updated));
      if (userId == null &&
          context != null &&
          BlocProvider.of<AuthCubit>(context) != null) {
        BlocProvider.of<AuthCubit>(context).refreshUser();
      }
      await refresh();
    }
  }

  void setAdmin(bool newAdmin) {
    emit(state.copyWith(setAdmin: newAdmin));
  }
}

class SettingsUserState extends Equatable {
  final User user;
  final bool setAdmin;
  final UpdateEnum updateState;

  const SettingsUserState(this.user, this.setAdmin, this.updateState);

  @override
  List<Object> get props => [user, setAdmin, updateState];

  SettingsUserState copyWith(
          {User user, bool setAdmin, UpdateEnum updateState}) =>
      SettingsUserState(user ?? this.user, setAdmin ?? this.setAdmin,
          updateState ?? this.updateState);
}