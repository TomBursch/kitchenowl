import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/services/api/api_service.dart';

class PasswordResetCubit extends Cubit<PasswordResetState> {
  String? token;
  PasswordResetCubit(this.token)
      : super(token == null
            ? const PasswordResetErrorState()
            : const PasswordResetState());

  Future<void> resetPassword(String password) async {
    if (token != null &&
        await ApiService.getInstance().resetPassword(token!, password)) {
      emit(const PasswordResetSuccessState());
    } else {
      emit(const PasswordResetErrorState());
    }
  }
}

class PasswordResetState extends Equatable {
  const PasswordResetState();

  @override
  List<Object?> get props => [];
}

class PasswordResetErrorState extends PasswordResetState {
  const PasswordResetErrorState();
}

class PasswordResetSuccessState extends PasswordResetState {
  const PasswordResetSuccessState();
}
