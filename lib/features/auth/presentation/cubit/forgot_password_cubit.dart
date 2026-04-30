import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news_app/features/auth/domain/usecases/request_otp_usecase.dart';
import 'package:news_app/features/auth/domain/usecases/reset_password_usecase.dart';
import 'package:news_app/features/auth/domain/usecases/verify_otp_usecase.dart';

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

class OTPVerifiedSuccess extends ForgotPasswordState {
  final String firebaseIdToken;

  const OTPVerifiedSuccess(this.firebaseIdToken);

  @override
  List<Object?> get props => [firebaseIdToken];
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
  final VerifyOTPUseCase verifyOTPUseCase;
  final ResetPasswordUseCase resetPasswordUseCase;

  ForgotPasswordCubit({
    required this.requestOTPUseCase,
    required this.verifyOTPUseCase,
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

  Future<void> verifyOTP({
    required String verificationId,
    required String smsCode,
  }) async {
    emit(ForgotPasswordLoading());
    final result = await verifyOTPUseCase(
      VerifyOTPParams(
        verificationId: verificationId,
        smsCode: smsCode,
      ),
    );

    result.fold(
      (failure) => emit(ForgotPasswordError(failure.message)),
      (firebaseIdToken) => emit(OTPVerifiedSuccess(firebaseIdToken)),
    );
  }

  Future<void> submitNewPassword({
    required String firebaseIdToken,
    required String newPassword,
  }) async {
    emit(ForgotPasswordLoading());
    final result = await resetPasswordUseCase(
      ResetPasswordParams(
        firebaseIdToken: firebaseIdToken,
        newPassword: newPassword,
      ),
    );

    result.fold(
      (failure) => emit(ForgotPasswordError(failure.message)),
      (_) => emit(PasswordResetSuccess()),
    );
  }
}
