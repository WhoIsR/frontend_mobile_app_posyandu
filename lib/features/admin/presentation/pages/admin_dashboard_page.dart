import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
}
