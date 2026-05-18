class MeasurementResult {
  const MeasurementResult({
    required this.id,
    required this.predictionStatus,
    this.riskLevel,
  });

  final int id;
  final String predictionStatus;
  final String? riskLevel;

  bool get predictionFailed => predictionStatus == 'gagal';
}
