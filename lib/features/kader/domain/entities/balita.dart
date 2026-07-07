class Balita {
  const Balita({
    required this.id,
    required this.namaBalita,
    required this.namaIbu,
    this.tanggalLahir,
    this.jenisKelamin,
    this.latestWeight,
    this.latestHeight,
    this.latestMeasuredAt,
    this.nikBalita,
    this.nikIbu,
    this.alamat,
    this.penghasilan,
    this.jumlahKeluarga,
    this.posyanduId,
  });

  final int id;
  final String namaBalita;
  final String namaIbu;
  final String? tanggalLahir;
  final String? jenisKelamin;
  final double? latestWeight;
  final double? latestHeight;
  final String? latestMeasuredAt;
  final String? nikBalita;
  final String? nikIbu;
  final String? alamat;
  final int? penghasilan;
  final int? jumlahKeluarga;
  final int? posyanduId;
}
