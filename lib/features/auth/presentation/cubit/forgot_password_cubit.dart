import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news_app/features/auth/domain/usecases/request_otp_usecase.dart';
import 'package:news_app/features/auth/domain/usecases/reset_password_usecase.dart';

abstract class ForgotPasswordState extends Equatable {
  const ForgotPasswordState();

  @override
  List<Object?> get props => [];
}

class ForgotPasswordInitial extends ForgotPasswordState {}

class ForgotPasswordLoading extends ForgotPasswordState {}

class OTPRequestedSuccess extends ForgotPasswordState {
  final String verificationId;

  const OTPRequestedSuccess(this.verificationId);

  @override
  List<Object?> get props => [verificationId];
}

class PasswordResetSuccess extends ForgotPasswordState {}

class ForgotPasswordError extends ForgotPasswordState {
  final String message;

  const ForgotPasswordError(this.message);

  @override
  List<Object?> get props => [message];
}

class ForgotPasswordCubit extends Cubit<ForgotPasswordState> {
  final RequestOTPUseCase requestOTPUseCase;
  final ResetPasswordUseCase resetPasswordUseCase;

  ForgotPasswordCubit({
    required this.requestOTPUseCase,
    required this.resetPasswordUseCase,
  }) : super(ForgotPasswordInitial());

  Future<void> requestOTP(String phoneNumber) async {
    emit(ForgotPasswordLoading());
    final result = await requestOTPUseCase(phoneNumber);

    result.fold(
      (failure) => emit(ForgotPasswordError(failure.message)),
      (verificationId) => emit(OTPRequestedSuccess(verificationId)),
    );
  }

  Future<void> verifyOTPAndResetPassword({
    required String verificationId,
    required String smsCode,
    required String newPassword,
  }) async {
    emit(ForgotPasswordLoading());
    final result = await resetPasswordUseCase(
      ResetPasswordParams(
        verificationId: verificationId,
        smsCode: smsCode,
        newPassword: newPassword,
      ),
    );

    result.fold(
      (failure) => emit(ForgotPasswordError(failure.message)),
      (_) => emit(PasswordResetSuccess()),
    );
  }
}
