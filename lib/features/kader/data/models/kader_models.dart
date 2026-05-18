import '../../domain/entities/app_notification.dart';
import '../../domain/entities/balita.dart';
import '../../domain/entities/measurement_result.dart';
import '../../domain/entities/posyandu_session.dart';
import '../../domain/entities/screening_item.dart';

class BalitaModel extends Balita {
  const BalitaModel({
    required super.id,
    required super.namaBalita,
    required super.namaIbu,
    super.tanggalLahir,
    super.jenisKelamin,
  });

  factory BalitaModel.fromJson(Map<String, dynamic> json) {
    return BalitaModel(
      id: _asInt(json['id']),
      namaBalita: json['nama_balita']?.toString() ?? '-',
      namaIbu: json['nama_ibu']?.toString() ?? '-',
      tanggalLahir: json['tanggal_lahir']?.toString(),
      jenisKelamin: json['jenis_kelamin']?.toString(),
    );
  }
}

class PosyanduSessionModel extends PosyanduSession {
  const PosyanduSessionModel({
    required super.id,
    required super.posyanduId,
    required super.tanggal,
    required super.status,
  });

  factory PosyanduSessionModel.fromJson(Map<String, dynamic> json) {
    return PosyanduSessionModel(
      id: _asInt(json['id']),
      posyanduId: _asInt(json['posyandu_id']),
      tanggal: json['tanggal']?.toString() ?? '-',
      status: json['status']?.toString() ?? '-',
    );
  }
}

class MeasurementResultModel extends MeasurementResult {
  const MeasurementResultModel({
    required super.id,
    required super.predictionStatus,
    super.riskLevel,
  });

  factory MeasurementResultModel.fromJson(Map<String, dynamic> json) {
    final prediction = json['hasil_prediksi'];
    return MeasurementResultModel(
      id: _asInt(json['id']),
      predictionStatus: json['status_prediksi']?.toString() ?? 'menunggu',
      riskLevel: prediction is Map
          ? prediction['risk_level']?.toString()
          : json['risk_level']?.toString(),
    );
  }
}

class ScreeningItemModel extends ScreeningItem {
  const ScreeningItemModel({
    required super.id,
    required super.namaBalita,
    required super.predictionStatus,
    super.riskLevel,
  });

  factory ScreeningItemModel.fromJson(Map<String, dynamic> json) {
    return ScreeningItemModel(
      id: _asInt(json['id']),
      namaBalita: json['nama_balita']?.toString() ?? '-',
      predictionStatus: json['status_prediksi']?.toString() ?? 'menunggu',
      riskLevel: json['risk_level']?.toString(),
    );
  }
}

class AppNotificationModel extends AppNotification {
  const AppNotificationModel({required super.title, required super.message});

  factory AppNotificationModel.fromJson(Map<String, dynamic> json) {
    return AppNotificationModel(
      title: json['judul']?.toString() ?? 'Notifikasi',
      message: json['pesan']?.toString() ?? '-',
    );
  }
}

List<Map<String, dynamic>> paginatedRows(Map<String, dynamic> json) {
  return (json['data'] as List<dynamic>? ?? [])
      .whereType<Map>()
      .map((row) => row.cast<String, dynamic>())
      .toList();
}

int _asInt(Object? value) {
  if (value is int) return value;
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
