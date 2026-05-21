import 'dart:typed_data';

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

  Future<List<AdminScheduleModel>> schedules() async {
    final json = await _apiClient.getJson(
      '/jadwal',
      query: {'per_page': '100'},
    );
    return adminRows(json).map(AdminScheduleModel.fromJson).toList();
  }

  Future<AdminSessionModel?> activeSession() async {
    final json = await _apiClient.getJson('/sesi/aktif');
    return json.isEmpty ? null : AdminSessionModel.fromJson(json);
  }

  Future<AdminAccountModel> saveAccount({
    int? id,
    required String name,
    required String nikNip,
    String? password,
    required String role,
    int? posyanduId,
    required String status,
  }) async {
    final body = {
      'nama': name,
      'nik_nip': nikNip,
      if (password?.isNotEmpty ?? false) 'password': password,
      'role': role,
      'posyandu_id': posyanduId,
      'status': status,
    };
    final json = id == null
        ? await _apiClient.postJson('/admin/users', body: body)
        : await _apiClient.putJson('/admin/users/$id', body: body);
    return AdminAccountModel.fromJson(json);
  }

  Future<AdminPosyanduModel> savePosyandu({
    int? id,
    required String name,
    required String address,
    required String village,
    required String district,
  }) async {
    final body = {
      'nama_posyandu': name,
      'alamat': address,
      'desa': village,
      'kecamatan': district,
      'bidan_id': null,
    };
    final json = id == null
        ? await _apiClient.postJson('/admin/posyandu', body: body)
        : await _apiClient.putJson('/admin/posyandu/$id', body: body);
    return AdminPosyanduModel.fromJson(json);
  }

  Future<AdminScheduleModel> saveSchedule({
    int? id,
    required int posyanduId,
    required String date,
    required String startTime,
    required String endTime,
    required String location,
    required String note,
  }) async {
    final body = {
      'posyandu_id': posyanduId,
      'tanggal': date,
      if (startTime.isNotEmpty) 'jam_mulai': startTime,
      if (endTime.isNotEmpty) 'jam_selesai': endTime,
      'lokasi': location,
      if (note.isNotEmpty) 'keterangan': note,
    };
    final json = id == null
        ? await _apiClient.postJson('/jadwal', body: body)
        : await _apiClient.putJson('/jadwal/$id', body: body);
    return AdminScheduleModel.fromJson(json);
  }

  Future<AdminSessionModel> startSession({
    int? scheduleId,
    required int posyanduId,
    required String date,
  }) async {
    final json = await _apiClient.postJson(
      '/sesi',
      body: {
        'jadwal_posyandu_id': scheduleId,
        'posyandu_id': posyanduId,
        'tanggal': date,
      },
    );
    return AdminSessionModel.fromJson(json);
  }

  Future<AdminSessionModel> closeSession(int id) async {
    final json = await _apiClient.postJson('/sesi/$id/selesai');
    return AdminSessionModel.fromJson(json);
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
}
