class MeasurementResult {
  const MeasurementResult({
    required this.id,
    required this.predictionStatus,
    this.riskLevel,
    this.continuityMessage,
  });

  final int id;
  final String predictionStatus;
  final String? riskLevel;
  final String? continuityMessage;

  bool get predictionFailed => predictionStatus == 'gagal';
}
