class AdminPosyandu {
  const AdminPosyandu({
    required this.id,
    required this.name,
    this.address,
    this.village,
    this.district,
  });

  final int id;
  final String name;
  final String? address;
  final String? village;
  final String? district;
}
