class ScreeningItem {
  const ScreeningItem({
    required this.id,
    required this.namaBalita,
    required this.predictionStatus,
    this.riskLevel,
  });

  final int id;
  final String namaBalita;
  final String predictionStatus;
  final String? riskLevel;
}
