import '../../domain/entities/app_user.dart';

class AppUserModel extends AppUser {
  const AppUserModel({
    required super.id,
    required super.nama,
    required super.nikNip,
    required super.role,
    super.posyanduId,
  });

  factory AppUserModel.fromJson(Map<String, dynamic> json) {
    return AppUserModel(
      id: _asInt(json['id']),
      nama: json['nama']?.toString() ?? '-',
      nikNip: json['nik_nip']?.toString() ?? '-',
      role: json['role'] == 'bidan' ? UserRole.bidan : UserRole.kader,
      posyanduId: json['posyandu_id'] == null ? null : _asInt(json['posyandu_id']),
    );
  }
}

int _asInt(Object? value) {
  if (value is int) return value;
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
