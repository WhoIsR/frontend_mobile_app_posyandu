import '../../../kader/data/models/kader_models.dart';
import '../../domain/entities/admin_account.dart';
import '../../domain/entities/admin_posyandu.dart';
import '../../domain/entities/admin_schedule.dart';

class AdminAccountModel extends AdminAccount {
  const AdminAccountModel({
    required super.id,
    required super.name,
    required super.nikNip,
    required super.role,
    required super.status,
    super.posyanduId,
  });

  factory AdminAccountModel.fromJson(Map<String, dynamic> json) {
    return AdminAccountModel(
      id: _asInt(json['id']),
      name: json['nama']?.toString() ?? '-',
      nikNip: json['nik_nip']?.toString() ?? '-',
      role: json['role']?.toString() ?? '-',
      status: json['status']?.toString() ?? '-',
      posyanduId: json['posyandu_id'] == null
          ? null
          : _asInt(json['posyandu_id']),
    );
  }
}

class AdminPosyanduModel extends AdminPosyandu {
  const AdminPosyanduModel({
    required super.id,
    required super.name,
    super.address,
    super.village,
    super.district,
  });

  factory AdminPosyanduModel.fromJson(Map<String, dynamic> json) {
    return AdminPosyanduModel(
      id: _asInt(json['id']),
      name: json['nama_posyandu']?.toString() ?? '-',
      address: json['alamat']?.toString(),
      village: json['desa']?.toString(),
      district: json['kecamatan']?.toString(),
    );
  }
}

class AdminScheduleModel extends AdminSchedule {
  const AdminScheduleModel({
    required super.id,
    required super.posyanduId,
    required super.date,
    super.startTime,
    super.endTime,
    super.location,
    super.note,
  });

  factory AdminScheduleModel.fromJson(Map<String, dynamic> json) {
    return AdminScheduleModel(
      id: _asInt(json['id']),
      posyanduId: _asInt(json['posyandu_id']),
      date: json['tanggal']?.toString() ?? '-',
      startTime: _shortTime(json['jam_mulai']),
      endTime: _shortTime(json['jam_selesai']),
      location: json['lokasi']?.toString(),
      note: json['keterangan']?.toString(),
    );
  }
}

class AdminSessionModel extends AdminSession {
  const AdminSessionModel({
    required super.id,
    required super.posyanduId,
    required super.date,
    required super.status,
    super.scheduleId,
  });

  factory AdminSessionModel.fromJson(Map<String, dynamic> json) {
    return AdminSessionModel(
      id: _asInt(json['id']),
      posyanduId: _asInt(json['posyandu_id']),
      date: json['tanggal']?.toString() ?? '-',
      status: json['status']?.toString() ?? '-',
      scheduleId: json['jadwal_posyandu_id'] == null
          ? null
          : _asInt(json['jadwal_posyandu_id']),
    );
  }
}

int _asInt(Object? value) {
  if (value is int) return value;
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

String? _shortTime(Object? value) {
  final text = value?.toString();
  if (text == null || text.isEmpty) return null;
  return text.length >= 5 ? text.substring(0, 5) : text;
}

List<Map<String, dynamic>> adminRows(Map<String, dynamic> json) =>
    paginatedRows(json);
