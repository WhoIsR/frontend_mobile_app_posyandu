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
      'sesi' => _sessionSection(
        data,
        showMeasurement: true,
        state: state,
        firstChild: firstChild,
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
        subtitle: '$notificationCount pesan untuk kader.',
        trailing: const Icon(Icons.arrow_forward),
        onTap: () => widget.onNavigate?.call('notifikasi'),
      ),
    ];
  }

  List<Widget> _sessionSection(
    KaderDashboardData? data, {
    required bool showMeasurement,
    KaderDashboardState? state,
    Balita? firstChild,
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
                  onPressed: () => _openChildActions(nextChild!),
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
        ..._measurementSection(state, firstChild),
      ],
    ];
  }

  List<Widget> _childrenSection(
    KaderDashboardData? data,
    KaderDashboardState state,
  ) {
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
      if (data?.children.isEmpty ?? true)
        const EmptyState(text: 'Belum ada balita pada hasil pencarian.')
      else
        ...data!.children
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
    Balita? firstChild,
  ) {
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
      const PageHeader(
        title: 'Hasil Skrining Hari Ini',
        subtitle:
            'Gunakan label ini sebagai skrining awal dan tindak lanjut empatik.',
        icon: Icons.fact_check_outlined,
      ),
      const SizedBox(height: 12),
      if (data?.screening.isEmpty ?? true)
        const EmptyState(text: 'Belum ada hasil skrining pada sesi ini.')
      else
        ...data!.screening.map((row) => _ScreeningRow(item: row)),
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

  Future<void> _search() {
    return ref
        .read(kaderDashboardControllerProvider.notifier)
        .search(_searchController.text);
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
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  widget.onNavigate?.call('skrining');
                },
                icon: const Icon(Icons.fact_check_outlined),
                label: const Text('Lihat skrining'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => Navigator.of(sheetContext).pop(),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit profil balita'),
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
                    label: measuredToday
                        ? 'Sudah diukur sesi ini'
                        : 'Belum diukur sesi ini',
                    color: measuredToday
                        ? LedgerColors.primary
                        : LedgerColors.attention,
                    softColor: measuredToday
                        ? LedgerColors.primarySoft
                        : LedgerColors.attentionSoft,
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: onSelect,
                    icon: const Icon(Icons.straighten_outlined, size: 16),
                    label: const Text('Ukur'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 2),
              const Icon(
                Icons.chevron_right_rounded,
                color: LedgerColors.inkMuted,
                size: 22,
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
