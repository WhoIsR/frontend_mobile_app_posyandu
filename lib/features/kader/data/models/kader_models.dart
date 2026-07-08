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
    super.latestWeight,
    super.latestHeight,
    super.latestMeasuredAt,
    super.nikBalita,
    super.nikIbu,
    super.alamat,
    super.penghasilan,
    super.jumlahKeluarga,
    super.posyanduId,
  });

  factory BalitaModel.fromJson(Map<String, dynamic> json) {
    return BalitaModel(
      id: _asInt(json['id']),
      namaBalita: json['nama_balita']?.toString() ?? '-',
      namaIbu: json['nama_ibu']?.toString() ?? '-',
      tanggalLahir: json['tanggal_lahir']?.toString(),
      jenisKelamin: json['jenis_kelamin']?.toString(),
      latestWeight: _asDouble(json['latest_weight']),
      latestHeight: _asDouble(json['latest_height']),
      latestMeasuredAt: json['latest_measured_at']?.toString(),
      nikBalita: json['nik_balita']?.toString(),
      nikIbu: json['nik_ibu']?.toString(),
      alamat: json['alamat']?.toString(),
      penghasilan: json['penghasilan'] != null
          ? _asInt(json['penghasilan'])
          : null,
      jumlahKeluarga: json['jumlah_keluarga'] != null
          ? _asInt(json['jumlah_keluarga'])
          : null,
      posyanduId: json['posyandu_id'] != null
          ? _asInt(json['posyandu_id'])
          : null,
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
    super.continuityMessage,
  });

  factory MeasurementResultModel.fromJson(Map<String, dynamic> json) {
    final prediction = json['hasil_prediksi'];
    final continuity = json['continuity_summary'];
    return MeasurementResultModel(
      id: _asInt(json['id']),
      predictionStatus: json['status_prediksi']?.toString() ?? 'menunggu',
      riskLevel:
          json['overall_risk_level']?.toString() ??
          json['risk_level']?.toString() ??
          (prediction is Map ? prediction['risk_level']?.toString() : null),
      continuityMessage: continuity is Map
          ? continuity['message']?.toString()
          : null,
    );
  }
}

class ScreeningItemModel extends ScreeningItem {
  const ScreeningItemModel({
    required super.id,
    required super.namaBalita,
    required super.predictionStatus,
    super.riskLevel,
    super.continuityLabel,
    super.continuityMessage,
    super.measurementHistory,
  });

  factory ScreeningItemModel.fromJson(Map<String, dynamic> json) {
    final continuity = json['continuity_summary'];
    return ScreeningItemModel(
      id: _asInt(json['id']),
      namaBalita: json['nama_balita']?.toString() ?? '-',
      predictionStatus: json['status_prediksi']?.toString() ?? 'menunggu',
      riskLevel:
          json['overall_risk_level']?.toString() ??
          json['risk_level']?.toString(),
      continuityLabel: continuity is Map
          ? continuity['label']?.toString()
          : null,
      continuityMessage: continuity is Map
          ? continuity['message']?.toString()
          : null,
      measurementHistory: continuity is Map
          ? _historyPoints(continuity['measurements'])
          : const [],
    );
  }
}

class AppNotificationModel extends AppNotification {
  const AppNotificationModel({
    required super.id,
    required super.title,
    required super.message,
    required super.type,
    super.data,
    super.isRead,
  });

  factory AppNotificationModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    return AppNotificationModel(
      id: _asInt(json['id']),
      title: json['judul']?.toString() ?? 'Notifikasi',
      message: json['pesan']?.toString() ?? '-',
      type: json['tipe']?.toString() ?? 'system',
      data: data is Map ? data.cast<String, Object?>() : const {},
      isRead: json['is_read'] == true || json['is_read']?.toString() == '1',
    );
  }
}

List<Map<String, dynamic>> paginatedRows(Map<String, dynamic> json) {
  return (json['data'] as List<dynamic>? ?? [])
      .whereType<Map>()
      .map((row) => row.cast<String, dynamic>())
      .toList();
}

List<MeasurementHistoryPoint> _historyPoints(Object? value) {
  if (value is! List) return const [];
  return value
      .whereType<Map>()
      .map((row) {
        return MeasurementHistoryPoint(
          visitLabel: row['visit_label']?.toString() ?? 'Kunjungan',
          measuredAt: row['tanggal_ukur']?.toString() ?? '-',
          weightKg: _asDouble(row['berat_badan']) ?? 0,
          heightCm: _asDouble(row['tinggi_badan']) ?? 0,
          weightDeltaKg: _asDouble(row['weight_delta_kg']),
          heightDeltaCm: _asDouble(row['height_delta_cm']),
        );
      })
      .toList(growable: false);
}

int _asInt(Object? value) {
  if (value is int) return value;
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double? _asDouble(Object? value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}
