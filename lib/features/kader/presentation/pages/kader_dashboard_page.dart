import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/ledger_theme.dart';
import '../../../../shared/risk/risk_copy.dart';
import '../../../../shared/widgets/ledger_widgets.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/entities/balita.dart';
import '../../domain/entities/create_balita_request.dart';
import '../../domain/entities/kader_dashboard_data.dart';
import '../../domain/entities/screening_item.dart';
import '../controllers/kader_dashboard_controller.dart';

class KaderDashboardPage extends ConsumerStatefulWidget {
  const KaderDashboardPage({super.key, this.focus, this.onNavigate});

  final String? focus;
  final ValueChanged<String>? onNavigate;

  @override
  ConsumerState<KaderDashboardPage> createState() => _KaderDashboardPageState();
}

class _KaderDashboardPageState extends ConsumerState<KaderDashboardPage> {
  final _searchController = TextEditingController();
  final _screeningSearchController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    _screeningSearchController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(kaderDashboardControllerProvider);
    if (state.isLoading) return const LoadingPanel();

    final data = state.data;
    final firstChild = data?.children.isEmpty ?? true
        ? null
        : data!.children.first;
    final selectedChild = state.selectedChild ?? firstChild;
    final sections = _sections(context, state, data, selectedChild);
    return RefreshIndicator(
      onRefresh: () =>
          ref.read(kaderDashboardControllerProvider.notifier).load(),
      child: ListView(
        key: const Key('kaderList'),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 132),
        children: sections,
      ),
    );
  }

  List<Widget> _sections(
    BuildContext context,
    KaderDashboardState state,
    KaderDashboardData? data,
    Balita? selectedChild,
  ) {
    return switch (widget.focus) {
      'sesi' => _sessionSection(
        data,
        showMeasurement: true,
        state: state,
        selectedChild: selectedChild,
      ),
      'balita' => _childrenSection(data, state),
      'skrining' => _screeningSection(data),
      'notifikasi' => _notificationSection(context, data),
      _ => _homeSection(context, data),
    };
  }

  bool _measuredToday(Balita child, KaderDashboardData? data) {
    return data?.screening.any((row) => row.namaBalita == child.namaBalita) ??
        false;
  }

  String _ageText(Balita child) {
    final raw = child.tanggalLahir;
    if (raw == null) return 'Usia belum tercatat';
    final birthDate = DateTime.tryParse(raw);
    if (birthDate == null) return 'Usia belum tercatat';
    final now = DateTime.now();
    var months = (now.year - birthDate.year) * 12 + now.month - birthDate.month;
    if (now.day < birthDate.day) months -= 1;
    if (months < 0) months = 0;
    return 'Usia $months bulan';
  }

  String _latestMeasurementText(Balita child) {
    final weight = child.latestWeight;
    final height = child.latestHeight;
    if (weight == null || height == null) return 'Belum ada riwayat ukur';
    return 'Terakhir: ${_number(weight)} kg / ${_number(height)} cm';
  }

  String _number(double value) {
    return value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 1);
  }

  List<Widget> _homeSection(BuildContext context, KaderDashboardData? data) {
    final childCount = data?.children.length ?? 0;
    final screeningCount = data?.screening.length ?? 0;
    final notificationCount = data?.notifications.length ?? 0;
    return [
      const PageHeader(
        title: 'Mulai kerja hari ini',
        subtitle:
            'Cari balita, input pengukuran, lalu pantau hasil skrining tanpa bolak-balik bingung.',
        icon: Icons.health_and_safety_outlined,
      ),
      const SizedBox(height: 12),
      MetricGrid(
        items: [
          MetricItem(
            label: 'Balita',
            value: '$childCount',
            helper: 'siap dicatat',
            icon: Icons.child_care_outlined,
          ),
          MetricItem(
            label: 'Skrining',
            value: '$screeningCount',
            helper: 'hari ini',
            icon: Icons.fact_check_outlined,
            accent: LedgerColors.bidanBlue,
            soft: LedgerColors.primarySoft,
          ),
        ],
      ),
      const SizedBox(height: 12),
      ..._sessionSection(data, showMeasurement: false),
      LedgerListRow(
        title: 'Cari atau tambah balita',
        subtitle: 'Buka register untuk memilih anak yang akan diukur.',
        trailing: const Icon(Icons.arrow_forward),
        onTap: () => widget.onNavigate?.call('balita'),
      ),
      LedgerListRow(
        title: 'Input pengukuran',
        subtitle: 'Masukkan berat dan tinggi badan dari sesi berjalan.',
        trailing: const Icon(Icons.arrow_forward),
        onTap: () => widget.onNavigate?.call('sesi'),
      ),
      LedgerListRow(
        title: 'Notifikasi',
        subtitle: '$notificationCount pesan masuk.',
        trailing: const Icon(Icons.arrow_forward),
        onTap: () => widget.onNavigate?.call('notifikasi'),
      ),
    ];
  }

  List<Widget> _sessionSection(
    KaderDashboardData? data, {
    required bool showMeasurement,
    KaderDashboardState? state,
    Balita? selectedChild,
  }) {
    final measured =
        data?.children.where((child) => _measuredToday(child, data)).length ??
        0;
    final total = data?.children.length ?? 0;
    final remaining = total - measured;
    Balita? nextChild;
    for (final child in data?.children ?? const <Balita>[]) {
      if (!_measuredToday(child, data)) {
        nextChild = child;
        break;
      }
    }

    return [
      PageHeader(
        title: showMeasurement ? 'Kerja hari ini' : 'Sesi hari ini',
        subtitle: data?.session == null
            ? 'Belum ada sesi berjalan untuk Posyandu ini.'
            : 'Sesi ${data!.session!.tanggal} | Status ${data.session!.status}',
        icon: Icons.event_available_outlined,
      ),
      const SizedBox(height: 12),
      MetricGrid(
        items: [
          MetricItem(
            label: 'Sudah diukur',
            value: '$measured',
            helper: 'balita sesi ini',
            icon: Icons.check_circle_outline,
          ),
          MetricItem(
            label: 'Belum diukur',
            value: '$remaining',
            helper: 'perlu dicatat',
            icon: Icons.pending_actions_outlined,
            accent: LedgerColors.attention,
            soft: LedgerColors.attentionSoft,
          ),
        ],
      ),
      const SizedBox(height: 12),
      if (showMeasurement)
        LedgerPanel(
          title: nextChild == null ? 'Antrean selesai' : 'Lanjutkan antrean',
          subtitle: nextChild == null
              ? 'Semua balita pada daftar ini sudah punya catatan skrining sesi ini.'
              : '${nextChild.namaBalita} belum diukur. Tap untuk input cepat.',
          accent: nextChild == null
              ? LedgerColors.healthAqua
              : LedgerColors.primary,
          child: nextChild == null
              ? const Text('Cek tab Skrining untuk melihat tindak lanjut.')
              : FilledButton.icon(
                  key: const Key('nextQueueChildButton'),
                  onPressed: () {
                    ref
                        .read(kaderDashboardControllerProvider.notifier)
                        .selectChild(nextChild!);
                  },
                  icon: const Icon(Icons.straighten_outlined),
                  label: const Text('Input BB/TB sekarang'),
                ),
        )
      else
        LedgerPanel(
          title: 'Mode kerja Posyandu',
          subtitle:
              'Tab Sesi dipakai untuk antrean dan progres pengukuran hari ini.',
          accent: LedgerColors.healthAqua,
          child: const Text('Tarik ke bawah untuk memuat ulang sesi.'),
        ),
      if (showMeasurement && state != null) ...[
        const SizedBox(height: 16),
        ..._measurementSection(state, selectedChild),
      ],
    ];
  }

  List<Widget> _childrenSection(
    KaderDashboardData? data,
    KaderDashboardState state,
  ) {
    final allChildren = state.data?.children ?? const <Balita>[];
    final query = _searchController.text.trim().toLowerCase();
    final filteredChildren = allChildren.where((child) {
      if (query.isEmpty) return true;
      return child.namaBalita.toLowerCase().contains(query) ||
          child.namaIbu.toLowerCase().contains(query) ||
          (child.nikBalita?.toLowerCase().contains(query) ?? false);
    }).toList();

    return [
      const PageHeader(
        title: 'Register balita',
        subtitle:
            'Cari dulu sebelum menambah data baru agar catatan anak tidak dobel.',
        icon: Icons.child_care_outlined,
      ),
      const SizedBox(height: 16),
      const SectionTitle('Cari balita'),
      TextField(
        controller: _searchController,
        onChanged: (val) {
          setState(() {});
        },
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search),
          labelText: 'Cari nama balita, ibu, atau NIK',
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                  },
                )
              : null,
        ),
      ),
      const SizedBox(height: 10),
      SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: _openCreateBalita,
          icon: const Icon(Icons.person_add_alt_1_outlined, size: 18),
          label: const Text('Tambah Balita'),
        ),
      ),
      const SizedBox(height: 12),
      if (state.message != null) ...[
        InlineMessage(text: state.message!, isError: state.isError),
        const SizedBox(height: 12),
      ],
      if (filteredChildren.isEmpty)
        const EmptyState(text: 'Belum ada balita pada hasil pencarian.')
      else
        ...filteredChildren
            .take(10)
            .map(
              (row) => _ChildRow(
                child: row,
                ageText: _ageText(row),
                latestMeasurement: _latestMeasurementText(row),
                measuredToday: _measuredToday(row, data),
                onSelect: () => _openChildActions(row),
              ),
            ),
    ];
  }

  List<Widget> _measurementSection(
    KaderDashboardState state,
    Balita? selectedChild,
  ) {
    return [
      const SectionTitle('Input pengukuran'),
      _MeasurementPanel(
        child: selectedChild,
        weightController: _weightController,
        heightController: _heightController,
        saving: state.isSaving,
        onSave: _saveMeasurement,
        onEdit: selectedChild == null
            ? null
            : () => _openEditProfile(selectedChild),
        onCancel: () {
          _weightController.clear();
          _heightController.clear();
          ref.read(kaderDashboardControllerProvider.notifier).selectChild(null);
        },
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
    final allScreenings = data?.screening ?? const [];
    final query = _screeningSearchController.text.trim().toLowerCase();
    final filtered = allScreenings.where((item) {
      if (query.isEmpty) return true;
      return item.namaBalita.toLowerCase().contains(query);
    }).toList();

    return [
      const PageHeader(
        title: 'Hasil Skrining Hari Ini',
        subtitle:
            'Lihat catatan hari ini, cek riwayat singkat, lalu pilih arahan yang pas.',
        icon: Icons.fact_check_outlined,
      ),
      const SizedBox(height: 16),
      const SectionTitle('Cari hasil skrining'),
      TextField(
        controller: _screeningSearchController,
        onChanged: (val) => setState(() {}),
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search),
          labelText: 'Cari nama balita atau ibu',
          suffixIcon: _screeningSearchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _screeningSearchController.clear();
                    setState(() {});
                  },
                )
              : null,
        ),
      ),
      const SizedBox(height: 16),
      if (filtered.isEmpty)
        const EmptyState(text: 'Belum ada hasil skrining yang cocok.')
      else
        ...filtered.map((row) => _ScreeningRow(item: row)),
    ];
  }

  List<Widget> _notificationSection(
    BuildContext context,
    KaderDashboardData? data,
  ) {
    return [
      const PageHeader(
        title: 'Notifikasi',
        subtitle: 'Buka pesan untuk melihat konteks tindak lanjut dari sistem.',
        icon: Icons.notifications_outlined,
      ),
      const SizedBox(height: 12),
      if (data?.notifications.isEmpty ?? true)
        const EmptyState(text: 'Belum ada notifikasi.')
      else
        ...data!.notifications
            .take(3)
            .map(
              (row) => LedgerListRow(
                title: row.title,
                subtitle: row.message,
                trailing: Icon(
                  row.isRead
                      ? Icons.mark_email_read_outlined
                      : Icons.notifications_none,
                ),
                onTap: () => _openNotification(context, row),
              ),
            ),
    ];
  }

  Future<void> _openCreateBalita() async {
    final posyanduId = ref
        .read(kaderDashboardControllerProvider)
        .data
        ?.session
        ?.posyanduId;
    if (posyanduId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sesi aktif belum tersedia untuk menentukan Posyandu.'),
        ),
      );
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _CreateBalitaPage(posyanduId: posyanduId),
      ),
    );
  }

  Future<void> _openEditProfile(Balita child) async {
    final posyanduId = ref
        .read(kaderDashboardControllerProvider)
        .data
        ?.session
        ?.posyanduId;
    if (posyanduId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sesi aktif belum tersedia untuk menentukan Posyandu.'),
        ),
      );
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _EditBalitaPage(child: child, posyanduId: posyanduId),
      ),
    );
  }

  Future<void> _saveMeasurement() async {
    final weight = double.tryParse(_weightController.text.replaceAll(',', '.'));
    final height = double.tryParse(_heightController.text.replaceAll(',', '.'));
    if (weight == null || height == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Isi berat badan dan tinggi badan dengan angka.'),
        ),
      );
      return;
    }
    await ref
        .read(kaderDashboardControllerProvider.notifier)
        .saveMeasurement(weight: weight, height: height);
  }

  Future<void> _saveQuickMeasurement(
    BuildContext sheetContext,
    TextEditingController weightController,
    TextEditingController heightController,
  ) async {
    final weight = double.tryParse(weightController.text.replaceAll(',', '.'));
    final height = double.tryParse(heightController.text.replaceAll(',', '.'));
    if (weight == null || height == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Isi BB dan TB dengan angka.')),
      );
      return;
    }
    await ref
        .read(kaderDashboardControllerProvider.notifier)
        .saveMeasurement(weight: weight, height: height);
    if (sheetContext.mounted) Navigator.of(sheetContext).pop();
  }

  Future<void> _openChildActions(Balita child) async {
    ref.read(kaderDashboardControllerProvider.notifier).selectChild(child);
    final quickWeight = TextEditingController();
    final quickHeight = TextEditingController();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Aksi balita',
                style: Theme.of(sheetContext).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                '${child.namaBalita} | Ibu: ${child.namaIbu}',
                style: const TextStyle(color: LedgerColors.inkSoft),
              ),
              const SizedBox(height: 12),
              _ChildContextStrip(
                ageText: _ageText(child),
                latestMeasurement: _latestMeasurementText(child),
              ),
              const SizedBox(height: 16),
              LedgerPanel(
                title: 'Input BB/TB',
                subtitle:
                    'Catat pengukuran dari sesi berjalan tanpa pindah halaman.',
                accent: LedgerColors.primary,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            key: const Key('quickWeightField'),
                            controller: quickWeight,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'BB',
                              suffixText: 'kg',
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            key: const Key('quickHeightField'),
                            controller: quickHeight,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'TB',
                              suffixText: 'cm',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      key: const Key('quickSaveMeasurementButton'),
                      onPressed: () => _saveQuickMeasurement(
                        sheetContext,
                        quickWeight,
                        quickHeight,
                      ),
                      icon: const Icon(Icons.save_outlined),
                      label: const Text('Simpan & Lanjut'),
                    ),
                  ],
                ),
              ),
              const SectionTitle('Riwayat singkat'),
              LedgerListRow(
                title: _latestMeasurementText(child),
                subtitle:
                    'Dipakai sebagai pembanding cepat sebelum input hari ini.',
                trailing: const Icon(Icons.timeline_outlined),
              ),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(sheetContext).pop();
                        widget.onNavigate?.call('skrining');
                      },
                      icon: const Icon(Icons.fact_check_outlined, size: 18),
                      label: const Text('Lihat skrining'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      key: const Key('editChildProfileButton'),
                      onPressed: () {
                        Navigator.of(sheetContext).pop();
                        _openEditProfile(child);
                      },
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Edit profil balita'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    Future<void>.delayed(const Duration(milliseconds: 300), () {
      quickWeight.dispose();
      quickHeight.dispose();
    });
  }

  Future<void> _openNotification(
    BuildContext context,
    AppNotification notification,
  ) async {
    await ref
        .read(kaderDashboardControllerProvider.notifier)
        .openNotification(notification.id);
    if (!context.mounted) return;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Detail notifikasi'),
        content: Text(notification.message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Mengerti'),
          ),
        ],
      ),
    );
  }
}

class _ChildRow extends StatelessWidget {
  const _ChildRow({
    required this.child,
    required this.ageText,
    required this.latestMeasurement,
    required this.measuredToday,
    required this.onSelect,
  });

  final Balita child;
  final String ageText;
  final String latestMeasurement;
  final bool measuredToday;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: LedgerColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: LedgerColors.line),
        boxShadow: [
          BoxShadow(
            color: LedgerColors.primary.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onSelect,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      child.namaBalita,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      ageText,
                      style: const TextStyle(
                        color: LedgerColors.inkSoft,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      'Ibu: ${child.namaIbu}',
                      style: const TextStyle(
                        color: LedgerColors.inkSoft,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      latestMeasurement,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  StatusBadge(
                    label: measuredToday ? 'Sudah diukur' : 'Belum diukur',
                    color: measuredToday
                        ? LedgerColors.primary
                        : LedgerColors.attention,
                    softColor: measuredToday
                        ? LedgerColors.primarySoft
                        : LedgerColors.attentionSoft,
                  ),
                  if (!measuredToday) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: LedgerColors.primarySoft,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.straighten_rounded,
                            size: 13,
                            color: LedgerColors.primary,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Ukur',
                            style: TextStyle(
                              color: LedgerColors.primary,
                              fontWeight: FontWeight.w900,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChildContextStrip extends StatelessWidget {
  const _ChildContextStrip({
    required this.ageText,
    required this.latestMeasurement,
  });

  final String ageText;
  final String latestMeasurement;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MiniInfoTile(
            label: 'Usia',
            value: ageText.replaceFirst('Usia ', ''),
            icon: Icons.cake_outlined,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MiniInfoTile(
            label: 'Pengukuran terakhir',
            value: latestMeasurement.replaceFirst('Terakhir: ', ''),
            icon: Icons.monitor_weight_outlined,
          ),
        ),
      ],
    );
  }
}

class _MiniInfoTile extends StatelessWidget {
  const _MiniInfoTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: LedgerColors.surfaceAlt,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: LedgerColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: LedgerColors.primary),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: LedgerColors.inkSoft,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _CreateBalitaPage extends ConsumerStatefulWidget {
  const _CreateBalitaPage({required this.posyanduId});

  final int posyanduId;

  @override
  ConsumerState<_CreateBalitaPage> createState() => _CreateBalitaPageState();
}

class _CreateBalitaPageState extends ConsumerState<_CreateBalitaPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _nikController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _motherController = TextEditingController();
  final _motherNikController = TextEditingController();
  final _addressController = TextEditingController();
  final _incomeController = TextEditingController();
  final _familyController = TextEditingController();
  String _gender = 'L';
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _nikController.dispose();
    _birthDateController.dispose();
    _motherController.dispose();
    _motherNikController.dispose();
    _addressController.dispose();
    _incomeController.dispose();
    _familyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tambah Balita')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              const SectionTitle('Data balita'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      TextFormField(
                        key: const Key('childNameField'),
                        controller: _nameController,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Nama balita',
                        ),
                        validator: _required,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        key: const Key('childNikField'),
                        controller: _nikController,
                        textInputAction: TextInputAction.next,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'NIK balita (opsional)',
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        key: const Key('birthDateField'),
                        controller: _birthDateController,
                        textInputAction: TextInputAction.next,
                        keyboardType: TextInputType.datetime,
                        decoration: const InputDecoration(
                          labelText: 'Tanggal lahir',
                          hintText: 'YYYY-MM-DD',
                        ),
                        validator: _required,
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        key: const Key('genderDropdown'),
                        initialValue: _gender,
                        decoration: const InputDecoration(
                          labelText: 'Jenis kelamin',
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'L',
                            child: Text('Laki-laki'),
                          ),
                          DropdownMenuItem(
                            value: 'P',
                            child: Text('Perempuan'),
                          ),
                        ],
                        onChanged: (value) =>
                            setState(() => _gender = value ?? 'L'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const SectionTitle('Data keluarga'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      TextFormField(
                        key: const Key('motherNameField'),
                        controller: _motherController,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Nama ibu',
                        ),
                        validator: _required,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        key: const Key('motherNikField'),
                        controller: _motherNikController,
                        textInputAction: TextInputAction.next,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'NIK ibu (opsional)',
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        key: const Key('addressField'),
                        controller: _addressController,
                        textInputAction: TextInputAction.next,
                        minLines: 2,
                        maxLines: 3,
                        decoration: const InputDecoration(labelText: 'Alamat'),
                        validator: _required,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        key: const Key('incomeField'),
                        controller: _incomeController,
                        textInputAction: TextInputAction.next,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Penghasilan keluarga',
                        ),
                        validator: _positiveInt,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        key: const Key('familyCountField'),
                        controller: _familyController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Jumlah keluarga',
                        ),
                        validator: _positiveInt,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                key: const Key('saveBalitaButton'),
                onPressed: _saving ? null : _submit,
                child: Text(_saving ? 'Menyimpan...' : 'Simpan Balita'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _required(String? value) {
    return value?.trim().isEmpty ?? true ? 'Wajib diisi.' : null;
  }

  String? _positiveInt(String? value) {
    final parsed = int.tryParse(value?.trim() ?? '');
    return parsed == null || parsed < 1
        ? 'Isi dengan angka lebih dari 0.'
        : null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(kaderDashboardControllerProvider.notifier)
          .createBalita(
            CreateBalitaRequest(
              namaBalita: _nameController.text.trim(),
              nikBalita: _nikController.text.trim(),
              tanggalLahir: _birthDateController.text.trim(),
              jenisKelamin: _gender,
              namaIbu: _motherController.text.trim(),
              nikIbu: _motherNikController.text.trim(),
              alamat: _addressController.text.trim(),
              penghasilan: int.parse(_incomeController.text.trim()),
              jumlahKeluarga: int.parse(_familyController.text.trim()),
              posyanduId: widget.posyanduId,
            ),
          );
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _EditBalitaPage extends ConsumerStatefulWidget {
  const _EditBalitaPage({required this.child, required this.posyanduId});

  final Balita child;
  final int posyanduId;

  @override
  ConsumerState<_EditBalitaPage> createState() => _EditBalitaPageState();
}

class _EditBalitaPageState extends ConsumerState<_EditBalitaPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _nikController;
  late final TextEditingController _birthDateController;
  late final TextEditingController _motherController;
  late final TextEditingController _motherNikController;
  late final TextEditingController _addressController;
  late final TextEditingController _incomeController;
  late final TextEditingController _familyController;
  late String _gender;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.child.namaBalita);
    _nikController = TextEditingController(text: widget.child.nikBalita ?? '');
    _birthDateController = TextEditingController(
      text: widget.child.tanggalLahir ?? '',
    );
    _motherController = TextEditingController(text: widget.child.namaIbu);
    _motherNikController = TextEditingController(
      text: widget.child.nikIbu ?? '',
    );
    _addressController = TextEditingController(text: widget.child.alamat ?? '');
    _incomeController = TextEditingController(
      text: widget.child.penghasilan != null
          ? widget.child.penghasilan.toString()
          : '',
    );
    _familyController = TextEditingController(
      text: widget.child.jumlahKeluarga != null
          ? widget.child.jumlahKeluarga.toString()
          : '',
    );
    _gender = widget.child.jenisKelamin ?? 'L';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nikController.dispose();
    _birthDateController.dispose();
    _motherController.dispose();
    _motherNikController.dispose();
    _addressController.dispose();
    _incomeController.dispose();
    _familyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profil Balita')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              const SectionTitle('Data balita'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      TextFormField(
                        key: const Key('editChildNameField'),
                        controller: _nameController,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Nama balita',
                        ),
                        validator: _required,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        key: const Key('editChildNikField'),
                        controller: _nikController,
                        textInputAction: TextInputAction.next,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'NIK balita (opsional)',
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        key: const Key('editBirthDateField'),
                        controller: _birthDateController,
                        textInputAction: TextInputAction.next,
                        keyboardType: TextInputType.datetime,
                        decoration: const InputDecoration(
                          labelText: 'Tanggal lahir',
                          hintText: 'YYYY-MM-DD',
                        ),
                        validator: _required,
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        key: const Key('editGenderDropdown'),
                        initialValue: _gender,
                        decoration: const InputDecoration(
                          labelText: 'Jenis kelamin',
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'L',
                            child: Text('Laki-laki'),
                          ),
                          DropdownMenuItem(
                            value: 'P',
                            child: Text('Perempuan'),
                          ),
                        ],
                        onChanged: (value) =>
                            setState(() => _gender = value ?? 'L'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const SectionTitle('Data keluarga'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      TextFormField(
                        key: const Key('editMotherNameField'),
                        controller: _motherController,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Nama ibu',
                        ),
                        validator: _required,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        key: const Key('editMotherNikField'),
                        controller: _motherNikController,
                        textInputAction: TextInputAction.next,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'NIK ibu (opsional)',
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        key: const Key('editAddressField'),
                        controller: _addressController,
                        textInputAction: TextInputAction.next,
                        minLines: 2,
                        maxLines: 3,
                        decoration: const InputDecoration(labelText: 'Alamat'),
                        validator: _required,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        key: const Key('editIncomeField'),
                        controller: _incomeController,
                        textInputAction: TextInputAction.next,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Penghasilan keluarga',
                        ),
                        validator: _positiveInt,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        key: const Key('editFamilyCountField'),
                        controller: _familyController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Jumlah keluarga',
                        ),
                        validator: _positiveInt,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                key: const Key('editSaveBalitaButton'),
                onPressed: _saving ? null : _submit,
                child: Text(_saving ? 'Menyimpan...' : 'Simpan Perubahan'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _required(String? value) {
    return value?.trim().isEmpty ?? true ? 'Wajib diisi.' : null;
  }

  String? _positiveInt(String? value) {
    final parsed = int.tryParse(value?.trim() ?? '');
    return parsed == null || parsed < 1
        ? 'Isi dengan angka lebih dari 0.'
        : null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(kaderDashboardControllerProvider.notifier)
          .updateBalita(
            widget.child.id,
            CreateBalitaRequest(
              namaBalita: _nameController.text.trim(),
              nikBalita: _nikController.text.trim(),
              tanggalLahir: _birthDateController.text.trim(),
              jenisKelamin: _gender,
              namaIbu: _motherController.text.trim(),
              nikIbu: _motherNikController.text.trim(),
              alamat: _addressController.text.trim(),
              penghasilan: int.parse(_incomeController.text.trim()),
              jumlahKeluarga: int.parse(_familyController.text.trim()),
              posyanduId: widget.posyanduId,
            ),
          );
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _ScreeningRow extends StatefulWidget {
  const _ScreeningRow({required this.item});

  final ScreeningItem item;

  @override
  State<_ScreeningRow> createState() => _ScreeningRowState();
}

class _ScreeningRowState extends State<_ScreeningRow> {
  void _showScreeningDetailsBottomSheet(BuildContext context) {
    final risk = widget.item.predictionStatus == 'gagal'
        ? 'gagal'
        : widget.item.riskLevel;
    final riskColorsTuple = riskColors(risk);
    final primaryColor = riskColorsTuple.$1;
    final softColor = riskColorsTuple.$2;
    final historyLabel = widget.item.continuityLabel ?? 'Riwayat pengukuran';
    final historyMessage = widget.item.continuityMessage ??
        'Riwayatnya belum cukup untuk membaca tren. Catatan hari ini tetap tersimpan dan bisa jadi pembanding pada kunjungan berikutnya.';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.65,
          minChildSize: 0.45,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          widget.item.namaBalita,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 20,
                            color: LedgerColors.ink,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      RiskBadge(risk: risk),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    RiskCopy.message(risk),
                    style: const TextStyle(
                      color: LedgerColors.inkSoft,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Divider(color: LedgerColors.line, height: 1),
                  const SizedBox(height: 20),
                  
                  // History Section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: LedgerColors.paper,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: LedgerColors.line),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.timeline_outlined,
                          color: LedgerColors.primary,
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                historyLabel,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: LedgerColors.ink,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                historyMessage,
                                style: const TextStyle(
                                  color: LedgerColors.inkSoft,
                                  fontSize: 12,
                                  height: 1.4,
                                ),
                              ),
                              if (widget.item.measurementHistory.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                _MeasurementHistoryList(
                                  points: widget.item.measurementHistory,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Recommendations Section ("Catatan")
                  const Text(
                    'Catatan:',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: LedgerColors.ink,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: softColor.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: primaryColor.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          _counselingIcon(risk),
                          color: primaryColor,
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _counselingText(risk),
                            style: TextStyle(
                              color: primaryColor.withValues(alpha: 0.95),
                              fontSize: 13,
                              height: 1.45,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final risk = widget.item.predictionStatus == 'gagal'
        ? 'gagal'
        : widget.item.riskLevel;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: LedgerColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: LedgerColors.line,
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: LedgerColors.primary.withValues(
              alpha: 0.04,
            ),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _showScreeningDetailsBottomSheet(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            widget.item.namaBalita,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        RiskBadge(risk: risk),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      RiskCopy.message(risk),
                      style: const TextStyle(
                        color: LedgerColors.inkSoft,
                        fontSize: 12,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: LedgerColors.inkMuted,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _counselingIcon(String? risk) {
    return switch (risk) {
      'rendah' => Icons.check_circle_outline,
      'sedang' => Icons.info_outline,
      'tinggi' => Icons.warning_amber_rounded,
      _ => Icons.help_outline,
    };
  }

  String _counselingText(String? risk) {
    return switch (risk) {
      'rendah' =>
        '- Beri apresiasi singkat ke ibu.\n- Ingatkan pola makan dan jadwal timbang berikutnya.\n- Catat bila ada keluhan yang perlu dibawa ke bidan.',
      'sedang' =>
        '- Ajak ibu cek ulang pola makan harian anak.\n- Sarankan tambahan protein hewani bila memungkinkan.\n- Pantau lagi di jadwal berikutnya atau lebih cepat bila ada keluhan.',
      'tinggi' =>
        '- Sampaikan pelan-pelan bahwa hasil ini perlu dicek bidan.\n- Hindari menyebut diagnosis atau membuat keluarga panik.\n- Bantu arahkan ibu ke bidan atau meja layanan berikutnya.',
      _ =>
        '- Pastikan berat dan tinggi badan sudah benar.\n- Coba ulang saat koneksi lebih stabil.\n- Bila masih gagal, simpan catatan untuk dicek bidan.',
    };
  }
}

class _MeasurementHistoryList extends StatelessWidget {
  const _MeasurementHistoryList({required this.points});

  final List<MeasurementHistoryPoint> points;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Riwayat BB/TB',
          style: TextStyle(
            color: LedgerColors.ink,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        for (final point in points) _MeasurementHistoryTile(point: point),
      ],
    );
  }
}

class _MeasurementHistoryTile extends StatelessWidget {
  const _MeasurementHistoryTile({required this.point});

  final MeasurementHistoryPoint point;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: LedgerColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: LedgerColors.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: LedgerColors.primarySoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.monitor_weight_outlined,
              size: 18,
              color: LedgerColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${point.visitLabel} - ${point.measuredAt}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                    color: LedgerColors.ink,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Berat Badan (BB)',
                            style: TextStyle(
                              color: LedgerColors.inkSoft,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                '${_num(point.weightKg)} kg',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                  color: LedgerColors.ink,
                                ),
                              ),
                              if (point.weightDeltaKg != null && point.weightDeltaKg != 0) ...[
                                const SizedBox(width: 4),
                                _CompactDeltaChip(
                                  value: point.weightDeltaKg!,
                                  unit: 'kg',
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Tinggi Badan (TB)',
                            style: TextStyle(
                              color: LedgerColors.inkSoft,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                '${_num(point.heightCm)} cm',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                  color: LedgerColors.ink,
                                ),
                              ),
                              if (point.heightDeltaCm != null && point.heightDeltaCm != 0) ...[
                                const SizedBox(width: 4),
                                _CompactDeltaChip(
                                  value: point.heightDeltaCm!,
                                  unit: 'cm',
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _num(double value) {
    return value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 1);
  }
}

class _CompactDeltaChip extends StatelessWidget {
  const _CompactDeltaChip({
    required this.value,
    required this.unit,
  });

  final double value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    if (value == 0) return const SizedBox.shrink();
    final isNegative = value < 0;
    final sign = value > 0 ? '+' : '';
    final color = isNegative ? LedgerColors.review : const Color(0xFF0F766E);
    final bgColor = isNegative ? LedgerColors.reviewSoft.withValues(alpha: 0.8) : const Color(0xFFE6F4F1);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$sign${value.toStringAsFixed(1)} $unit',
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w800,
        ),
      ),
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
    this.onEdit,
    this.onCancel,
  });

  final Balita? child;
  final TextEditingController weightController;
  final TextEditingController heightController;
  final bool saving;
  final VoidCallback onSave;
  final VoidCallback? onEdit;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: LedgerColors.primarySoft,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.child_care_outlined,
                    color: LedgerColors.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    child == null
                        ? 'Pilih balita dari register.'
                        : '${child!.namaBalita}\nIbu: ${child!.namaIbu}',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (child != null && onEdit != null) ...[
                  IconButton(
                    key: const Key('inlineEditProfileButton'),
                    tooltip: 'Edit profil balita',
                    onPressed: onEdit,
                    icon: const Icon(
                      Icons.edit_note_outlined,
                      color: LedgerColors.primary,
                      size: 26,
                    ),
                  ),
                ],
                if (child != null && onCancel != null) ...[
                  IconButton(
                    key: const Key('inlineCancelButton'),
                    tooltip: 'Kembali ke antrean',
                    onPressed: onCancel,
                    icon: const Icon(
                      Icons.close_rounded,
                      color: LedgerColors.inkSoft,
                      size: 24,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    key: const Key('weightField'),
                    controller: weightController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Berat badan',
                      suffixText: 'kg',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    key: const Key('heightField'),
                    controller: heightController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Tinggi badan',
                      suffixText: 'cm',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                if (onCancel != null) ...[
                  Expanded(
                    flex: 1,
                    child: OutlinedButton(
                      key: const Key('cancelMeasurementButton'),
                      onPressed: saving ? null : onCancel,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: LedgerColors.inkSoft,
                        side: const BorderSide(color: LedgerColors.line),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'Batal',
                        softWrap: false,
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  flex: 1,
                  child: FilledButton.icon(
                    key: const Key('saveMeasurementButton'),
                    onPressed: saving ? null : onSave,
                    icon: const Icon(Icons.save_outlined, size: 18),
                    label: const Text(
                      'Simpan',
                      softWrap: false,
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
