class CreateBalitaRequest {
  const CreateBalitaRequest({
    required this.namaBalita,
    this.nikBalita,
    required this.tanggalLahir,
    required this.jenisKelamin,
    required this.namaIbu,
    this.nikIbu,
    required this.alamat,
    required this.penghasilan,
    required this.jumlahKeluarga,
    required this.posyanduId,
  });

  final String namaBalita;
  final String? nikBalita;
  final String tanggalLahir;
  final String jenisKelamin;
  final String namaIbu;
  final String? nikIbu;
  final String alamat;
  final int penghasilan;
  final int jumlahKeluarga;
  final int posyanduId;
}
