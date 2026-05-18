class Balita {
  const Balita({
    required this.id,
    required this.namaBalita,
    required this.namaIbu,
    this.tanggalLahir,
    this.jenisKelamin,
  });

  final int id;
  final String namaBalita;
  final String namaIbu;
  final String? tanggalLahir;
  final String? jenisKelamin;
}
