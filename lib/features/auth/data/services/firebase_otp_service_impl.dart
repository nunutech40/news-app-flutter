import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:news_app/core/error/failures.dart';
import 'package:news_app/features/auth/domain/services/firebase_otp_service.dart';

class FirebaseOTPServiceImpl implements FirebaseOTPService {
  final FirebaseAuth _firebaseAuth;

  FirebaseOTPServiceImpl({FirebaseAuth? firebaseAuth})
      : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  @override
  Future<Either<Failure, String>> requestOTP(String phoneNumber) async {
    final completer = Completer<Either<Failure, String>>();

    try {
      await _firebaseAuth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) {
          // This callback is triggered automatically on Android if SMS is auto-retrieved.
          // Since we want the user to go through the UI flow, we usually don't 
          // resolve the future here, or we can handle auto-sign-in later.
        },
        verificationFailed: (FirebaseAuthException e) {
          if (!completer.isCompleted) {
            completer.complete(Left(ServerFailure(message: e.message ?? 'Phone verification failed')));
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          if (!completer.isCompleted) {
            completer.complete(Right(verificationId));
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          // Auto-retrieval timeout
        },
      );

      return await completer.future;
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> verifyOTP({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      // Sign in to Firebase to get the ID Token
      final userCredential = await _firebaseAuth.signInWithCredential(credential);
      final idToken = await userCredential.user?.getIdToken(true);

      if (idToken != null) {
        return Right(idToken);
      } else {
        return const Left(ServerFailure(message: 'Failed to retrieve Firebase ID Token'));
      }
    } on FirebaseAuthException catch (e) {
      return Left(ServerFailure(message: e.message ?? 'Invalid OTP code'));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
