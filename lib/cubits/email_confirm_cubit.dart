import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/services/api/api_service.dart';

class EmailConfirmCubit extends Cubit<EmailConfirmState> {
  String? token;
  EmailConfirmCubit(this.token) : super(const EmailConfirmState()) {
    confirm();
  }

  Future<void> confirm() async {
    if (token != null && await ApiService.getInstance().confirmMail(token!)) {
      emit(const EmailConfirmSuccessState());
    } else {
      emit(const EmailConfirmErrorState());
    }
  }
}

class EmailConfirmState extends Equatable {
  const EmailConfirmState();

  @override
  List<Object?> get props => [];
}

class EmailConfirmErrorState extends EmailConfirmState {
  const EmailConfirmErrorState();
}

class EmailConfirmSuccessState extends EmailConfirmState {
  const EmailConfirmSuccessState();
}
