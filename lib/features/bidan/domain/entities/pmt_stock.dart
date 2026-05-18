class PmtStock {
  const PmtStock({
    required this.id,
    required this.name,
    required this.stock,
    required this.minimumStock,
    required this.unit,
  });

  final int id;
  final String name;
  final int stock;
  final int minimumStock;
  final String unit;

  bool get isLow => stock < minimumStock;
}
