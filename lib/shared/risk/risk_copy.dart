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
      'rendah' =>
        'Catatan hari ini terlihat aman. Tetap pantau di jadwal berikutnya.',
      'sedang' =>
        'Ada tanda yang perlu dipantau. Arahkan ibu untuk cek pola makan dan lanjutkan pemantauan.',
      'tinggi' =>
        'Perlu dilihat bidan. Sampaikan sebagai hasil pemantauan awal, bukan kesimpulan medis.',
      'gagal' =>
        'Pengukuran sudah tersimpan. Coba ulang prediksi saat koneksi lebih stabil.',
      _ => 'Pengukuran sudah tersimpan. Hasil sedang diproses.',
    };
  }
}
