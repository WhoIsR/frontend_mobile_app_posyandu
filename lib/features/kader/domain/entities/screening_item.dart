class ScreeningItem {
  const ScreeningItem({
    required this.id,
    required this.namaBalita,
    required this.predictionStatus,
    this.riskLevel,
    this.continuityLabel,
    this.continuityMessage,
    this.measurementHistory = const [],
  });

  final int id;
  final String namaBalita;
  final String predictionStatus;
  final String? riskLevel;
  final String? continuityLabel;
  final String? continuityMessage;
  final List<MeasurementHistoryPoint> measurementHistory;
}

class MeasurementHistoryPoint {
  const MeasurementHistoryPoint({
    required this.visitLabel,
    required this.measuredAt,
    required this.weightKg,
    required this.heightCm,
    this.weightDeltaKg,
    this.heightDeltaCm,
  });

  final String visitLabel;
  final String measuredAt;
  final double weightKg;
  final double heightCm;
  final double? weightDeltaKg;
  final double? heightDeltaCm;
}
