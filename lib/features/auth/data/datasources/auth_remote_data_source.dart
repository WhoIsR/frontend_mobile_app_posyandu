import '../../../../core/network/api_client.dart';
import '../models/app_user_model.dart';
import '../models/auth_session_model.dart';

class AuthRemoteDataSource {
  const AuthRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  Future<AuthSessionModel> login(String nikNip, String password) async {
    final json = await _apiClient.postJson(
      '/login',
      authenticated: false,
      body: {'nik_nip': nikNip, 'password': password},
    );
    final session = AuthSessionModel.fromJson(json);
    _apiClient.token = session.token;
    return session;
  }

  Future<AppUserModel> currentUser() async {
    return AppUserModel.fromJson(await _apiClient.getJson('/me'));
  }

  Future<void> logout() async {
    await _apiClient.postJson('/logout');
    _apiClient.token = null;
  }
}
