import '../../../kader/data/models/kader_models.dart';
import '../../../kader/domain/entities/app_notification.dart';
import '../../domain/entities/pmt_stock.dart';
import '../../domain/entities/referral.dart';
import '../../domain/entities/validation_result.dart';

class ReferralModel extends Referral {
  const ReferralModel({
    required super.id,
    required super.namaBalita,
    required super.namaIbu,
    required super.riskLevel,
    required super.status,
  });

  factory ReferralModel.fromJson(Map<String, dynamic> json) {
    return ReferralModel(
      id: _asInt(json['id']),
      namaBalita: json['nama_balita']?.toString() ?? '-',
      namaIbu: json['nama_ibu']?.toString() ?? '-',
      riskLevel: json['risk_level']?.toString() ?? 'rendah',
      status: json['status_rujukan']?.toString() ?? '-',
    );
  }
}

class PmtStockModel extends PmtStock {
  const PmtStockModel({
    required super.id,
    required super.name,
    required super.stock,
    required super.minimumStock,
    required super.unit,
  });

  factory PmtStockModel.fromJson(Map<String, dynamic> json) {
    return PmtStockModel(
      id: _asInt(json['id']),
      name: json['nama_barang']?.toString() ?? '-',
      stock: _asInt(json['stok_saat_ini']),
      minimumStock: _asInt(json['stok_minimum']),
      unit: json['satuan']?.toString() ?? '',
    );
  }
}

class ValidationResultModel extends ValidationResult {
  const ValidationResultModel({
    required super.id,
    required super.referralId,
    required super.decision,
  });

  factory ValidationResultModel.fromJson(Map<String, dynamic> json) {
    return ValidationResultModel(
      id: _asInt(json['id']),
      referralId: _asInt(json['rujukan_id']),
      decision: json['keputusan']?.toString() ?? '-',
    );
  }
}

List<AppNotification> notificationModels(Map<String, dynamic> json) {
  return paginatedRows(json).map(AppNotificationModel.fromJson).toList();
}

int _asInt(Object? value) {
  if (value is int) return value;
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
