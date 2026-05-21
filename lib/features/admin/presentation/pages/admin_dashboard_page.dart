import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

import '../../../../app/ledger_theme.dart';
import '../../../../shared/widgets/ledger_widgets.dart';
import '../controllers/admin_dashboard_controller.dart';

class AdminDashboardPage extends ConsumerWidget {
  const AdminDashboardPage({super.key, this.focus});

  final String? focus;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminDashboardControllerProvider);
    if (state.isLoading) return const LoadingPanel();
    final sections = switch (focus) {
      'akun' => _accounts(context, state),
      'posyandu' => _posyandu(context, state),
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
      Text(
        'Ringkasan Admin',
        style: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 4),
      const Text(
        'Kelola akun dan Posyandu dasar untuk operasional aplikasi.',
        style: TextStyle(color: LedgerColors.inkSoft),
      ),
      const SizedBox(height: 16),
      LedgerListRow(
        title: 'Akun aktif',
        subtitle: '$bidanCount bidan dan $kaderCount kader terdaftar.',
        trailing: const Icon(Icons.people_outline),
      ),
      LedgerListRow(
        title: 'Posyandu',
        subtitle: '${state.posyandu.length} Posyandu tercatat.',
        trailing: const Icon(Icons.home_work_outlined),
      ),
      LedgerListRow(
        title: 'Laporan PDF',
        subtitle: 'Preview/share 3 laporan PRD dari data server.',
        trailing: const Icon(Icons.description_outlined),
      ),
      if (state.message != null)
        InlineMessage(text: state.message!, isError: state.isError),
    ];
  }

  List<Widget> _accounts(BuildContext context, AdminDashboardState state) {
    return [
      const SectionTitle('Akun'),
      const Text(
        'Admin hanya mengelola akun Kader dan Bidan untuk kebutuhan operasional.',
        style: TextStyle(color: LedgerColors.inkSoft),
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
          ),
        ),
    ];
  }

  List<Widget> _posyandu(BuildContext context, AdminDashboardState state) {
    return [
      const SectionTitle('Posyandu'),
      const Text(
        'Data wilayah kerja dasar untuk menghubungkan Bidan, Kader, dan balita.',
        style: TextStyle(color: LedgerColors.inkSoft),
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
          ),
        ),
    ];
  }

  List<Widget> _reports(
    BuildContext context,
    WidgetRef ref,
    AdminDashboardState state,
  ) {
    return [
      const SectionTitle('Laporan PDF'),
      const Text(
        'Admin dapat mengambil laporan operasional yang sama untuk kebutuhan demo dan audit dasar.',
        style: TextStyle(color: LedgerColors.inkSoft),
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
