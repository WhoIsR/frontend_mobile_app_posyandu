import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/ledger_theme.dart';
import '../../../../shared/widgets/ledger_widgets.dart';
import '../../domain/entities/bidan_dashboard_data.dart';
import '../../domain/entities/pmt_stock.dart';
import '../../domain/entities/referral.dart';
import '../controllers/bidan_dashboard_controller.dart';

class BidanDashboardPage extends ConsumerStatefulWidget {
  const BidanDashboardPage({super.key, this.focus});

  final String? focus;

  @override
  ConsumerState<BidanDashboardPage> createState() => _BidanDashboardPageState();
}

class _BidanDashboardPageState extends ConsumerState<BidanDashboardPage> {
  final _noteController = TextEditingController(text: 'Observasi dan pantau ulang.');
  String _decision = 'observasi';

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bidanDashboardControllerProvider);
    if (state.isLoading) return const LoadingPanel();
    final data = state.data;
    final sections = _sections(context, state, data);
    return RefreshIndicator(
      onRefresh: () => ref.read(bidanDashboardControllerProvider.notifier).load(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: sections,
      ),
    );
  }

  List<Widget> _sections(
    BuildContext context,
    BidanDashboardState state,
    BidanDashboardData? data,
  ) {
    return switch (widget.focus) {
      'rujukan' => [
        ..._referralSection(context, data),
        const SizedBox(height: 16),
        ..._validationSection(state),
      ],
      'pmt' => _pmtSection(state, data),
      'laporan' => _reportSection(state),
      'notifikasi' => _notificationSection(data),
      _ => _homeSection(context, data),
    };
  }

  List<Widget> _homeSection(BuildContext context, BidanDashboardData? data) {
    final referrals = data?.referrals.length ?? 0;
    final waiting = data?.referrals
            .where((row) => row.status == 'menunggu_validasi')
            .length ??
        0;
    final pmtItems = data?.pmtStock.length ?? 0;
    final notifications = data?.notifications.length ?? 0;
    return [
      Text(
        'Ringkasan Bidan',
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
      ),
      const SizedBox(height: 12),
      LedgerListRow(
        title: 'Rujukan perlu ditinjau',
        subtitle: '$waiting dari $referrals rujukan menunggu validasi.',
        trailing: const Icon(Icons.assignment_late_outlined),
      ),
      LedgerListRow(
        title: 'Stok PMT',
        subtitle: '$pmtItems item PMT tercatat.',
        trailing: const Icon(Icons.inventory_2_outlined),
      ),
      LedgerListRow(
        title: 'Notifikasi',
        subtitle: '$notifications pesan untuk bidan.',
        trailing: const Icon(Icons.notifications_none),
      ),
    ];
  }

  List<Widget> _referralSection(BuildContext context, BidanDashboardData? data) {
    return [
      Text(
        'Rujukan',
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 12),
      if (data?.referrals.isEmpty ?? true)
        const EmptyState(text: 'Belum ada rujukan masuk.')
      else
        ...data!.referrals.take(4).map((row) => _ReferralRow(referral: row)),
    ];
  }

  List<Widget> _validationSection(BidanDashboardState state) {
    return [
      const SectionTitle('Validasi Medis'),
      LedgerPanel(
        title: 'Keputusan',
        subtitle: 'Observasi, konseling, PMT, rujuk puskesmas, atau cek ulang data.',
        accent: LedgerColors.bidanBlue,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              key: const Key('decisionDropdown'),
              initialValue: _decision,
              decoration: const InputDecoration(labelText: 'Keputusan'),
              items: const [
                DropdownMenuItem(value: 'observasi', child: Text('Observasi')),
                DropdownMenuItem(value: 'konseling', child: Text('Konseling')),
                DropdownMenuItem(value: 'pmt', child: Text('PMT')),
                DropdownMenuItem(value: 'rujuk_puskesmas', child: Text('Rujuk Puskesmas')),
                DropdownMenuItem(value: 'cek_ulang_data', child: Text('Cek ulang data')),
              ],
              onChanged: (value) => setState(() => _decision = value ?? 'observasi'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _noteController,
              minLines: 2,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Catatan bidan'),
            ),
            const SizedBox(height: 12),
            FilledButton(
              key: const Key('validateButton'),
              onPressed: state.isSavingValidation ? null : _validateReferral,
              child: Text(state.isSavingValidation ? 'Menyimpan...' : 'Simpan Validasi'),
            ),
          ],
        ),
      ),
      if (state.message != null &&
          !state.message!.toLowerCase().contains('distribusi') &&
          !state.message!.toLowerCase().contains('pdf')) ...[
        const SizedBox(height: 12),
        InlineMessage(text: state.message!, isError: state.isError),
      ],
    ];
  }

  List<Widget> _pmtSection(BidanDashboardState state, BidanDashboardData? data) {
    return [
      const SectionTitle('PMT'),
      if (data?.pmtStock.isEmpty ?? true)
        const EmptyState(text: 'Belum ada stok PMT.')
      else ...[
        ...data!.pmtStock.map((row) => _StockRow(stock: row)),
        const SizedBox(height: 8),
        FilledButton(
          key: const Key('distributePmtButton'),
          onPressed: state.isDistributingPmt
              ? null
              : () => ref
                  .read(bidanDashboardControllerProvider.notifier)
                  .distributeFirstPmt(),
          child: Text(
            state.isDistributingPmt ? 'Menyimpan...' : 'Distribusikan 1 paket',
          ),
        ),
      ],
      if (state.message != null &&
          state.message!.toLowerCase().contains('distribusi')) ...[
        const SizedBox(height: 12),
        InlineMessage(text: state.message!, isError: state.isError),
      ],
    ];
  }

  List<Widget> _reportSection(BidanDashboardState state) {
    return [
      const SectionTitle('Laporan PDF'),
      _ReportPicker(
        onDownload: (type) => ref
            .read(bidanDashboardControllerProvider.notifier)
            .downloadReport(type),
      ),
      if (state.message != null &&
          state.message!.toLowerCase().contains('pdf')) ...[
        const SizedBox(height: 12),
        InlineMessage(
          text: state.message!,
          isError: state.isError,
        ),
      ],
    ];
  }

  List<Widget> _notificationSection(BidanDashboardData? data) {
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

  Future<void> _validateReferral() {
    return ref.read(bidanDashboardControllerProvider.notifier).validateFirstReferral(
          decision: _decision,
          note: _noteController.text,
        );
  }
}

class _ReferralRow extends StatelessWidget {
  const _ReferralRow({required this.referral});

  final Referral referral;

  @override
  Widget build(BuildContext context) {
    return LedgerListRow(
      title: referral.namaBalita,
      subtitle: 'Ibu: ${referral.namaIbu} | ${referral.status}',
      trailing: RiskBadge(risk: referral.riskLevel),
    );
  }
}

class _StockRow extends StatelessWidget {
  const _StockRow({required this.stock});

  final PmtStock stock;

  @override
  Widget build(BuildContext context) {
    return LedgerListRow(
      title: stock.name,
      subtitle: 'Stok ${stock.stock} ${stock.unit} | Minimum ${stock.minimumStock}',
      trailing: StatusBadge(
        label: stock.isLow ? 'Stok menipis' : 'Aman',
        color: stock.isLow ? LedgerColors.attention : LedgerColors.primary,
        softColor: stock.isLow ? LedgerColors.attentionSoft : LedgerColors.primarySoft,
      ),
    );
  }
}

class _ReportPicker extends StatelessWidget {
  const _ReportPicker({required this.onDownload});

  final Future<void> Function(String type) onDownload;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Prediksi Risiko'),
            const SizedBox(height: 12),
            FilledButton(
              key: const Key('downloadReport-prediksi'),
              onPressed: () => onDownload('prediksi'),
              child: const Text('Download Prediksi'),
            ),
            const SizedBox(height: 8),
            const Text('Kehadiran Posyandu'),
            const SizedBox(height: 12),
            FilledButton(
              key: const Key('downloadReport-kehadiran'),
              onPressed: () => onDownload('kehadiran'),
              child: const Text('Download Kehadiran'),
            ),
            const SizedBox(height: 8),
            const Text('Distribusi PMT'),
            const SizedBox(height: 12),
            FilledButton(
              key: const Key('downloadReport-distribusi-pmt'),
              onPressed: () => onDownload('distribusi-pmt'),
              child: const Text('Download Distribusi'),
            ),
          ],
        ),
      ),
    );
  }
}
