import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/ledger_theme.dart';
import '../../../../shared/risk/risk_copy.dart';
import '../../../../shared/widgets/ledger_widgets.dart';
import '../../domain/entities/balita.dart';
import '../../domain/entities/create_balita_request.dart';
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
        style: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
      const Text(
        'Posyandu aktif hari ini',
        style: TextStyle(color: LedgerColors.inkSoft),
      ),
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
        child: showMeasurement
            ? const Row(
                children: [
                  Icon(Icons.straighten_outlined, color: LedgerColors.primary),
                  SizedBox(width: 8),
                  Text('Pengukuran balita'),
                ],
              )
            : const Text('Tarik ke bawah untuk memuat ulang sesi.'),
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
      Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Expanded(child: SectionTitle('Cari balita')),
          SizedBox(
            height: 40,
            child: OutlinedButton.icon(
              onPressed: _openCreateBalita,
              icon: const Icon(Icons.person_add_alt_1_outlined, size: 18),
              label: const Text('Tambah Balita'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 40),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
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
        ...data!.children
            .take(10)
            .map(
              (row) => _ChildRow(
                child: row,
                onSelect: () => ref
                    .read(kaderDashboardControllerProvider.notifier)
                    .selectChild(row),
              ),
            ),
      if (state.message != null) ...[
        const SizedBox(height: 12),
        InlineMessage(text: state.message!, isError: state.isError),
      ],
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
        ...data!.notifications
            .take(3)
            .map(
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
}

class _ChildRow extends StatelessWidget {
  const _ChildRow({required this.child, required this.onSelect});

  final Balita child;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    return LedgerListRow(
      title: child.namaBalita,
      subtitle: 'Ibu: ${child.namaIbu}',
      trailing: SizedBox(
        height: 36,
        child: TextButton.icon(
          onPressed: onSelect,
          icon: const Icon(Icons.straighten_outlined, size: 16),
          label: const Text('Ukur'),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8),
          ),
        ),
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
