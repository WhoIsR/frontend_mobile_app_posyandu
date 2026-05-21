import 'dart:typed_data';

import '../../../../core/network/api_client.dart';
import '../../../kader/data/models/kader_models.dart';
import '../../../kader/domain/entities/app_notification.dart';
import '../models/bidan_models.dart';

class BidanRemoteDataSource {
  const BidanRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  Future<List<ReferralModel>> referrals({
    String search = '',
    String? status,
  }) async {
    final json = await _apiClient.getJson(
      '/rujukan',
      query: {
        if (search.trim().isNotEmpty) 'search': search.trim(),
        if (status != null && status.isNotEmpty) 'status': status,
      },
    );
    return paginatedRows(json).map(ReferralModel.fromJson).toList();
  }

  Future<ValidationResultModel> validateReferral({
    required int referralId,
    required String decision,
    required String note,
  }) async {
    final json = await _apiClient.postJson(
      '/rujukan/$referralId/validasi',
      body: {'keputusan': decision, 'catatan_bidan': note},
    );
    return ValidationResultModel.fromJson(json);
  }

  Future<void> distributePmt({
    required int validationId,
    required int childId,
    required int pmtId,
    required int quantity,
  }) async {
    await _apiClient.postJson(
      '/distribusi-pmt',
      body: {
        'validasi_medis_id': validationId,
        'balita_id': childId,
        'pmt_id': pmtId,
        'jumlah': quantity,
        'tanggal_distribusi': DateTime.now().toIso8601String().split('T').first,
      },
    );
  }

  Future<List<PmtStockModel>> pmtStock() async {
    final json = await _apiClient.getJson('/pmt');
    return paginatedRows(json).map(PmtStockModel.fromJson).toList();
  }

  Future<List<AppNotification>> notifications() async {
    final json = await _apiClient.getJson('/notifikasi');
    return notificationModels(json);
  }

  Future<Uint8List> downloadReport(
    String type, {
    String? startDate,
    String? endDate,
  }) {
    return _apiClient.download(
      '/laporan/$type',
      query: {
        if (startDate != null) 'start_date': startDate,
        if (endDate != null) 'end_date': endDate,
      },
    );
  }

  Future<void> markNotificationRead(int id) async {
    await _apiClient.postJson('/notifikasi/$id/read');
  }
}
