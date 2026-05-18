import 'package:flutter/material.dart';

void main() {
  runApp(const PosyanduApp());
}

enum UserRole { kader, bidan }

class PosyanduApp extends StatelessWidget {
  const PosyanduApp({super.key, this.initialRole});

  final UserRole? initialRole;

  static const paper = Color(0xFFF8F4EC);
  static const surface = Color(0xFFFFFDF8);
  static const line = Color(0xFFDDD2C3);
  static const ink = Color(0xFF25231F);
  static const inkSoft = Color(0xFF5D594F);
  static const primary = Color(0xFF4E6F5C);
  static const primarySoft = Color(0xFFDDE8DE);
  static const bidanBlue = Color(0xFF4F6F86);
  static const attention = Color(0xFF9A6A2F);
  static const attentionSoft = Color(0xFFF1E2C9);
  static const review = Color(0xFF9A4E3A);
  static const reviewSoft = Color(0xFFF0D8D1);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Posyandu Desa',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: paper,
        colorScheme:
            ColorScheme.fromSeed(
              seedColor: primary,
              brightness: Brightness.light,
            ).copyWith(
              primary: primary,
              secondary: bidanBlue,
              surface: surface,
              outline: line,
            ),
        appBarTheme: const AppBarTheme(
          backgroundColor: surface,
          foregroundColor: ink,
          elevation: 0,
          centerTitle: false,
          surfaceTintColor: Colors.transparent,
        ),
        cardTheme: CardThemeData(
          color: surface,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: line),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: line),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: primary, width: 2),
          ),
        ),
      ),
      home: initialRole == null
          ? const LoginScreen()
          : RoleShell(role: initialRole!),
    );
  }
}

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 36),
            Text(
              'Posyandu Desa',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: PosyanduApp.ink,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Catatan tumbuh kembang dan tindak lanjut balita.',
              style: TextStyle(color: PosyanduApp.inkSoft, height: 1.4),
            ),
            const SizedBox(height: 32),
            const TextField(
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'NIK / NIP'),
            ),
            const SizedBox(height: 16),
            const TextField(
              obscureText: true,
              decoration: InputDecoration(labelText: 'Password'),
            ),
            const SizedBox(height: 24),
            FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                backgroundColor: PosyanduApp.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {},
              child: const Text('Masuk'),
            ),
            const SizedBox(height: 16),
            const Text(
              'Butuh bantuan akun? Hubungi bidan atau kader koordinator.',
              style: TextStyle(color: PosyanduApp.inkSoft),
            ),
          ],
        ),
      ),
    );
  }
}

class RoleShell extends StatelessWidget {
  const RoleShell({super.key, required this.role});

  final UserRole role;

  @override
  Widget build(BuildContext context) {
    final isKader = role == UserRole.kader;
    return Scaffold(
      appBar: AppBar(
        title: Text(isKader ? 'Beranda Kader' : 'Beranda Bidan'),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: PosyanduApp.line),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        destinations: isKader
            ? const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  label: 'Beranda',
                ),
                NavigationDestination(
                  icon: Icon(Icons.event_available_outlined),
                  label: 'Sesi',
                ),
                NavigationDestination(
                  icon: Icon(Icons.child_care_outlined),
                  label: 'Balita',
                ),
                NavigationDestination(
                  icon: Icon(Icons.fact_check_outlined),
                  label: 'Skrining',
                ),
                NavigationDestination(
                  icon: Icon(Icons.notifications_outlined),
                  label: 'Notifikasi',
                ),
              ]
            : const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  label: 'Beranda',
                ),
                NavigationDestination(
                  icon: Icon(Icons.assignment_late_outlined),
                  label: 'Rujukan',
                ),
                NavigationDestination(
                  icon: Icon(Icons.inventory_2_outlined),
                  label: 'PMT',
                ),
                NavigationDestination(
                  icon: Icon(Icons.description_outlined),
                  label: 'Laporan',
                ),
                NavigationDestination(
                  icon: Icon(Icons.notifications_outlined),
                  label: 'Notifikasi',
                ),
              ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [isKader ? const KaderContent() : const BidanContent()],
        ),
      ),
    );
  }
}

class KaderContent extends StatelessWidget {
  const KaderContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Selamat pagi, Bu Rini',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const Text(
          'Posyandu Melati 03',
          style: TextStyle(color: PosyanduApp.inkSoft),
        ),
        const SizedBox(height: 16),
        const StatusPanel(
          title: 'Sesi hari ini',
          subtitle: 'Melati 03 - 18 Mei 2026 | 08.00-11.00 | Balai Desa',
          accent: PosyanduApp.primary,
          child: PrimaryAction(label: 'Input Pengukuran'),
        ),
        const SizedBox(height: 16),
        const SectionTitle('Cari balita'),
        const TextField(
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.search),
            labelText: 'Cari nama balita, ibu, atau NIK',
          ),
        ),
        const SizedBox(height: 12),
        const ChildRow(
          name: 'Raka Pratama',
          meta: '31 bulan | Ibu: Wulan',
          status: 'Input',
        ),
        const ChildRow(
          name: 'Sari Wulandari',
          meta: '28 bulan | Ibu: Sinta',
          status: 'Tersimpan',
        ),
        const SizedBox(height: 16),
        const SectionTitle('Input pengukuran'),
        const MeasurementPanel(),
        const SizedBox(height: 16),
        const SectionTitle('Hasil Skrining Hari Ini'),
        const ScreeningRow(
          name: 'Raka Pratama',
          badge: 'Perlu perhatian',
          message:
              'Pertumbuhan anak perlu diperhatikan. Data akan ditinjau tenaga kesehatan.',
          color: PosyanduApp.attention,
          softColor: PosyanduApp.attentionSoft,
        ),
        const ScreeningRow(
          name: 'Nadia Putri',
          badge: 'Prediksi gagal',
          message:
              'Pengukuran tersimpan. Prediksi dapat dicoba ulang saat koneksi stabil.',
          color: PosyanduApp.inkSoft,
          softColor: PosyanduApp.line,
        ),
        const SizedBox(height: 16),
        const StatusPanel(
          title: 'Notifikasi',
          subtitle: 'PMT disetujui dan validasi selesai akan tampil di sini.',
          accent: PosyanduApp.bidanBlue,
          child: Text('Pengukuran tersimpan. Prediksi diproses di belakang.'),
        ),
      ],
    );
  }
}

class BidanContent extends StatelessWidget {
  const BidanContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rujukan masuk',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        const TextField(
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.search),
            labelText: 'Cari balita atau nama ibu',
          ),
        ),
        const SizedBox(height: 12),
        const ReferralRow(
          name: 'Raka Pratama',
          risk: 'Perlu perhatian',
          meta: 'Melati 03 | 31 bulan | TB 87.5',
        ),
        const ReferralRow(
          name: 'Dina Lestari',
          risk: 'Perlu ditinjau bidan',
          meta: 'Melati 02 | 22 bulan | TB 76.0',
        ),
        const SizedBox(height: 16),
        const SectionTitle('Validasi Medis'),
        const StatusPanel(
          title: 'Keputusan',
          subtitle:
              'Observasi, Konseling, PMT, Rujuk Puskesmas, atau Cek ulang data.',
          accent: PosyanduApp.bidanBlue,
          child: PrimaryAction(label: 'Simpan Validasi'),
        ),
        const SizedBox(height: 16),
        const SectionTitle('PMT'),
        const StockRow(
          name: 'Biskuit Balita',
          meta: 'Stok 18 dus | Minimum 10',
          status: 'Aman',
        ),
        const StockRow(
          name: 'Susu UHT',
          meta: 'Stok 7 kotak | Minimum 10',
          status: 'Stok menipis',
        ),
        const SizedBox(height: 16),
        const SectionTitle('Laporan PDF'),
        const ReportPicker(),
      ],
    );
  }
}

class StatusPanel extends StatelessWidget {
  const StatusPanel({
    super.key,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Color accent;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(8),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: PosyanduApp.inkSoft,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 12),
                    child,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MeasurementPanel extends StatelessWidget {
  const MeasurementPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Raka Pratama\n31 bulan | Laki-laki | Ibu: Wulan'),
            SizedBox(height: 12),
            TextField(
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Berat badan (kg)'),
            ),
            SizedBox(height: 12),
            TextField(
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Tinggi badan (cm)'),
            ),
            SizedBox(height: 12),
            PrimaryAction(label: 'Simpan & Lanjut'),
          ],
        ),
      ),
    );
  }
}

class ChildRow extends StatelessWidget {
  const ChildRow({
    super.key,
    required this.name,
    required this.meta,
    required this.status,
  });

  final String name;
  final String meta;
  final String status;

  @override
  Widget build(BuildContext context) {
    return _ListTileFrame(
      title: name,
      subtitle: meta,
      trailing: StatusBadge(
        label: status,
        color: PosyanduApp.primary,
        softColor: PosyanduApp.primarySoft,
      ),
    );
  }
}

class ScreeningRow extends StatelessWidget {
  const ScreeningRow({
    super.key,
    required this.name,
    required this.badge,
    required this.message,
    required this.color,
    required this.softColor,
  });

  final String name;
  final String badge;
  final String message;
  final Color color;
  final Color softColor;

  @override
  Widget build(BuildContext context) {
    return _ListTileFrame(
      title: name,
      subtitle: message,
      trailing: StatusBadge(label: badge, color: color, softColor: softColor),
    );
  }
}

class ReferralRow extends StatelessWidget {
  const ReferralRow({
    super.key,
    required this.name,
    required this.risk,
    required this.meta,
  });

  final String name;
  final String risk;
  final String meta;

  @override
  Widget build(BuildContext context) {
    return _ListTileFrame(
      title: name,
      subtitle: meta,
      trailing: StatusBadge(
        label: risk,
        color: PosyanduApp.review,
        softColor: PosyanduApp.reviewSoft,
      ),
    );
  }
}

class StockRow extends StatelessWidget {
  const StockRow({
    super.key,
    required this.name,
    required this.meta,
    required this.status,
  });

  final String name;
  final String meta;
  final String status;

  @override
  Widget build(BuildContext context) {
    return _ListTileFrame(
      title: name,
      subtitle: meta,
      trailing: StatusBadge(
        label: status,
        color: status == 'Aman' ? PosyanduApp.primary : PosyanduApp.attention,
        softColor: status == 'Aman'
            ? PosyanduApp.primarySoft
            : PosyanduApp.attentionSoft,
      ),
    );
  }
}

class ReportPicker extends StatelessWidget {
  const ReportPicker({super.key});

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Prediksi Risiko'),
            Text('Kehadiran Posyandu'),
            Text('Distribusi PMT'),
            SizedBox(height: 12),
            PrimaryAction(label: 'Download PDF'),
          ],
        ),
      ),
    );
  }
}

class _ListTileFrame extends StatelessWidget {
  const _ListTileFrame({
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(color: PosyanduApp.inkSoft),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            trailing,
          ],
        ),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    required this.softColor,
  });

  final String label;
  final Color color;
  final Color softColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 28),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: softColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class PrimaryAction extends StatelessWidget {
  const PrimaryAction({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        backgroundColor: PosyanduApp.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: () {},
      child: Text(label),
    );
  }
}
