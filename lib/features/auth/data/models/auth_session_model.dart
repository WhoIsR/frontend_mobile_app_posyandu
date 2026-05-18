import '../../domain/entities/auth_session.dart';
import 'app_user_model.dart';

class AuthSessionModel extends AuthSession {
  const AuthSessionModel({required super.token, required super.user});

  factory AuthSessionModel.fromJson(Map<String, dynamic> json) {
    return AuthSessionModel(
      token: json['token']?.toString() ?? '',
      user: AppUserModel.fromJson((json['user'] as Map).cast<String, dynamic>()),
    );
  }
}
