part of 'auth_bloc.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Check if user is already authenticated (on app start)
class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

/// Login with email and password
class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;

  const AuthLoginRequested({
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [email, password];
}

/// Login with an OAuth provider
class AuthOAuthLoginRequested extends AuthEvent {
  final OAuthService service;

  const AuthOAuthLoginRequested(this.service);

  @override
  List<Object?> get props => [service];
}

/// Register a new account
class AuthRegisterRequested extends AuthEvent {
  final String name;
  final String email;
  final String password;

  const AuthRegisterRequested({
    required this.name,
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [name, email, password];
}

/// Fetch user profile
class AuthProfileRequested extends AuthEvent {
  const AuthProfileRequested();
}

/// Logout
class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

/// Update user data in memory (e.g., after profile edit)
class AuthUserUpdated extends AuthEvent {
  final User user;
  const AuthUserUpdated(this.user);

  @override
  List<Object?> get props => [user];
}
