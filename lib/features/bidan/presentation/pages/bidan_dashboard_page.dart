import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

import '../../../../app/ledger_theme.dart';
import '../../../../shared/widgets/ledger_widgets.dart';
import '../../../kader/domain/entities/app_notification.dart';
import '../../domain/entities/bidan_dashboard_data.dart';
import '../../domain/entities/pmt_stock.dart';
import '../../domain/entities/referral.dart';
import '../controllers/bidan_dashboard_controller.dart';

class BidanDashboardPage extends ConsumerStatefulWidget {
  const BidanDashboardPage({super.key, this.focus, this.onNavigate});

  final String? focus;
  final ValueChanged<String>? onNavigate;

  @override
  ConsumerState<BidanDashboardPage> createState() => _BidanDashboardPageState();
}

class _BidanDashboardPageState extends ConsumerState<BidanDashboardPage> {
  final _noteController = TextEditingController(
    text: 'Observasi dan pantau ulang.',
  );
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
      onRefresh: () =>
          ref.read(bidanDashboardControllerProvider.notifier).load(),
      child: ListView(padding: const EdgeInsets.all(16), children: sections),
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
      'notifikasi' => _notificationSection(context, data),
      _ => _homeSection(context, data),
    };
  }

  List<Widget> _homeSection(BuildContext context, BidanDashboardData? data) {
    final referrals = data?.referrals.length ?? 0;
    final waiting =
        data?.referrals
            .where((row) => row.status == 'menunggu_validasi')
            .length ??
        0;
    final pmtItems = data?.pmtStock.length ?? 0;
    final lowStock = data?.pmtStock.where((row) => row.isLow).length ?? 0;
    final notifications = data?.notifications.length ?? 0;
    return [
      const _PageIntro(
        title: 'Triage hari ini',
        subtitle:
            'Prioritaskan rujukan masuk, cek stok PMT, lalu ambil laporan bila dibutuhkan.',
      ),
      const SizedBox(height: 12),
      _SummaryStrip(
        items: [
          _SummaryItem(
            label: 'Menunggu',
            value: '$waiting',
            helper: 'dari $referrals rujukan',
            icon: Icons.assignment_late_outlined,
          ),
          _SummaryItem(
            label: 'PMT',
            value: '$pmtItems',
            helper: lowStock > 0 ? '$lowStock stok menipis' : 'stok aman',
            icon: Icons.inventory_2_outlined,
          ),
        ],
      ),
      const SizedBox(height: 12),
      LedgerListRow(
        title: 'Rujukan perlu ditinjau',
        subtitle: waiting == 0
            ? 'Belum ada rujukan yang menunggu validasi.'
            : '$waiting rujukan menunggu keputusan bidan.',
        trailing: const Icon(Icons.arrow_forward),
        onTap: () => widget.onNavigate?.call('rujukan'),
      ),
      LedgerListRow(
        title: 'Stok dan distribusi PMT',
        subtitle: lowStock > 0
            ? '$lowStock item perlu dicek sebelum distribusi.'
            : 'Stok PMT saat ini aman untuk tindak lanjut.',
        trailing: const Icon(Icons.arrow_forward),
        onTap: () => widget.onNavigate?.call('pmt'),
      ),
      LedgerListRow(
        title: 'Notifikasi',
        subtitle: '$notifications pesan untuk bidan.',
        trailing: const Icon(Icons.arrow_forward),
        onTap: () => widget.onNavigate?.call('notifikasi'),
      ),
    ];
  }

  List<Widget> _referralSection(
    BuildContext context,
    BidanDashboardData? data,
  ) {
    return [
      const _PageIntro(
        title: 'Rujukan',
        subtitle: 'Tinjau hasil skrining yang perlu keputusan lanjutan.',
      ),
      const SizedBox(height: 12),
      if (data?.referrals.isEmpty ?? true)
        const EmptyState(text: 'Belum ada rujukan masuk.')
      else
        ...data!.referrals
            .take(4)
            .map(
              (row) => _ReferralRow(
                referral: row,
                onTap: () => _openReferralDetail(context, row),
              ),
            ),
    ];
  }

  List<Widget> _validationSection(BidanDashboardState state) {
    return [
      const SectionTitle('Validasi Medis'),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SoftIcon(icon: Icons.medical_information_outlined),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Keputusan tindak lanjut',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Gunakan catatan singkat agar kader memahami arahan berikutnya.',
                          style: TextStyle(
                            color: LedgerColors.inkSoft,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                key: const Key('decisionDropdown'),
                initialValue: _decision,
                decoration: const InputDecoration(labelText: 'Keputusan'),
                items: const [
                  DropdownMenuItem(
                    value: 'observasi',
                    child: Text('Observasi'),
                  ),
                  DropdownMenuItem(
                    value: 'konseling',
                    child: Text('Konseling'),
                  ),
                  DropdownMenuItem(value: 'pmt', child: Text('PMT')),
                  DropdownMenuItem(
                    value: 'rujuk_puskesmas',
                    child: Text('Rujuk Puskesmas'),
                  ),
                  DropdownMenuItem(
                    value: 'cek_ulang_data',
                    child: Text('Cek ulang data'),
                  ),
                ],
                onChanged: (value) =>
                    setState(() => _decision = value ?? 'observasi'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _noteController,
                minLines: 2,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Catatan bidan'),
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                key: const Key('validateButton'),
                onPressed: state.isSavingValidation ? null : _validateReferral,
                icon: state.isSavingValidation
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_circle_outline),
                label: Text(
                  state.isSavingValidation ? 'Menyimpan...' : 'Simpan Validasi',
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 8),
      const Text(
        'Label risiko tetap skrining awal, bukan diagnosis.',
        style: TextStyle(color: LedgerColors.inkSoft, fontSize: 12),
      ),
      if (state.message != null &&
          !state.message!.toLowerCase().contains('distribusi') &&
          !state.message!.toLowerCase().contains('pdf')) ...[
        const SizedBox(height: 12),
        InlineMessage(text: state.message!, isError: state.isError),
      ],
    ];
  }

  List<Widget> _pmtSection(
    BidanDashboardState state,
    BidanDashboardData? data,
  ) {
    final stockCount = data?.pmtStock.length ?? 0;
    final lowStock = data?.pmtStock.where((row) => row.isLow).length ?? 0;
    return [
      const _PageIntro(
        title: 'PMT',
        subtitle: 'Pantau stok dan catat distribusi dari keputusan bidan.',
      ),
      const SizedBox(height: 12),
      _SummaryStrip(
        items: [
          _SummaryItem(
            label: 'Item PMT',
            value: '$stockCount',
            helper: 'tercatat',
            icon: Icons.inventory_2_outlined,
          ),
          _SummaryItem(
            label: 'Perhatian',
            value: '$lowStock',
            helper: 'stok menipis',
            icon: Icons.error_outline,
          ),
        ],
      ),
      const SizedBox(height: 12),
      if (data?.pmtStock.isEmpty ?? true)
        const EmptyState(text: 'Belum ada stok PMT.')
      else ...[
        ...data!.pmtStock.map((row) => _StockRow(stock: row)),
        const SizedBox(height: 8),
        FilledButton.icon(
          key: const Key('distributePmtButton'),
          onPressed: state.isDistributingPmt
              ? null
              : () => ref
                    .read(bidanDashboardControllerProvider.notifier)
                    .distributeFirstPmt(),
          icon: state.isDistributingPmt
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.inventory_outlined),
          label: Text(
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
      const _PageIntro(
        title: 'Laporan PDF',
        subtitle: 'Unduh rekap MVP sesuai kebutuhan Posyandu dan bidan.',
      ),
      const SizedBox(height: 12),
      _ReportRangePicker(
        startDate: state.reportStartDate,
        endDate: state.reportEndDate,
        onPick: (range) => ref
            .read(bidanDashboardControllerProvider.notifier)
            .setReportRange(range.start, range.end),
      ),
      const SizedBox(height: 12),
      _ReportPicker(
        onDownload: (type) => ref
            .read(bidanDashboardControllerProvider.notifier)
            .downloadReport(type),
      ),
      if (state.reportBytes != null) ...[
        const SizedBox(height: 12),
        LedgerPanel(
          title: 'Preview PDF siap',
          subtitle:
              'Laporan ${state.reportType ?? ''} sudah diterima dari server.',
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
      if (state.message != null &&
          state.message!.toLowerCase().contains('pdf')) ...[
        const SizedBox(height: 12),
        InlineMessage(text: state.message!, isError: state.isError),
      ],
    ];
  }

  List<Widget> _notificationSection(
    BuildContext context,
    BidanDashboardData? data,
  ) {
    return [
      const _PageIntro(
        title: 'Notifikasi',
        subtitle: 'Pesan sistem dari rujukan, validasi, dan PMT.',
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

  Future<void> _validateReferral() {
    return ref
        .read(bidanDashboardControllerProvider.notifier)
        .validateFirstReferral(decision: _decision, note: _noteController.text);
  }

  Future<void> _openReferralDetail(BuildContext context, Referral referral) {
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
              'Detail rujukan',
              style: Theme.of(sheetContext).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              '${referral.namaBalita} | Ibu: ${referral.namaIbu}',
              style: const TextStyle(color: LedgerColors.inkSoft),
            ),
            const SizedBox(height: 12),
            RiskBadge(risk: referral.riskLevel),
            const SizedBox(height: 12),
            const Text(
              'Validasi ini mencatat keputusan tindak lanjut, bukan diagnosis.',
              style: TextStyle(color: LedgerColors.inkSoft),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              key: const Key('validateReferralDetailButton'),
              onPressed: () async {
                await ref
                    .read(bidanDashboardControllerProvider.notifier)
                    .validateReferral(
                      referralId: referral.id,
                      childId: referral.childId,
                      decision: _decision,
                      note: _noteController.text,
                    );
                if (sheetContext.mounted) Navigator.of(sheetContext).pop();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Validasi tersimpan')),
                  );
                }
              },
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Simpan Validasi'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openNotification(
    BuildContext context,
    AppNotification notification,
  ) async {
    await ref
        .read(bidanDashboardControllerProvider.notifier)
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

class _ReferralRow extends StatelessWidget {
  const _ReferralRow({required this.referral, required this.onTap});

  final Referral referral;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return LedgerListRow(
      title: referral.namaBalita,
      subtitle:
          'Ibu: ${referral.namaIbu} | ${_readableStatus(referral.status)}',
      trailing: RiskBadge(risk: referral.riskLevel),
      onTap: onTap,
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
      subtitle:
          'Stok ${stock.stock} ${stock.unit} | Minimum ${stock.minimumStock}',
      trailing: StatusBadge(
        label: stock.isLow ? 'Stok menipis' : 'Aman',
        color: stock.isLow ? LedgerColors.attention : LedgerColors.primary,
        softColor: stock.isLow
            ? LedgerColors.attentionSoft
            : LedgerColors.primarySoft,
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          children: [
            _ReportAction(
              title: 'Prediksi Risiko',
              subtitle: 'Rekap hasil skrining per sesi.',
              icon: Icons.fact_check_outlined,
              buttonLabel: 'Download Prediksi',
              buttonKey: const Key('downloadReport-prediksi'),
              onPressed: () => onDownload('prediksi'),
            ),
            const Divider(height: 1),
            _ReportAction(
              title: 'Kehadiran Posyandu',
              subtitle: 'Daftar balita yang hadir pada sesi.',
              icon: Icons.event_available_outlined,
              buttonLabel: 'Download Kehadiran',
              buttonKey: const Key('downloadReport-kehadiran'),
              onPressed: () => onDownload('kehadiran'),
            ),
            const Divider(height: 1),
            _ReportAction(
              title: 'Distribusi PMT',
              subtitle: 'Catatan paket PMT yang disalurkan.',
              icon: Icons.inventory_outlined,
              buttonLabel: 'Download Distribusi',
              buttonKey: const Key('downloadReport-distribusi-pmt'),
              onPressed: () => onDownload('distribusi-pmt'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PageIntro extends StatelessWidget {
  const _PageIntro({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(color: LedgerColors.inkSoft, height: 1.35),
        ),
      ],
    );
  }
}

class _SummaryStrip extends StatelessWidget {
  const _SummaryStrip({required this.items});

  final List<_SummaryItem> items;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var index = 0; index < items.length; index++) ...[
          Expanded(child: _SummaryTile(item: items[index])),
          if (index != items.length - 1) const SizedBox(width: 10),
        ],
      ],
    );
  }
}

class _SummaryItem {
  const _SummaryItem({
    required this.label,
    required this.value,
    required this.helper,
    required this.icon,
  });

  final String label;
  final String value;
  final String helper;
  final IconData icon;
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({required this.item});

  final _SummaryItem item;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SoftIcon(icon: item.icon),
            const SizedBox(height: 12),
            Text(
              item.value,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 2),
            Text(
              item.label,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 2),
            Text(
              item.helper,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: LedgerColors.inkSoft,
                fontSize: 12,
                height: 1.25,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SoftIcon extends StatelessWidget {
  const _SoftIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: LedgerColors.primarySoft,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 20, color: LedgerColors.primary),
    );
  }
}

class _ReportRangePicker extends StatelessWidget {
  const _ReportRangePicker({
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

class _ReportAction extends StatelessWidget {
  const _ReportAction({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.buttonLabel,
    required this.buttonKey,
    required this.onPressed,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String buttonLabel;
  final Key buttonKey;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SoftIcon(icon: icon),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: LedgerColors.inkSoft,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            key: buttonKey,
            onPressed: onPressed,
            icon: const Icon(Icons.download_outlined),
            label: Text(buttonLabel),
          ),
        ],
      ),
    );
  }
}

String _readableStatus(String status) {
  return status.replaceAll('_', ' ');
}
