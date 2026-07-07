import '../../../../core/network/api_client.dart';
import '../../domain/entities/create_balita_request.dart';
import '../models/kader_models.dart';

class KaderRemoteDataSource {
  const KaderRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  Future<PosyanduSessionModel?> activeSession() async {
    final json = await _apiClient.getJson('/sesi/aktif');
    return json.isEmpty ? null : PosyanduSessionModel.fromJson(json);
  }

  Future<List<BalitaModel>> children({String search = ''}) async {
    final json = await _apiClient.getJson(
      '/balita',
      query: {
        if (search.trim().isNotEmpty) 'search': search.trim(),
        'per_page': '10',
      },
    );
    return paginatedRows(json).map(BalitaModel.fromJson).toList();
  }

  Future<BalitaModel> createBalita(CreateBalitaRequest request) async {
    final json = await _apiClient.postJson(
      '/balita',
      body: {
        'nama_balita': request.namaBalita,
        if (request.nikBalita?.trim().isNotEmpty ?? false)
          'nik_balita': request.nikBalita!.trim(),
        'tanggal_lahir': request.tanggalLahir,
        'jenis_kelamin': request.jenisKelamin,
        'nama_ibu': request.namaIbu,
        if (request.nikIbu?.trim().isNotEmpty ?? false)
          'nik_ibu': request.nikIbu!.trim(),
        'alamat': request.alamat,
        'penghasilan': request.penghasilan,
        'jumlah_keluarga': request.jumlahKeluarga,
        'posyandu_id': request.posyanduId,
      },
    );
    return BalitaModel.fromJson(json);
  }

  Future<BalitaModel> updateBalita(int id, CreateBalitaRequest request) async {
    final json = await _apiClient.putJson(
      '/balita/$id',
      body: {
        'nama_balita': request.namaBalita,
        'nik_balita': request.nikBalita?.trim().isNotEmpty ?? false
            ? request.nikBalita!.trim()
            : null,
        'tanggal_lahir': request.tanggalLahir,
        'jenis_kelamin': request.jenisKelamin,
        'nama_ibu': request.namaIbu,
        'nik_ibu': request.nikIbu?.trim().isNotEmpty ?? false
            ? request.nikIbu!.trim()
            : null,
        'alamat': request.alamat,
        'penghasilan': request.penghasilan,
        'jumlah_keluarga': request.jumlahKeluarga,
        'posyandu_id': request.posyanduId,
      },
    );
    return BalitaModel.fromJson(json);
  }

  Future<MeasurementResultModel> saveMeasurement({
    required int sessionId,
    required int childId,
    required double weight,
    required double height,
  }) async {
    final json = await _apiClient.postJson(
      '/pengukuran',
      body: {
        'sesi_posyandu_id': sessionId,
        'balita_id': childId,
        'berat_badan': weight,
        'tinggi_badan': height,
      },
    );
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

  Future<void> markNotificationRead(int id) async {
    await _apiClient.postJson('/notifikasi/$id/read');
  }
}
