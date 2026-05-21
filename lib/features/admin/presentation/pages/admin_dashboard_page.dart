import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

import '../../../../app/ledger_theme.dart';
import '../../../../shared/widgets/ledger_widgets.dart';
import '../../domain/entities/admin_account.dart';
import '../../domain/entities/admin_posyandu.dart';
import '../controllers/admin_dashboard_controller.dart';

class AdminDashboardPage extends ConsumerWidget {
  const AdminDashboardPage({super.key, this.focus, this.onNavigate});

  final String? focus;
  final ValueChanged<String>? onNavigate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminDashboardControllerProvider);
    if (state.isLoading) return const LoadingPanel();
    final sections = switch (focus) {
      'akun' => _accounts(context, ref, state),
      'posyandu' => _posyandu(context, ref, state),
      'laporan' => _reports(context, ref, state),
      _ => _home(context, state),
    };
    return RefreshIndicator(
      onRefresh: () =>
          ref.read(adminDashboardControllerProvider.notifier).load(),
      child: ListView(padding: const EdgeInsets.all(16), children: sections),
    );
  }

  List<Widget> _home(BuildContext context, AdminDashboardState state) {
    final bidanCount = state.accounts
        .where((row) => row.role == 'bidan')
        .length;
    final kaderCount = state.accounts
        .where((row) => row.role == 'kader')
        .length;
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
      LedgerListRow(
        title: 'Akun aktif',
        subtitle: '$bidanCount bidan dan $kaderCount kader terdaftar.',
        trailing: const Icon(Icons.arrow_forward),
        onTap: () => onNavigate?.call('akun'),
      ),
      LedgerListRow(
        title: 'Posyandu',
        subtitle: '${state.posyandu.length} Posyandu tercatat.',
        trailing: const Icon(Icons.arrow_forward),
        onTap: () => onNavigate?.call('posyandu'),
      ),
      LedgerListRow(
        title: 'Laporan PDF',
        subtitle: 'Preview/share 3 laporan PRD dari data server.',
        trailing: const Icon(Icons.arrow_forward),
        onTap: () => onNavigate?.call('laporan'),
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
    return [
      PageHeader(
        title: 'Akun',
        subtitle:
            'Admin hanya mengelola akun Kader dan Bidan untuk kebutuhan operasional.',
        icon: Icons.people_outline,
        action: FilledButton.icon(
          onPressed: () => _openAccountForm(context, ref),
          icon: const Icon(Icons.person_add_alt_1_outlined),
          label: const Text('Tambah Akun'),
        ),
      ),
      const SizedBox(height: 12),
      if (state.accounts.isEmpty)
        const EmptyState(text: 'Belum ada akun.')
      else
        ...state.accounts.map(
          (row) => LedgerListRow(
            title: row.name,
            subtitle: '${row.role.toUpperCase()} | ${row.nikNip}',
            trailing: StatusBadge(
              label: row.status,
              color: row.status == 'aktif'
                  ? LedgerColors.primary
                  : LedgerColors.inkSoft,
              softColor: row.status == 'aktif'
                  ? LedgerColors.primarySoft
                  : LedgerColors.line,
            ),
            onTap: () => _openAccountActions(context, ref, row),
          ),
        ),
      if (state.message != null) ...[
        const SizedBox(height: 12),
        InlineMessage(text: state.message!, isError: state.isError),
      ],
    ];
  }

  List<Widget> _posyandu(
    BuildContext context,
    WidgetRef ref,
    AdminDashboardState state,
  ) {
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
      if (state.posyandu.isEmpty)
        const EmptyState(text: 'Belum ada Posyandu.')
      else
        ...state.posyandu.map(
          (row) => LedgerListRow(
            title: row.name,
            subtitle: [
              if (row.village?.isNotEmpty ?? false) row.village,
              if (row.district?.isNotEmpty ?? false) row.district,
            ].whereType<String>().join(' | '),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _openPosyanduForm(context, ref, row),
          ),
        ),
      if (state.message != null) ...[
        const SizedBox(height: 12),
        InlineMessage(text: state.message!, isError: state.isError),
      ],
    ];
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
        onPressed: () => ref
            .read(adminDashboardControllerProvider.notifier)
            .downloadReport('prediksi'),
      ),
      _AdminReportAction(
        title: 'Kehadiran Posyandu',
        subtitle: 'Daftar kehadiran dari sesi Posyandu.',
        icon: Icons.event_available_outlined,
        onPressed: () => ref
            .read(adminDashboardControllerProvider.notifier)
            .downloadReport('kehadiran'),
      ),
      _AdminReportAction(
        title: 'Distribusi PMT',
        subtitle: 'Catatan penyaluran paket PMT.',
        icon: Icons.inventory_outlined,
        onPressed: () => ref
            .read(adminDashboardControllerProvider.notifier)
            .downloadReport('distribusi-pmt'),
      ),
      if (state.reportBytes != null) ...[
        const SizedBox(height: 12),
        LedgerPanel(
          title: 'Preview PDF siap',
          subtitle:
              'Laporan ${state.reportType ?? 'posyandu'} sudah diterima dari server.',
          accent: LedgerColors.bidanBlue,
          child: FilledButton.icon(
            onPressed: () => Printing.sharePdf(
              bytes: state.reportBytes!,
              filename: 'laporan-${state.reportType ?? 'posyandu'}.pdf',
            ),
            icon: const Icon(Icons.ios_share_outlined),
            label: const Text('Bagikan / Simpan'),
          ),
        ),
      ],
      if (state.message != null)
        InlineMessage(text: state.message!, isError: state.isError),
    ];
  }

  Future<void> _openAccountActions(
    BuildContext context,
    WidgetRef ref,
    AdminAccount account,
  ) {
    final nextStatus = account.status == 'aktif' ? 'nonaktif' : 'aktif';
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Aksi akun', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(
                account.name,
                style: const TextStyle(color: LedgerColors.inkSoft),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  _openAccountForm(context, ref, account);
                },
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit akun'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () async {
                  Navigator.of(context).pop();
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
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openAccountForm(
    BuildContext context,
    WidgetRef ref, [
    AdminAccount? account,
  ]) {
    final name = TextEditingController(text: account?.name ?? '');
    final nik = TextEditingController(text: account?.nikNip ?? '');
    final password = TextEditingController();
    var role = account?.role == 'bidan' ? 'bidan' : 'kader';
    var status = account?.status == 'nonaktif' ? 'nonaktif' : 'aktif';
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
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
              DropdownButtonFormField<String>(
                initialValue: status,
                decoration: const InputDecoration(labelText: 'Status'),
                items: const [
                  DropdownMenuItem(value: 'aktif', child: Text('Aktif')),
                  DropdownMenuItem(value: 'nonaktif', child: Text('Nonaktif')),
                ],
                onChanged: (value) => setState(() => status = value ?? 'aktif'),
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
                        posyanduId: account?.posyanduId,
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
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
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
    ).whenComplete(() {
      Future<void>.delayed(const Duration(milliseconds: 300), () {
        name.dispose();
        address.dispose();
        village.dispose();
        district.dispose();
      });
    });
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
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onPressed;

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
                onPressed: onPressed,
                child: const Text('Preview'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
