class RiskCopy {
  static String label(String? risk) {
    return switch (risk) {
      'rendah' => 'Risiko rendah',
      'sedang' => 'Perlu perhatian',
      'tinggi' => 'Perlu ditinjau bidan',
      'gagal' => 'Prediksi gagal',
      _ => 'Menunggu hasil',
    };
  }

  static String message(String? risk) {
    return switch (risk) {
      'rendah' => 'Pertumbuhan tercatat dalam risiko rendah.',
      'sedang' =>
        'Pertumbuhan anak perlu diperhatikan. Data akan ditinjau tenaga kesehatan.',
      'tinggi' =>
        'Data perlu ditinjau bidan. Ini skrining awal, bukan diagnosis.',
      'gagal' =>
        'Pengukuran tersimpan. Prediksi dapat dicoba ulang saat koneksi stabil.',
      _ => 'Pengukuran tersimpan. Prediksi diproses di belakang.',
    };
  }
}
