import '../entities/auth_session.dart';
import '../repositories/auth_repository.dart';

class Login {
  const Login(this._repository);

  final AuthRepository _repository;

  Future<AuthSession> call(String nikNip, String password) {
    return _repository.login(nikNip, password);
  }
}
