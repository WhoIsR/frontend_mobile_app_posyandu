class Referral {
  const Referral({
    required this.id,
    required this.childId,
    required this.namaBalita,
    required this.namaIbu,
    required this.riskLevel,
    required this.status,
    this.tanggalLahir,
    this.beratBadan,
    this.tinggiBadan,
    this.tanggalUkur,
  });

  final int id;
  final int childId;
  final String namaBalita;
  final String namaIbu;
  final String riskLevel;
  final String status;
  final String? tanggalLahir;
  final double? beratBadan;
  final double? tinggiBadan;
  final String? tanggalUkur;
}
