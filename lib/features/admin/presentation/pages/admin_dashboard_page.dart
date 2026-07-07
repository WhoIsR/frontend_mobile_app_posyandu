import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

import '../../../../app/ledger_theme.dart';
import '../../../../shared/widgets/ledger_widgets.dart';
import '../../domain/entities/admin_account.dart';
import '../../domain/entities/admin_posyandu.dart';
import '../../domain/entities/admin_schedule.dart';
import '../controllers/admin_dashboard_controller.dart';

class AdminDashboardPage extends ConsumerStatefulWidget {
  const AdminDashboardPage({
    super.key,
    this.focus,
    this.selectedPosyanduId,
    this.onNavigate,
  });

  final String? focus;
  final int? selectedPosyanduId;
  final ValueChanged<String>? onNavigate;

  @override
  ConsumerState<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends ConsumerState<AdminDashboardPage> {
  String _accountSearchQuery = '';
  String _posyanduSearchQuery = '';

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminDashboardControllerProvider);
    if (state.isLoading) return const LoadingPanel();
    final sections = switch (widget.focus) {
      'akun' => _accounts(context, ref, state),
      'posyandu' => _posyandu(context, ref, state),
      'sesi' => _sessions(context, ref, state),
      'laporan' => _reports(context, ref, state),
      _ => _home(context, ref, state),
    };
    return RefreshIndicator(
      onRefresh: () async {
        setState(() {
          _accountSearchQuery = '';
          _posyanduSearchQuery = '';
        });
        await ref.read(adminDashboardControllerProvider.notifier).load();
      },
      child: ListView(padding: const EdgeInsets.all(16), children: sections),
    );
  }

  List<Widget> _home(
    BuildContext context,
    WidgetRef ref,
    AdminDashboardState state,
  ) {
    final bidanCount = state.accounts
        .where((row) => row.role == 'bidan' && row.status == 'aktif')
        .length;
    final kaderCount = state.accounts
        .where((row) => row.role == 'kader' && row.status == 'aktif')
        .length;
    final inactiveCount = state.accounts
        .where((row) => row.status == 'nonaktif')
        .length;
    final activeSession = state.activeSession;
    return [
      const PageHeader(
        title: 'Kontrol operasional',
        subtitle:
            'Kelola akun kerja dan wilayah Posyandu secukupnya untuk menjalankan MVP.',
        icon: Icons.admin_panel_settings_outlined,
      ),
      const SizedBox(height: 12),
      MetricGrid(
        items: [
          MetricItem(
            label: 'Bidan',
            value: '$bidanCount',
            helper: 'akun aktif',
            icon: Icons.medical_services_outlined,
            accent: LedgerColors.bidanBlue,
            soft: LedgerColors.primarySoft,
          ),
          MetricItem(
            label: 'Kader',
            value: '$kaderCount',
            helper: 'akun aktif',
            icon: Icons.groups_outlined,
          ),
        ],
      ),
      const SizedBox(height: 12),
      LedgerPanel(
        title: 'Akun nonaktif',
        subtitle: inactiveCount == 0
            ? 'Tidak ada akun yang perlu dicek.'
            : '$inactiveCount perlu dicek sebelum jadwal Posyandu berikutnya.',
        accent: inactiveCount == 0
            ? LedgerColors.primary
            : LedgerColors.attention,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$inactiveCount perlu dicek',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: () => _openAccountForm(context, ref, state),
              icon: const Icon(Icons.person_add_alt_1_outlined),
              label: const Text('Tambah akun kerja'),
            ),
          ],
        ),
      ),
      LedgerListRow(
        title: 'Akun aktif',
        subtitle: '$bidanCount bidan dan $kaderCount kader terdaftar.',
        onTap: () => widget.onNavigate?.call('akun'),
      ),
      LedgerListRow(
        title: 'Posyandu',
        subtitle:
            '${state.posyandu.length} wilayah, terhubung to akun dan balita.',
        onTap: () => widget.onNavigate?.call('posyandu'),
      ),
      LedgerListRow(
        title: activeSession == null ? 'Jadwal & sesi' : 'Sesi sedang aktif',
        subtitle: activeSession == null
            ? '${state.schedules.length} jadwal tercatat. Mulai sesi dari sini.'
            : '${_posyanduName(state, activeSession.posyanduId)} | ${activeSession.date}',
        onTap: () => widget.onNavigate?.call('sesi'),
      ),
      LedgerListRow(
        title: 'Laporan PDF',
        subtitle: 'Preview/share 3 laporan PRD dari data server.',
        onTap: () => widget.onNavigate?.call('laporan'),
      ),
      if (state.message != null)
        InlineMessage(text: state.message!, isError: state.isError),
    ];
  }

  List<Widget> _accounts(
    BuildContext context,
    WidgetRef ref,
    AdminDashboardState state,
  ) {
    final baseAccounts = widget.selectedPosyanduId == null
        ? state.accounts
        : state.accounts
              .where((row) => row.posyanduId == widget.selectedPosyanduId)
              .toList();

    final filteredAccounts = baseAccounts.where((row) {
      if (_accountSearchQuery.trim().isEmpty) return true;
      final q = _accountSearchQuery.toLowerCase();
      return row.name.toLowerCase().contains(q) ||
          row.nikNip.toLowerCase().contains(q);
    }).toList();

    final filterName = widget.selectedPosyanduId == null
        ? null
        : _posyanduName(state, widget.selectedPosyanduId!);
    return [
      PageHeader(
        title: 'Akun',
        subtitle: filterName == null
            ? 'Admin hanya mengelola akun Kader dan Bidan untuk kebutuhan operasional.'
            : 'Akun Kader dan Bidan yang terhubung ke $filterName.',
        icon: Icons.people_outline,
        action: FilledButton.icon(
          onPressed: () => _openAccountForm(context, ref, state),
          icon: const Icon(Icons.person_add_alt_1_outlined),
          label: const Text('Tambah Akun'),
        ),
      ),
      const SizedBox(height: 12),
      if (filterName != null) ...[
        InlineMessage(
          text:
              'Filter aktif: $filterName. Data di bawah hanya untuk Posyandu ini.',
        ),
        const SizedBox(height: 12),
      ],
      TextField(
        key: const Key('adminAccountSearchField'),
        onChanged: (value) {
          setState(() {
            _accountSearchQuery = value;
          });
        },
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search, color: LedgerColors.inkSoft),
          hintText: 'Cari akun nama atau NIK/NIP...',
          suffixIcon: _accountSearchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () {
                    setState(() {
                      _accountSearchQuery = '';
                    });
                  },
                )
              : null,
        ),
      ),
      const SizedBox(height: 12),
      if (filteredAccounts.isEmpty)
        EmptyState(
          text: _accountSearchQuery.isEmpty
              ? (filterName == null
                  ? 'Belum ada akun.'
                  : 'Belum ada akun yang terhubung ke $filterName.')
              : 'Akun tidak ditemukan dalam pencarian.',
        )
      else ...[
        if (state.message != null) ...[
          InlineMessage(text: state.message!, isError: state.isError),
          const SizedBox(height: 12),
        ],
        ...filteredAccounts.map(
          (row) => _AdminAccountCard(
            account: row,
            posyanduName: row.posyanduId == null
                ? 'Semua Posyandu'
                : _posyanduName(state, row.posyanduId!),
            onTap: () => _openAccountActions(context, ref, state, row),
          ),
        ),
      ],
    ];
  }

  List<Widget> _posyandu(
    BuildContext context,
    WidgetRef ref,
    AdminDashboardState state,
  ) {
    final filteredPosyandu = state.posyandu.where((row) {
      if (_posyanduSearchQuery.trim().isEmpty) return true;
      final q = _posyanduSearchQuery.toLowerCase();
      return row.name.toLowerCase().contains(q) ||
          (row.address?.toLowerCase().contains(q) ?? false) ||
          (row.village?.toLowerCase().contains(q) ?? false) ||
          (row.district?.toLowerCase().contains(q) ?? false);
    }).toList();

    return [
      PageHeader(
        title: 'Posyandu',
        subtitle:
            'Data wilayah kerja dasar untuk menghubungkan Bidan, Kader, dan balita.',
        icon: Icons.home_work_outlined,
        action: FilledButton.icon(
          onPressed: () => _openPosyanduForm(context, ref),
          icon: const Icon(Icons.add_home_work_outlined),
          label: const Text('Tambah'),
        ),
      ),
      const SizedBox(height: 12),
      TextField(
        key: const Key('adminPosyanduSearchField'),
        onChanged: (value) {
          setState(() {
            _posyanduSearchQuery = value;
          });
        },
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search, color: LedgerColors.inkSoft),
          hintText: 'Cari wilayah nama Posyandu, desa, kecamatan...',
          suffixIcon: _posyanduSearchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () {
                    setState(() {
                      _posyanduSearchQuery = '';
                    });
                  },
                )
              : null,
        ),
      ),
      const SizedBox(height: 12),
      if (filteredPosyandu.isEmpty)
        EmptyState(
          text: _posyanduSearchQuery.isEmpty
              ? 'Belum ada Posyandu.'
              : 'Posyandu tidak ditemukan dalam pencarian.',
        )
      else
        ...filteredPosyandu.map(
          (row) => _AdminPosyanduCard(
            posyandu: row,
            bidanCount: _countAccounts(state, row.id, 'bidan'),
            kaderCount: _countAccounts(state, row.id, 'kader'),
            scheduleCount: state.schedules
                .where((schedule) => schedule.posyanduId == row.id)
                .length,
            isActive:
                state.activeSession != null &&
                state.activeSession!.posyanduId == row.id,
            onOpenAccounts: () => widget.onNavigate?.call('akun:${row.id}'),
            onOpenSessions: () => widget.onNavigate?.call('sesi:${row.id}'),
            onEdit: () => _openPosyanduForm(context, ref, row),
          ),
        ),
      if (state.message != null) ...[
        const SizedBox(height: 12),
        InlineMessage(text: state.message!, isError: state.isError),
      ],
    ];
  }

  int _countAccounts(AdminDashboardState state, int posyanduId, String role) {
    return state.accounts
        .where(
          (account) =>
              account.role == role &&
              account.status == 'aktif' &&
              account.posyanduId == posyanduId,
        )
        .length;
  }

  List<Widget> _sessions(
    BuildContext context,
    WidgetRef ref,
    AdminDashboardState state,
  ) {
    final active = state.activeSession;
    final filteredSchedules = widget.selectedPosyanduId == null
        ? state.schedules
        : state.schedules
              .where((row) => row.posyanduId == widget.selectedPosyanduId)
              .toList();
    final filterName = widget.selectedPosyanduId == null
        ? null
        : _posyanduName(state, widget.selectedPosyanduId!);
    final activeForFilter =
        active != null &&
        (widget.selectedPosyanduId == null || active.posyanduId == widget.selectedPosyanduId);
    return [
      PageHeader(
        title: 'Jadwal & sesi',
        subtitle: filterName == null
            ? 'Di sini Admin/Bidan menyiapkan jadwal Posyandu dan membuka sesi aktif yang dipakai Kader untuk input BB/TB.'
            : 'Jadwal dan sesi khusus $filterName.',
        icon: Icons.event_available_outlined,
        action: state.posyandu.isEmpty
            ? null
            : FilledButton.icon(
                onPressed: () => _openScheduleForm(context, ref, state),
                icon: const Icon(Icons.add_task_outlined),
                label: const Text('Buat Jadwal'),
              ),
      ),
      const SizedBox(height: 12),
      if (filterName != null) ...[
        InlineMessage(
          text:
              'Filter aktif: $filterName. Jadwal di bawah hanya untuk Posyandu ini.',
        ),
        const SizedBox(height: 12),
      ],
      if (!activeForFilter)
        LedgerPanel(
          title: filterName == null
              ? 'Belum ada sesi aktif'
              : 'Belum ada sesi aktif untuk $filterName',
          subtitle: filterName == null
              ? 'Kader baru bisa input pengukuran setelah sesi Posyandu dibuka.'
              : 'Kader $filterName baru bisa input setelah sesi wilayah ini dibuka.',
          accent: LedgerColors.attention,
          child: const Text(
            'Pilih jadwal di bawah lalu tekan Mulai Sesi.',
            style: TextStyle(color: LedgerColors.inkSoft),
          ),
        )
      else
        LedgerPanel(
          title: 'Sesi sedang berjalan',
          subtitle:
              '${_posyanduName(state, active.posyanduId)} | ${active.date}',
          accent: LedgerColors.primary,
          child: FilledButton.icon(
            onPressed: state.isSaving
                ? null
                : () => ref
                      .read(adminDashboardControllerProvider.notifier)
                      .closeActiveSession(),
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Selesaikan Sesi'),
          ),
        ),
      const SectionTitle('Jadwal Posyandu'),
      if (filteredSchedules.isEmpty)
        EmptyState(
          text: filterName == null
              ? 'Belum ada jadwal. Buat jadwal pertama dulu.'
              : 'Belum ada jadwal untuk $filterName.',
        )
      else
        ...filteredSchedules.map(
          (schedule) => _AdminScheduleCard(
            schedule: schedule,
            posyanduName: _posyanduName(state, schedule.posyanduId),
            isActive: active?.scheduleId == schedule.id,
            onStart: state.isSaving
                ? null
                : () => ref
                      .read(adminDashboardControllerProvider.notifier)
                      .startSession(schedule),
            onEdit: () => _openScheduleForm(context, ref, state, schedule),
          ),
        ),
      if (state.message != null) ...[
        const SizedBox(height: 12),
        InlineMessage(text: state.message!, isError: state.isError),
      ],
    ];
  }

  String _posyanduName(AdminDashboardState state, int id) {
    for (final row in state.posyandu) {
      if (row.id == id) return row.name;
    }
    return 'Posyandu $id';
  }

  List<Widget> _reports(
    BuildContext context,
    WidgetRef ref,
    AdminDashboardState state,
  ) {
    return [
      const PageHeader(
        title: 'Laporan PDF',
        subtitle:
            'Ambil laporan operasional untuk kebutuhan demo dan audit dasar.',
        icon: Icons.description_outlined,
      ),
      const SizedBox(height: 12),
      _AdminReportRangePicker(
        startDate: state.reportStartDate,
        endDate: state.reportEndDate,
        onPick: (range) => ref
            .read(adminDashboardControllerProvider.notifier)
            .setReportRange(range.start, range.end),
      ),
      const SizedBox(height: 12),
      _AdminReportAction(
        title: 'Prediksi Risiko',
        subtitle: 'Rekap hasil skrining balita.',
        icon: Icons.fact_check_outlined,
        isDownloading: state.downloadingReportType == 'prediksi',
        onPressed: () => ref
            .read(adminDashboardControllerProvider.notifier)
            .downloadReport('prediksi'),
      ),
      _AdminReportAction(
        title: 'Kehadiran Posyandu',
        subtitle: 'Daftar kehadiran dari sesi Posyandu.',
        icon: Icons.event_available_outlined,
        isDownloading: state.downloadingReportType == 'kehadiran',
        onPressed: () => ref
            .read(adminDashboardControllerProvider.notifier)
            .downloadReport('kehadiran'),
      ),
      _AdminReportAction(
        title: 'Distribusi PMT',
        subtitle: 'Catatan penyaluran paket PMT.',
        icon: Icons.inventory_outlined,
        isDownloading: state.downloadingReportType == 'distribusi-pmt',
        onPressed: () => ref
            .read(adminDashboardControllerProvider.notifier)
            .downloadReport('distribusi-pmt'),
      ),
      _AdminReportAction(
        title: 'Semua Laporan (Gabungan)',
        subtitle: 'Menggabungkan semua laporan dalam satu dokumen.',
        icon: Icons.analytics_outlined,
        isDownloading: state.downloadingReportType == 'semua',
        onPressed: () => ref
            .read(adminDashboardControllerProvider.notifier)
            .downloadReport('semua'),
      ),
      if (state.reportBytes != null) ...[
        const SizedBox(height: 16),
        if (Platform.environment.containsKey('FLUTTER_TEST')) ...[
          LedgerPanel(
            title: 'Preview PDF siap',
            subtitle: 'Laporan ${state.reportType ?? 'posyandu'} sudah diterima dari server.',
            accent: LedgerColors.bidanBlue,
            child: FilledButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.ios_share_outlined),
              label: const Text('Bagikan / Simpan'),
            ),
          ),
        ] else ...[
          const SectionTitle('Preview Laporan'),
          const SizedBox(height: 8),
          Container(
            height: 480,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: LedgerColors.line),
            ),
            clipBehavior: Clip.antiAlias,
            child: PdfPreview(
              build: (format) => state.reportBytes!,
              useActions: true,
              allowPrinting: true,
              allowSharing: true,
              canChangePageFormat: false,
              canChangeOrientation: false,
              canDebug: false,
            ),
          ),
        ],
      ],
      if (state.message != null)
        InlineMessage(text: state.message!, isError: state.isError),
    ];
  }

  Future<void> _openAccountActions(
    BuildContext context,
    WidgetRef ref,
    AdminDashboardState state,
    AdminAccount account,
  ) {
    final nextStatus = account.status == 'aktif' ? 'nonaktif' : 'aktif';
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Aksi akun',
                    style: Theme.of(sheetContext).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    account.name,
                    style: const TextStyle(color: LedgerColors.inkSoft),
                  ),
                  const SizedBox(height: 12),
                  _AccountActionSummary(
                    account: account,
                    posyanduName: account.posyanduId == null
                        ? 'Semua Posyandu'
                        : _posyanduName(state, account.posyanduId!),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.of(sheetContext).pop();
                        _openAccountForm(context, ref, state, account);
                      },
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Edit akun'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(sheetContext).pop();
                        _openStatusConfirmation(
                          context,
                          ref,
                          account,
                          nextStatus,
                        );
                      },
                      icon: Icon(
                        nextStatus == 'nonaktif'
                            ? Icons.block
                            : Icons.check_circle_outline,
                      ),
                      label: Text(
                        nextStatus == 'nonaktif' ? 'Nonaktifkan' : 'Aktifkan',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openStatusConfirmation(
    BuildContext context,
    WidgetRef ref,
    AdminAccount account,
    String nextStatus,
  ) {
    final disabling = nextStatus == 'nonaktif';
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    disabling ? 'Nonaktifkan akun?' : 'Aktifkan akun?',
                    style: Theme.of(sheetContext).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    disabling
                        ? '${account.name} tidak bisa login lagi, tapi histori pengukuran dan validasi tetap aman.'
                        : '${account.name} akan bisa login kembali.',
                    style: const TextStyle(
                      color: LedgerColors.inkSoft,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () async {
                        await ref
                            .read(adminDashboardControllerProvider.notifier)
                            .saveAccount(
                              id: account.id,
                              name: account.name,
                              nikNip: account.nikNip,
                              role: account.role,
                              posyanduId: account.posyanduId,
                              status: nextStatus,
                            );
                        if (sheetContext.mounted) {
                          Navigator.of(sheetContext).pop();
                        }
                      },
                      icon: Icon(
                        disabling ? Icons.block : Icons.check_circle_outline,
                      ),
                      label: Text(
                        disabling ? 'Ya, nonaktifkan' : 'Ya, aktifkan',
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(sheetContext).pop(),
                      child: const Text('Batal'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openAccountForm(
    BuildContext context,
    WidgetRef ref,
    AdminDashboardState state, [
    AdminAccount? account,
  ]) {
    final name = TextEditingController(text: account?.name ?? '');
    final nik = TextEditingController(text: account?.nikNip ?? '');
    final password = TextEditingController();
    var role = account?.role == 'bidan' ? 'bidan' : 'kader';
    var status = account?.status == 'nonaktif' ? 'nonaktif' : 'aktif';
    int? posyanduId =
        account?.posyanduId ??
        widget.selectedPosyanduId ??
        (state.posyandu.isEmpty ? null : state.posyandu.first.id);
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setState) => SizedBox(
          width: double.infinity,
          child: Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: ListView(
              shrinkWrap: true,
              children: [
                Text(
                  account == null ? 'Tambah Akun' : 'Edit akun',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('adminAccountNameField'),
                  controller: name,
                  decoration: const InputDecoration(labelText: 'Nama'),
                ),
                const SizedBox(height: 10),
                TextField(
                  key: const Key('adminAccountNikField'),
                  controller: nik,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'NIK / NIP'),
                ),
                const SizedBox(height: 10),
                TextField(
                  key: const Key('adminAccountPasswordField'),
                  controller: password,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: account == null
                        ? 'Password'
                        : 'Password baru (opsional)',
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: role,
                  decoration: const InputDecoration(labelText: 'Role'),
                  items: const [
                    DropdownMenuItem(value: 'kader', child: Text('Kader')),
                    DropdownMenuItem(value: 'bidan', child: Text('Bidan')),
                  ],
                  onChanged: (value) => setState(() => role = value ?? 'kader'),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<int?>(
                  initialValue: posyanduId,
                  decoration: const InputDecoration(labelText: 'Posyandu'),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('Semua Posyandu'),
                    ),
                    ...state.posyandu.map(
                      (row) => DropdownMenuItem<int?>(
                        value: row.id,
                        child: Text(row.name),
                      ),
                    ),
                  ],
                  onChanged: (value) => setState(() => posyanduId = value),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: status,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: const [
                    DropdownMenuItem(value: 'aktif', child: Text('Aktif')),
                    DropdownMenuItem(
                      value: 'nonaktif',
                      child: Text('Nonaktif'),
                    ),
                  ],
                  onChanged: (value) =>
                      setState(() => status = value ?? 'aktif'),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  key: const Key('saveAdminAccountButton'),
                  onPressed: () async {
                    await ref
                        .read(adminDashboardControllerProvider.notifier)
                        .saveAccount(
                          id: account?.id,
                          name: name.text.trim(),
                          nikNip: nik.text.trim(),
                          password: password.text.trim(),
                          role: role,
                          posyanduId: posyanduId,
                          status: status,
                        );
                    if (sheetContext.mounted) Navigator.of(sheetContext).pop();
                  },
                  child: const Text('Simpan Akun'),
                ),
              ],
            ),
          ),
        ),
      ),
    ).whenComplete(() {
      Future<void>.delayed(const Duration(milliseconds: 300), () {
        name.dispose();
        nik.dispose();
        password.dispose();
      });
    });
  }

  Future<void> _openPosyanduForm(
    BuildContext context,
    WidgetRef ref, [
    AdminPosyandu? posyandu,
  ]) {
    final name = TextEditingController(text: posyandu?.name ?? '');
    final address = TextEditingController(text: posyandu?.address ?? '');
    final village = TextEditingController(text: posyandu?.village ?? '');
    final district = TextEditingController(text: posyandu?.district ?? '');
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => SizedBox(
        width: double.infinity,
        child: Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
          ),
          child: ListView(
            shrinkWrap: true,
            children: [
              Text(
                posyandu == null ? 'Tambah Posyandu' : 'Edit Posyandu',
                style: Theme.of(sheetContext).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Nama Posyandu'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: address,
                decoration: const InputDecoration(labelText: 'Alamat'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: village,
                decoration: const InputDecoration(labelText: 'Desa'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: district,
                decoration: const InputDecoration(labelText: 'Kecamatan'),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () async {
                  await ref
                      .read(adminDashboardControllerProvider.notifier)
                      .savePosyandu(
                        id: posyandu?.id,
                        name: name.text.trim(),
                        address: address.text.trim(),
                        village: village.text.trim(),
                        district: district.text.trim(),
                      );
                  if (sheetContext.mounted) Navigator.of(sheetContext).pop();
                },
                child: const Text('Simpan Posyandu'),
              ),
            ],
          ),
        ),
      ),
    ).whenComplete(() {
      Future<void>.delayed(const Duration(milliseconds: 300), () {
        name.dispose();
        address.dispose();
        village.dispose();
        district.dispose();
      });
    });
  }

  Future<void> _openScheduleForm(
    BuildContext context,
    WidgetRef ref,
    AdminDashboardState state, [
    AdminSchedule? schedule,
  ]) {
    final now = DateTime.now();
    final defaultDate =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final date = TextEditingController(text: schedule?.date ?? defaultDate);
    final start = TextEditingController(text: schedule?.startTime ?? '08:00');
    final end = TextEditingController(text: schedule?.endTime ?? '11:00');
    final location = TextEditingController(
      text: schedule?.location ?? state.posyandu.first.address ?? '',
    );
    final note = TextEditingController(text: schedule?.note ?? '');
    var posyanduId =
        schedule?.posyanduId ?? widget.selectedPosyanduId ?? state.posyandu.first.id;

    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setState) => SizedBox(
          width: double.infinity,
          child: Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: ListView(
              shrinkWrap: true,
              children: [
                Text(
                  schedule == null ? 'Buat Jadwal' : 'Edit Jadwal',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 6),
                const Text(
                  'Jadwal ini bisa dibuka menjadi sesi aktif saat Posyandu berlangsung.',
                  style: TextStyle(color: LedgerColors.inkSoft, height: 1.35),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<int>(
                  initialValue: posyanduId,
                  decoration: const InputDecoration(labelText: 'Posyandu'),
                  items: state.posyandu
                      .map(
                        (row) => DropdownMenuItem(
                          value: row.id,
                          child: Text(row.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setState(() => posyanduId = value ?? posyanduId),
                ),
                const SizedBox(height: 10),
                TextField(
                  key: const Key('adminScheduleDateField'),
                  controller: date,
                  decoration: const InputDecoration(
                    labelText: 'Tanggal',
                    hintText: 'YYYY-MM-DD',
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: start,
                        decoration: const InputDecoration(
                          labelText: 'Mulai',
                          hintText: '08:00',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: end,
                        decoration: const InputDecoration(
                          labelText: 'Selesai',
                          hintText: '11:00',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: location,
                  decoration: const InputDecoration(labelText: 'Lokasi'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: note,
                  decoration: const InputDecoration(
                    labelText: 'Catatan',
                    hintText: 'Misal: penimbangan rutin',
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  key: const Key('saveAdminScheduleButton'),
                  onPressed: () async {
                    await ref
                        .read(adminDashboardControllerProvider.notifier)
                        .saveSchedule(
                          id: schedule?.id,
                          posyanduId: posyanduId,
                          date: date.text.trim(),
                          startTime: start.text.trim(),
                          endTime: end.text.trim(),
                          location: location.text.trim(),
                          note: note.text.trim(),
                        );
                    if (sheetContext.mounted) Navigator.of(sheetContext).pop();
                  },
                  child: const Text('Simpan Jadwal'),
                ),
              ],
            ),
          ),
        ),
      ),
    ).whenComplete(() {
      Future<void>.delayed(const Duration(milliseconds: 300), () {
        date.dispose();
        start.dispose();
        end.dispose();
        location.dispose();
        note.dispose();
      });
    });
  }
}

class _AdminAccountCard extends StatelessWidget {
  const _AdminAccountCard({
    required this.account,
    required this.posyanduName,
    required this.onTap,
  });

  final AdminAccount account;
  final String posyanduName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final active = account.status == 'aktif';
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
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SoftIcon(
                icon: account.role == 'bidan'
                    ? Icons.medical_services_outlined
                    : Icons.groups_outlined,
                color: account.role == 'bidan'
                    ? LedgerColors.bidanBlue
                    : LedgerColors.primary,
                softColor: account.role == 'bidan'
                    ? LedgerColors.healthAquaSoft
                    : LedgerColors.primarySoft,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account.name,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      account.role.toUpperCase(),
                      style: const TextStyle(
                        color: LedgerColors.inkSoft,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'NIP/NIK ${account.nikNip}',
                      style: const TextStyle(
                        color: LedgerColors.inkSoft,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      posyanduName,
                      style: const TextStyle(
                        color: LedgerColors.inkSoft,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              StatusBadge(
                label: account.status,
                color: active ? LedgerColors.primary : LedgerColors.inkSoft,
                softColor: active
                    ? LedgerColors.primarySoft
                    : LedgerColors.line,
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.chevron_right_rounded,
                color: LedgerColors.inkMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccountActionSummary extends StatelessWidget {
  const _AccountActionSummary({
    required this.account,
    required this.posyanduName,
  });

  final AdminAccount account;
  final String posyanduName;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: LedgerColors.surfaceAlt,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: LedgerColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            account.role.toUpperCase(),
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: LedgerColors.inkSoft,
            ),
          ),
          const SizedBox(height: 4),
          Text('NIP/NIK ${account.nikNip}'),
          const SizedBox(height: 2),
          Text(
            account.posyanduId == null
                ? 'Akses semua Posyandu'
                : 'Terhubung ke $posyanduName',
            style: const TextStyle(color: LedgerColors.inkSoft),
          ),
        ],
      ),
    );
  }
}

class _AdminPosyanduCard extends StatelessWidget {
  const _AdminPosyanduCard({
    required this.posyandu,
    required this.bidanCount,
    required this.kaderCount,
    required this.scheduleCount,
    required this.isActive,
    required this.onOpenAccounts,
    required this.onOpenSessions,
    required this.onEdit,
  });

  final AdminPosyandu posyandu;
  final int bidanCount;
  final int kaderCount;
  final int scheduleCount;
  final bool isActive;
  final VoidCallback onOpenAccounts;
  final VoidCallback onOpenSessions;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final location = [
      if (posyandu.village?.isNotEmpty ?? false) posyandu.village,
      if (posyandu.district?.isNotEmpty ?? false) posyandu.district,
    ].whereType<String>().join(' | ');
    return LedgerPanel(
      title: posyandu.name,
      subtitle: location.isEmpty ? 'Wilayah kerja Posyandu' : location,
      accent: isActive ? LedgerColors.primary : LedgerColors.bidanBlue,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              StatusBadge(
                label: '$bidanCount bidan',
                color: LedgerColors.bidanBlue,
                softColor: LedgerColors.healthAquaSoft,
              ),
              StatusBadge(
                label: '$kaderCount kader',
                color: LedgerColors.primary,
                softColor: LedgerColors.primarySoft,
              ),
              StatusBadge(
                label: '$scheduleCount jadwal',
                color: LedgerColors.attention,
                softColor: LedgerColors.attentionSoft,
              ),
              if (isActive)
                const StatusBadge(
                  label: 'sesi aktif',
                  color: LedgerColors.primary,
                  softColor: LedgerColors.primarySoft,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            posyandu.address?.isNotEmpty ?? false
                ? posyandu.address!
                : 'Alamat belum diisi.',
            style: const TextStyle(color: LedgerColors.inkSoft),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: onOpenAccounts,
                icon: const Icon(Icons.people_outline),
                label: const Text('Akun terkait'),
              ),
              OutlinedButton.icon(
                onPressed: onOpenSessions,
                icon: const Icon(Icons.event_available_outlined),
                label: const Text('Jadwal/Sesi'),
              ),
              FilledButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AdminScheduleCard extends StatelessWidget {
  const _AdminScheduleCard({
    required this.schedule,
    required this.posyanduName,
    required this.isActive,
    required this.onStart,
    required this.onEdit,
  });

  final AdminSchedule schedule;
  final String posyanduName;
  final bool isActive;
  final VoidCallback? onStart;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final time = [
      if (schedule.startTime?.isNotEmpty ?? false) schedule.startTime,
      if (schedule.endTime?.isNotEmpty ?? false) schedule.endTime,
    ].whereType<String>().join(' - ');
    return LedgerPanel(
      title: '$posyanduName | ${schedule.date}',
      subtitle: time.isEmpty ? 'Jam belum diatur' : time,
      accent: isActive ? LedgerColors.primary : LedgerColors.attention,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            schedule.location?.isNotEmpty ?? false
                ? schedule.location!
                : 'Lokasi belum diisi.',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          if (schedule.note?.isNotEmpty ?? false) ...[
            const SizedBox(height: 4),
            Text(
              schedule.note!,
              style: const TextStyle(color: LedgerColors.inkSoft),
            ),
          ],
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                key: const Key('startAdminSessionButton'),
                onPressed: isActive ? null : onStart,
                icon: const Icon(Icons.play_arrow_outlined),
                label: Text(isActive ? 'Sedang Aktif' : 'Mulai Sesi'),
              ),
              OutlinedButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_calendar_outlined),
                label: const Text('Edit Jadwal'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AdminReportRangePicker extends StatelessWidget {
  const _AdminReportRangePicker({
    required this.startDate,
    required this.endDate,
    required this.onPick,
  });

  final String? startDate;
  final String? endDate;
  final ValueChanged<DateTimeRange> onPick;

  @override
  Widget build(BuildContext context) {
    final label = startDate == null || endDate == null
        ? 'Semua tanggal'
        : '$startDate sampai $endDate';
    return LedgerPanel(
      title: 'Rentang laporan',
      subtitle: label,
      accent: LedgerColors.bidanBlue,
      child: OutlinedButton.icon(
        onPressed: () async {
          final now = DateTime.now();
          final range = await showDateRangePicker(
            context: context,
            firstDate: DateTime(now.year - 2),
            lastDate: DateTime(now.year + 1, 12, 31),
            initialDateRange: DateTimeRange(
              start: startDate == null
                  ? DateTime(now.year, now.month, 1)
                  : DateTime.parse(startDate!),
              end: endDate == null ? now : DateTime.parse(endDate!),
            ),
          );
          if (range != null) onPick(range);
        },
        icon: const Icon(Icons.date_range_outlined),
        label: const Text('Pilih tanggal'),
      ),
    );
  }
}

class _AdminReportAction extends StatelessWidget {
  const _AdminReportAction({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onPressed,
    required this.isDownloading,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onPressed;
  final bool isDownloading;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(icon, color: LedgerColors.inkSoft),
            const SizedBox(width: 12),
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
                    style: const TextStyle(color: LedgerColors.inkSoft),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 104,
              child: FilledButton(
                onPressed: isDownloading ? null : onPressed,
                child: isDownloading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Preview'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
