import '../entities/app_user.dart';
import '../entities/auth_session.dart';

abstract class AuthRepository {
  Future<AuthSession> login(String nikNip, String password);
  Future<AppUser> currentUser();
  Future<AppUser?> restoreSession();
  Future<void> logout();
}
