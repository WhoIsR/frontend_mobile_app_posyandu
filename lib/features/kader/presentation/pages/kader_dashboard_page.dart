import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/ledger_theme.dart';
import '../../../../shared/risk/risk_copy.dart';
import '../../../../shared/widgets/ledger_widgets.dart';
import '../../domain/entities/balita.dart';
import '../../domain/entities/kader_dashboard_data.dart';
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
    final sections = _sections(context, state, data, firstChild);
    return RefreshIndicator(
      onRefresh: () => ref.read(kaderDashboardControllerProvider.notifier).load(),
      child: ListView(
        key: const Key('kaderList'),
        padding: const EdgeInsets.all(16),
        children: sections,
      ),
    );
  }

  List<Widget> _sections(
    BuildContext context,
    KaderDashboardState state,
    KaderDashboardData? data,
    Balita? firstChild,
  ) {
    return switch (widget.focus) {
      'sesi' => _sessionSection(data, showMeasurement: true, state: state, firstChild: firstChild),
      'balita' => _childrenSection(data, state, firstChild),
      'skrining' => _screeningSection(data),
      'notifikasi' => _notificationSection(data),
      _ => _homeSection(context, data),
    };
  }

  List<Widget> _homeSection(BuildContext context, KaderDashboardData? data) {
    final childCount = data?.children.length ?? 0;
    final screeningCount = data?.screening.length ?? 0;
    final notificationCount = data?.notifications.length ?? 0;
    return [
      Text(
        'Ringkasan Kader',
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
      ),
      const Text('Posyandu aktif hari ini', style: TextStyle(color: LedgerColors.inkSoft)),
      const SizedBox(height: 16),
      ..._sessionSection(data, showMeasurement: false),
      const SizedBox(height: 16),
      LedgerListRow(
        title: 'Balita terdaftar',
        subtitle: '$childCount balita siap dicari dan dicatat.',
        trailing: const Icon(Icons.child_care_outlined),
      ),
      LedgerListRow(
        title: 'Skrining hari ini',
        subtitle: '$screeningCount hasil skrining tersimpan.',
        trailing: const Icon(Icons.fact_check_outlined),
      ),
      LedgerListRow(
        title: 'Notifikasi',
        subtitle: '$notificationCount pesan untuk kader.',
        trailing: const Icon(Icons.notifications_none),
      ),
    ];
  }

  List<Widget> _sessionSection(
    KaderDashboardData? data, {
    required bool showMeasurement,
    KaderDashboardState? state,
    Balita? firstChild,
  }) {
    return [
      LedgerPanel(
        title: 'Sesi hari ini',
        subtitle: data?.session == null
            ? 'Belum ada sesi berjalan untuk Posyandu ini.'
            : 'Sesi ${data!.session!.tanggal} | Status ${data.session!.status}',
        accent: LedgerColors.primary,
        child: Text(showMeasurement ? 'Input Pengukuran' : 'Tarik ke bawah untuk memuat ulang sesi.'),
      ),
      if (showMeasurement && state != null) ...[
        const SizedBox(height: 16),
        ..._measurementSection(state, firstChild),
      ],
    ];
  }

  List<Widget> _childrenSection(
    KaderDashboardData? data,
    KaderDashboardState state,
    Balita? firstChild,
  ) {
    return [
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
      ..._measurementSection(state, firstChild),
    ];
  }

  List<Widget> _measurementSection(KaderDashboardState state, Balita? firstChild) {
    return [
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
    ];
  }

  List<Widget> _screeningSection(KaderDashboardData? data) {
    return [
      const SectionTitle('Hasil Skrining Hari Ini'),
      if (data?.screening.isEmpty ?? true)
        const EmptyState(text: 'Belum ada hasil skrining pada sesi ini.')
      else
        ...data!.screening.map((row) => _ScreeningRow(item: row)),
    ];
  }

  List<Widget> _notificationSection(KaderDashboardData? data) {
    return [
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
    ];
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
