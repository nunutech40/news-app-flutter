import 'package:dartz/dartz.dart';
import 'package:news_app/core/error/failures.dart';

abstract class FirebaseOTPService {
  /// Request an OTP to be sent to the given phone number.
  /// Returns the verificationId string on success.
  Future<Either<Failure, String>> requestOTP(String phoneNumber);

  /// Verify the OTP entered by the user.
  /// Returns the Firebase ID Token string on success.
  Future<Either<Failure, String>> verifyOTP({
    required String verificationId,
    required String smsCode,
  });
}
