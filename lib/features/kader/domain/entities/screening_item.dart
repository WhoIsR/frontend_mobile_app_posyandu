class ScreeningItem {
  const ScreeningItem({
    required this.id,
    required this.namaBalita,
    required this.predictionStatus,
    this.riskLevel,
    this.continuityLabel,
    this.continuityMessage,
  });

  final int id;
  final String namaBalita;
  final String predictionStatus;
  final String? riskLevel;
  final String? continuityLabel;
  final String? continuityMessage;
}
