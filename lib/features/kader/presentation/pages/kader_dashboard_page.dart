import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/ledger_theme.dart';
import '../../../../shared/risk/risk_copy.dart';
import '../../../../shared/widgets/ledger_widgets.dart';
import '../../domain/entities/balita.dart';
import '../../domain/entities/screening_item.dart';
import '../controllers/kader_dashboard_controller.dart';

class KaderDashboardPage extends ConsumerStatefulWidget {
  const KaderDashboardPage({super.key, this.focus});

  final String? focus;

  @override
  ConsumerState<KaderDashboardPage> createState() => _KaderDashboardPageState();
}

class _KaderDashboardPageState extends ConsumerState<KaderDashboardPage> {
  final _searchController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(kaderDashboardControllerProvider);
    if (state.isLoading) return const LoadingPanel();

    final data = state.data;
    final firstChild = data?.children.isEmpty ?? true ? null : data!.children.first;
    return RefreshIndicator(
      onRefresh: () => ref.read(kaderDashboardControllerProvider.notifier).load(),
      child: ListView(
        key: const Key('kaderList'),
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Beranda Kader',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const Text('Posyandu aktif hari ini', style: TextStyle(color: LedgerColors.inkSoft)),
          const SizedBox(height: 16),
          LedgerPanel(
            title: 'Sesi hari ini',
            subtitle: data?.session == null
                ? 'Belum ada sesi berjalan untuk Posyandu ini.'
                : 'Sesi ${data!.session!.tanggal} | Status ${data.session!.status}',
            accent: LedgerColors.primary,
            child: Text(widget.focus == 'sesi' ? 'Tarik ke bawah untuk memuat ulang sesi.' : 'Input Pengukuran'),
          ),
          const SizedBox(height: 16),
          const SectionTitle('Cari balita'),
          TextField(
            controller: _searchController,
            onSubmitted: (_) => _search(),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              labelText: 'Cari nama balita, ibu, atau NIK',
              suffixIcon: IconButton(
                tooltip: 'Cari',
                onPressed: _search,
                icon: const Icon(Icons.arrow_forward),
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (data?.children.isEmpty ?? true)
            const EmptyState(text: 'Belum ada balita pada hasil pencarian.')
          else
            ...data!.children.take(3).map((row) => _ChildRow(child: row)),
          const SizedBox(height: 16),
          const SectionTitle('Input pengukuran'),
          _MeasurementPanel(
            child: firstChild,
            weightController: _weightController,
            heightController: _heightController,
            saving: state.isSaving,
            onSave: _saveMeasurement,
          ),
          if (state.message != null) ...[
            const SizedBox(height: 12),
            InlineMessage(text: state.message!, isError: state.isError),
          ],
          if (state.lastMeasurement?.predictionFailed ?? false) ...[
            const SizedBox(height: 8),
            const StatusBadge(
              label: 'Prediksi gagal',
              color: LedgerColors.inkSoft,
              softColor: LedgerColors.line,
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => ref
                  .read(kaderDashboardControllerProvider.notifier)
                  .retryPrediction(),
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
            ),
          ],
          const SizedBox(height: 16),
          const SectionTitle('Hasil Skrining Hari Ini'),
          if (data?.screening.isEmpty ?? true)
            const EmptyState(text: 'Belum ada hasil skrining pada sesi ini.')
          else
            ...data!.screening.map((row) => _ScreeningRow(item: row)),
          const SizedBox(height: 16),
          const SectionTitle('Notifikasi'),
          if (data?.notifications.isEmpty ?? true)
            const EmptyState(text: 'Belum ada notifikasi.')
          else
            ...data!.notifications.take(3).map(
                  (row) => LedgerListRow(
                    title: row.title,
                    subtitle: row.message,
                    trailing: const Icon(Icons.notifications_none),
                  ),
                ),
        ],
      ),
    );
  }

  Future<void> _search() {
    return ref
        .read(kaderDashboardControllerProvider.notifier)
        .search(_searchController.text);
  }

  Future<void> _saveMeasurement() async {
    final weight = double.tryParse(_weightController.text.replaceAll(',', '.'));
    final height = double.tryParse(_heightController.text.replaceAll(',', '.'));
    if (weight == null || height == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Isi berat badan dan tinggi badan dengan angka.')),
      );
      return;
    }
    await ref.read(kaderDashboardControllerProvider.notifier).saveMeasurement(
          weight: weight,
          height: height,
        );
  }
}

class _ChildRow extends StatelessWidget {
  const _ChildRow({required this.child});

  final Balita child;

  @override
  Widget build(BuildContext context) {
    return LedgerListRow(
      title: child.namaBalita,
      subtitle: 'Ibu: ${child.namaIbu}',
      trailing: const StatusBadge(
        label: 'Input',
        color: LedgerColors.primary,
        softColor: LedgerColors.primarySoft,
      ),
    );
  }
}

class _ScreeningRow extends StatelessWidget {
  const _ScreeningRow({required this.item});

  final ScreeningItem item;

  @override
  Widget build(BuildContext context) {
    final risk = item.predictionStatus == 'gagal' ? 'gagal' : item.riskLevel;
    return LedgerListRow(
      title: item.namaBalita,
      subtitle: RiskCopy.message(risk),
      trailing: RiskBadge(risk: risk),
    );
  }
}

class _MeasurementPanel extends StatelessWidget {
  const _MeasurementPanel({
    required this.child,
    required this.weightController,
    required this.heightController,
    required this.saving,
    required this.onSave,
  });

  final Balita? child;
  final TextEditingController weightController;
  final TextEditingController heightController;
  final bool saving;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              child == null
                  ? 'Pilih balita dari hasil pencarian.'
                  : '${child!.namaBalita}\nIbu: ${child!.namaIbu}',
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('weightField'),
              controller: weightController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Berat badan (kg)'),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('heightField'),
              controller: heightController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Tinggi badan (cm)'),
            ),
            const SizedBox(height: 12),
            FilledButton(
              key: const Key('saveMeasurementButton'),
              onPressed: saving ? null : onSave,
              child: Text(saving ? 'Menyimpan...' : 'Simpan & Lanjut'),
            ),
          ],
        ),
      ),
    );
  }
}
