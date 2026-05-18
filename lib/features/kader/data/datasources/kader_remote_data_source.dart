import '../../../../core/network/api_client.dart';
import '../models/kader_models.dart';

class KaderRemoteDataSource {
  const KaderRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  Future<PosyanduSessionModel?> activeSession() async {
    final json = await _apiClient.getJson('/sesi/aktif');
    return json.isEmpty ? null : PosyanduSessionModel.fromJson(json);
  }

  Future<List<BalitaModel>> children({String search = ''}) async {
    final json = await _apiClient.getJson('/balita', query: {
      if (search.trim().isNotEmpty) 'search': search.trim(),
      'per_page': '10',
    });
    return paginatedRows(json).map(BalitaModel.fromJson).toList();
  }

  Future<MeasurementResultModel> saveMeasurement({
    required int sessionId,
    required int childId,
    required double weight,
    required double height,
  }) async {
    final json = await _apiClient.postJson('/pengukuran', body: {
      'sesi_posyandu_id': sessionId,
      'balita_id': childId,
      'berat_badan': weight,
      'tinggi_badan': height,
    });
    return MeasurementResultModel.fromJson(json);
  }

  Future<MeasurementResultModel> retryPrediction(int measurementId) async {
    final json = await _apiClient.postJson(
      '/pengukuran/$measurementId/retry-prediksi',
    );
    return MeasurementResultModel.fromJson(json);
  }

  Future<List<ScreeningItemModel>> screening(int sessionId) async {
    final json = await _apiClient.getJson('/sesi/$sessionId/skrining');
    return paginatedRows(json).map(ScreeningItemModel.fromJson).toList();
  }

  Future<List<AppNotificationModel>> notifications() async {
    final json = await _apiClient.getJson('/notifikasi');
    return paginatedRows(json).map(AppNotificationModel.fromJson).toList();
  }
}
