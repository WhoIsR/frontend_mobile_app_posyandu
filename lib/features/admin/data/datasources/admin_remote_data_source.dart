import '../../../../core/network/api_client.dart';
import '../models/admin_models.dart';

class AdminRemoteDataSource {
  const AdminRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  Future<List<AdminAccountModel>> accounts() async {
    final json = await _apiClient.getJson(
      '/admin/users',
      query: {'per_page': '100'},
    );
    return adminRows(json).map(AdminAccountModel.fromJson).toList();
  }

  Future<List<AdminPosyanduModel>> posyandu() async {
    final json = await _apiClient.getJson(
      '/admin/posyandu',
      query: {'per_page': '100'},
    );
    return adminRows(json).map(AdminPosyanduModel.fromJson).toList();
  }
}
