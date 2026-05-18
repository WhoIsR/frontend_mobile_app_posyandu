import '../../../../core/network/api_client.dart';
import '../../../../core/token_store.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
    required TokenStore tokenStore,
    required ApiClient apiClient,
  }) : _remoteDataSource = remoteDataSource,
       _tokenStore = tokenStore,
       _apiClient = apiClient;

  final AuthRemoteDataSource _remoteDataSource;
  final TokenStore _tokenStore;
  final ApiClient _apiClient;

  @override
  Future<AuthSession> login(String nikNip, String password) async {
    final session = await _remoteDataSource.login(nikNip, password);
    await _tokenStore.write(session.token);
    return session;
  }

  @override
  Future<AppUser> currentUser() => _remoteDataSource.currentUser();

  @override
  Future<AppUser?> restoreSession() async {
    final token = await _tokenStore.read();
    if (token == null) return null;
    _apiClient.token = token;
    try {
      return await _remoteDataSource.currentUser();
    } catch (_) {
      await _tokenStore.clear();
      _apiClient.token = null;
      return null;
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _remoteDataSource.logout();
    } finally {
      await _tokenStore.clear();
      _apiClient.token = null;
    }
  }
}
