import '../../../kader/data/models/kader_models.dart';
import '../../domain/entities/admin_account.dart';
import '../../domain/entities/admin_posyandu.dart';

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

int _asInt(Object? value) {
  if (value is int) return value;
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

List<Map<String, dynamic>> adminRows(Map<String, dynamic> json) =>
    paginatedRows(json);
