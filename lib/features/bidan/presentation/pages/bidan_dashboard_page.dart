import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

import '../../../../app/ledger_theme.dart';
import '../../../../shared/widgets/ledger_widgets.dart';
import '../../../kader/domain/entities/app_notification.dart';
import '../../../kader/domain/entities/balita.dart';
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
  final _referralSearchController = TextEditingController();
  final _childSearchController = TextEditingController();

  @override
  void dispose() {
    _referralSearchController.dispose();
    _childSearchController.dispose();
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
      'balita' => _childrenSection(context, state, data),
      'rujukan' => _referralSection(context, state, data),
      'pmt' => _pmtSection(context, state, data),
      'laporan' => _reportSection(state),
      'notifikasi' => _notificationSection(context, data),
      _ => _homeSection(context, state, data),
    };
  }

  // ─────────────────────────────────────────────────────────
  //  HOME
  // ─────────────────────────────────────────────────────────

  List<Widget> _homeSection(
    BuildContext context,
    BidanDashboardState state,
    BidanDashboardData? data,
  ) {
    final referrals = data?.referrals.length ?? 0;
    final waiting =
        data?.referrals
            .where((row) => row.status == 'menunggu_validasi')
            .length ??
        0;
    final pmtItems = data?.pmtStock.length ?? 0;
    final lowStock = data?.pmtStock.where((row) => row.isLow).length ?? 0;
    final pendingPmt = state.pendingPmtQueue.length;
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
            helper: pendingPmt > 0
                ? '$pendingPmt antrean distribusi'
                : lowStock > 0
                    ? '$lowStock stok menipis'
                    : 'stok aman',
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
        onTap: () => widget.onNavigate?.call('rujukan'),
      ),
      LedgerListRow(
        title: 'Stok dan distribusi PMT',
        subtitle: pendingPmt > 0
            ? '$pendingPmt balita menunggu distribusi PMT.'
            : lowStock > 0
                ? '$lowStock item perlu dicek sebelum distribusi.'
                : 'Stok PMT saat ini aman untuk tindak lanjut.',
        onTap: () => widget.onNavigate?.call('pmt'),
      ),
      LedgerListRow(
        title: 'Notifikasi',
        subtitle: '$notifications pesan masuk.',
        onTap: () => widget.onNavigate?.call('notifikasi'),
      ),
    ];
  }

  // ─────────────────────────────────────────────────────────
  //  RUJUKAN — with pagination, no static validation section
  // ─────────────────────────────────────────────────────────

  List<Widget> _referralSection(
    BuildContext context,
    BidanDashboardState state,
    BidanDashboardData? data,
  ) {
    final allReferrals = data?.referrals ?? const [];
    final query = state.referralSearchQuery.trim().toLowerCase();
    final filteredReferrals = allReferrals.where((ref) {
      if (query.isEmpty) return true;
      return ref.namaBalita.toLowerCase().contains(query) ||
             ref.namaIbu.toLowerCase().contains(query);
    }).toList();

    final waiting =
        filteredReferrals
            .where((row) => row.status == 'menunggu_validasi')
            .length;

    return [
      const _PageIntro(
        title: 'Rujukan',
        subtitle:
            'Ketuk rujukan untuk melihat detail dan memberikan keputusan.',
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _referralSearchController,
        onChanged: (val) {
          ref.read(bidanDashboardControllerProvider.notifier).searchReferrals(val);
        },
        decoration: const InputDecoration(
          prefixIcon: Icon(Icons.search),
          labelText: 'Cari rujukan nama balita atau ibu',
        ),
      ),
      const SizedBox(height: 12),
      if (waiting > 0) ...[
        StatusBadge(
          label: '$waiting menunggu validasi',
          color: LedgerColors.attention,
          softColor: LedgerColors.attentionSoft,
        ),
        const SizedBox(height: 12),
      ],
      if (filteredReferrals.isEmpty)
        const EmptyState(text: 'Belum ada rujukan yang cocok.')
      else
        _PaginatedReferralList(
          referrals: filteredReferrals,
          onTap: (row) => _openReferralDetail(context, row),
        ),
      if (state.message != null &&
          !state.message!.toLowerCase().contains('distribusi') &&
          !state.message!.toLowerCase().contains('pdf')) ...[
        const SizedBox(height: 12),
        InlineMessage(text: state.message!, isError: state.isError),
      ],
    ];
  }

  // ─────────────────────────────────────────────────────────
  //  PMT — with distribution form per pending item
  // ─────────────────────────────────────────────────────────

  List<Widget> _pmtSection(
    BuildContext context,
    BidanDashboardState state,
    BidanDashboardData? data,
  ) {
    final stockCount = data?.pmtStock.length ?? 0;
    final lowStock = data?.pmtStock.where((row) => row.isLow).length ?? 0;
    final queue = state.pendingPmtQueue;
    return [
      const _PageIntro(
        title: 'PMT',
        subtitle: 'Pantau stok dan selesaikan distribusi dari keputusan bidan.',
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
            label: queue.isNotEmpty ? 'Antrean' : 'Perhatian',
            value: queue.isNotEmpty ? '${queue.length}' : '$lowStock',
            helper: queue.isNotEmpty
                ? 'balita perlu distribusi'
                : 'stok menipis',
            icon: queue.isNotEmpty ? Icons.pending_outlined : Icons.error_outline,
          ),
        ],
      ),
      const SizedBox(height: 12),

      // Pending distribution queue
      if (queue.isNotEmpty) ...[
        const SectionTitle('Antrean Distribusi'),
        const Text(
          'Balita berikut telah divalidasi dengan keputusan PMT. '
          'Pilih item PMT dan jumlah untuk masing-masing.',
          style: TextStyle(color: LedgerColors.inkSoft, height: 1.4),
        ),
        const SizedBox(height: 10),
        for (var i = 0; i < queue.length; i++)
          _PmtDistributionCard(
            key: ValueKey('pmt-dist-$i'),
            item: queue[i],
            index: i,
            stockItems: data?.pmtStock ?? const [],
            isDistributing: state.isDistributingPmt,
            onDistribute: ({required int pmtId, required int quantity}) =>
                ref
                    .read(bidanDashboardControllerProvider.notifier)
                    .distributePmt(
                      pendingIndex: i,
                      pmtId: pmtId,
                      quantity: quantity,
                    ),
          ),
        const SizedBox(height: 8),
      ],

      // Stock overview
      const SectionTitle('Stok Tersedia'),
      if (data?.pmtStock.isEmpty ?? true)
        const EmptyState(text: 'Belum ada stok PMT.')
      else
        ...data!.pmtStock.map((row) => _StockRow(stock: row)),
      if (state.message != null &&
          state.message!.toLowerCase().contains('distribusi')) ...[
        const SizedBox(height: 12),
        InlineMessage(text: state.message!, isError: state.isError),
      ],
    ];
  }

  // ─────────────────────────────────────────────────────────
  //  LAPORAN — polished with loading states
  // ─────────────────────────────────────────────────────────

  List<Widget> _reportSection(BidanDashboardState state) {
    return [
      const _PageIntro(
        title: 'Laporan PDF',
        subtitle:
            'Pilih rentang tanggal lalu unduh laporan sesuai kebutuhan posyandu.',
      ),
      const SizedBox(height: 12),

      // Step 1: Date range
      _ReportRangePicker(
        startDate: state.reportStartDate,
        endDate: state.reportEndDate,
        onPick: (range) => ref
            .read(bidanDashboardControllerProvider.notifier)
            .setReportRange(range.start, range.end),
      ),
      const SizedBox(height: 8),
      Text(
        state.reportStartDate != null
            ? 'Laporan akan difilter dari ${state.reportStartDate} s/d ${state.reportEndDate}'
            : 'Semua data akan disertakan karena rentang belum dipilih.',
        style: const TextStyle(
          color: LedgerColors.inkSoft,
          fontSize: 12,
          fontStyle: FontStyle.italic,
        ),
      ),
      const SizedBox(height: 16),

      // Step 2: Choose report type
      const SectionTitle('Pilih Jenis Laporan'),
      _ReportPicker(
        downloadingType: state.downloadingReportType,
        onDownload: (type) => ref
            .read(bidanDashboardControllerProvider.notifier)
            .downloadReport(type),
      ),

      // Step 3: Interactive PDF Preview
      if (state.reportBytes != null) ...[
        const SizedBox(height: 16),
        if (Platform.environment.containsKey('FLUTTER_TEST')) ...[
          LedgerPanel(
            title: 'Laporan siap',
            subtitle: 'Laporan ${_reportLabel(state.reportType)} berhasil dibuat.',
            accent: LedgerColors.primary,
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.ios_share_outlined),
                    label: const Text('Bagikan'),
                  ),
                ),
              ],
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

      if (state.message != null &&
          state.message!.toLowerCase().contains('pdf')) ...[
        const SizedBox(height: 12),
        InlineMessage(text: state.message!, isError: state.isError),
      ],
    ];
  }

  // ─────────────────────────────────────────────────────────
  //  NOTIFIKASI
  // ─────────────────────────────────────────────────────────

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
        ...data!.notifications.map(
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

  // ─────────────────────────────────────────────────────────
  //  BOTTOM SHEET: Referral Detail + Validation
  // ─────────────────────────────────────────────────────────

  Future<void> _openReferralDetail(BuildContext context, Referral referral) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => _ReferralDetailSheet(
        referral: referral,
        onValidate: ({
          required String decision,
          required String note,
        }) async {
          await ref
              .read(bidanDashboardControllerProvider.notifier)
              .validateReferral(
                referralId: referral.id,
                childId: referral.childId,
                childName: referral.namaBalita,
                decision: decision,
                note: note,
              );
          if (sheetContext.mounted) Navigator.of(sheetContext).pop();
          if (!context.mounted) return;
          final state = ref.read(bidanDashboardControllerProvider);
          // If the decision was PMT, show a shortcut to tab PMT
          if (decision == 'pmt') {
            ScaffoldMessenger.of(context)
              ..clearSnackBars()
              ..showSnackBar(
                SnackBar(
                  content: const Text(
                    'Validasi tersimpan — lanjut distribusi PMT',
                  ),
                  action: SnackBarAction(
                    label: 'Buka Tab PMT',
                    onPressed: () => widget.onNavigate?.call('pmt'),
                  ),
                  duration: const Duration(seconds: 5),
                ),
              );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message ?? 'Validasi tersimpan'),
              ),
            );
          }
        },
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

  List<Widget> _childrenSection(
    BuildContext context,
    BidanDashboardState state,
    BidanDashboardData? data,
  ) {
    final allChildren = state.children;
    final query = state.childSearchQuery.trim().toLowerCase();
    final filtered = allChildren.where((child) {
      if (query.isEmpty) return true;
      return child.namaBalita.toLowerCase().contains(query) ||
             child.namaIbu.toLowerCase().contains(query) ||
             (child.nikBalita?.toLowerCase().contains(query) ?? false);
    }).toList();

    return [
      const _PageIntro(
        title: 'Data Balita',
        subtitle: 'Daftar balita terdaftar di seluruh wilayah Posyandu Desa.',
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _childSearchController,
        onChanged: (val) {
          ref.read(bidanDashboardControllerProvider.notifier).searchChildren(val);
        },
        decoration: const InputDecoration(
          prefixIcon: Icon(Icons.search),
          labelText: 'Cari balita berdasarkan nama, ibu, atau NIK',
        ),
      ),
      const SizedBox(height: 16),
      if (filtered.isEmpty)
        const EmptyState(text: 'Belum ada data balita yang cocok.')
      else
        ...filtered.take(20).map((child) => _BidanChildCard(child: child)),
    ];
  }
}

// ═══════════════════════════════════════════════════════════
//  REFERRAL DETAIL BOTTOM SHEET
// ═══════════════════════════════════════════════════════════

class _ReferralDetailSheet extends StatefulWidget {
  const _ReferralDetailSheet({
    required this.referral,
    required this.onValidate,
  });

  final Referral referral;
  final Future<void> Function({
    required String decision,
    required String note,
  }) onValidate;

  @override
  State<_ReferralDetailSheet> createState() => _ReferralDetailSheetState();
}

class _ReferralDetailSheetState extends State<_ReferralDetailSheet> {
  final _noteController = TextEditingController(
    text: 'Observasi dan pantau ulang.',
  );
  String _decision = 'observasi';
  bool _isSaving = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final referral = widget.referral;
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Detail Rujukan',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              '${referral.namaBalita} | Ibu: ${referral.namaIbu}',
              style: const TextStyle(color: LedgerColors.inkSoft),
            ),
            const SizedBox(height: 12),
            _ReferralContextStrip(referral: referral),
            const SizedBox(height: 12),
            LedgerPanel(
              title: 'Konteks skrining',
              subtitle: 'Label risiko adalah skrining awal, bukan diagnosis.',
              accent: referral.riskLevel == 'tinggi'
                  ? LedgerColors.review
                  : LedgerColors.attention,
              child: Row(
                children: [
                  RiskBadge(risk: referral.riskLevel),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${_measurementText(referral)} | ${_readableStatus(referral.status)}',
                      style: const TextStyle(color: LedgerColors.inkSoft),
                    ),
                  ),
                ],
              ),
            ),
            const SectionTitle('Keputusan & catatan'),
            DropdownButtonFormField<String>(
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
            const SizedBox(height: 10),
            TextField(
              controller: _noteController,
              minLines: 2,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Catatan bidan'),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              key: const Key('validateReferralDetailButton'),
              onPressed: _isSaving
                  ? null
                  : () async {
                      setState(() => _isSaving = true);
                      await widget.onValidate(
                        decision: _decision,
                        note: _noteController.text,
                      );
                      if (mounted) setState(() => _isSaving = false);
                    },
              icon: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check_circle_outline),
              label: Text(
                _isSaving ? 'Menyimpan...' : 'Simpan Validasi',
              ),
            ),
            if (_decision == 'pmt') ...[
              const SizedBox(height: 8),
              const Text(
                'Setelah menyimpan, Anda bisa langsung distribusi PMT '
                'dari tab PMT.',
                style: TextStyle(
                  color: LedgerColors.inkSoft,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  PMT DISTRIBUTION CARD — per pending item
// ═══════════════════════════════════════════════════════════

class _PmtDistributionCard extends StatefulWidget {
  const _PmtDistributionCard({
    super.key,
    required this.item,
    required this.index,
    required this.stockItems,
    required this.isDistributing,
    required this.onDistribute,
  });

  final PendingPmtItem item;
  final int index;
  final List<PmtStock> stockItems;
  final bool isDistributing;
  final void Function({required int pmtId, required int quantity})
      onDistribute;

  @override
  State<_PmtDistributionCard> createState() => _PmtDistributionCardState();
}

class _PmtDistributionCardState extends State<_PmtDistributionCard> {
  int? _selectedPmtId;
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    if (widget.stockItems.isNotEmpty) {
      _selectedPmtId = widget.stockItems.first.id;
    }
  }

  @override
  void didUpdateWidget(covariant _PmtDistributionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_selectedPmtId == null && widget.stockItems.isNotEmpty) {
      _selectedPmtId = widget.stockItems.first.id;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedPmtId == null && widget.stockItems.isNotEmpty) {
      _selectedPmtId = widget.stockItems.first.id;
    }
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: LedgerColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: LedgerColors.bidanBlue.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: LedgerColors.bidanBlue.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: LedgerColors.bidanBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.child_care,
                    size: 20,
                    color: LedgerColors.bidanBlue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.item.childName,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Perlu distribusi PMT',
                        style: TextStyle(
                          color: LedgerColors.inkSoft,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                StatusBadge(
                  label: 'Antrean ${widget.index + 1}',
                  color: LedgerColors.bidanBlue,
                  softColor: LedgerColors.bidanBlue.withValues(alpha: 0.1),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (widget.stockItems.isEmpty)
              const Text(
                'Tidak ada stok PMT. Tambahkan stok terlebih dahulu.',
                style: TextStyle(color: LedgerColors.review),
              )
            else ...[
              DropdownButtonFormField<int>(
                key: Key('pmtDropdown-${widget.index}'),
                initialValue: _selectedPmtId,
                decoration: const InputDecoration(
                  labelText: 'Pilih item PMT',
                  isDense: true,
                ),
                items: widget.stockItems.map((stock) {
                  return DropdownMenuItem(
                    value: stock.id,
                    child: Text(
                      '${stock.name} — stok: ${stock.stock} ${stock.unit}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (value) =>
                    setState(() => _selectedPmtId = value),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Text(
                    'Jumlah: ',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  IconButton.outlined(
                    onPressed: _quantity > 1
                        ? () => setState(() => _quantity--)
                        : null,
                    icon: const Icon(Icons.remove, size: 16),
                    visualDensity: VisualDensity.compact,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      '$_quantity',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  IconButton.outlined(
                    onPressed: () => setState(() => _quantity++),
                    icon: const Icon(Icons.add, size: 16),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  key: Key('distributePmtButton-${widget.index}'),
                  onPressed: widget.isDistributing || _selectedPmtId == null
                      ? null
                      : () => widget.onDistribute(
                            pmtId: _selectedPmtId!,
                            quantity: _quantity,
                          ),
                  icon: widget.isDistributing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.inventory_outlined),
                  label: Text(
                    widget.isDistributing
                        ? 'Menyimpan...'
                        : 'Simpan Distribusi',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  PAGINATED REFERRAL LIST
// ═══════════════════════════════════════════════════════════

class _PaginatedReferralList extends StatefulWidget {
  const _PaginatedReferralList({
    required this.referrals,
    required this.onTap,
  });

  final List<Referral> referrals;
  final void Function(Referral) onTap;

  @override
  State<_PaginatedReferralList> createState() => _PaginatedReferralListState();
}

class _PaginatedReferralListState extends State<_PaginatedReferralList> {
  static const _pageSize = 5;
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    final total = widget.referrals.length;
    final totalPages = (total / _pageSize).ceil();
    final start = _page * _pageSize;
    final end = (start + _pageSize).clamp(0, total);
    final visible = widget.referrals.sublist(start, end);

    return Column(
      children: [
        ...visible.map(
          (row) => _ReferralRow(
            referral: row,
            onTap: () => widget.onTap(row),
          ),
        ),
        if (totalPages > 1) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton.outlined(
                onPressed:
                    _page > 0 ? () => setState(() => _page--) : null,
                icon: const Icon(Icons.chevron_left, size: 18),
                visualDensity: VisualDensity.compact,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  '${_page + 1} / $totalPages',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              IconButton.outlined(
                onPressed: _page < totalPages - 1
                    ? () => setState(() => _page++)
                    : null,
                icon: const Icon(Icons.chevron_right, size: 18),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ],
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  REUSABLE WIDGETS
// ═══════════════════════════════════════════════════════════

class _ReferralRow extends StatelessWidget {
  const _ReferralRow({required this.referral, required this.onTap});

  final Referral referral;
  final VoidCallback onTap;

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
            color: LedgerColors.bidanBlue.withValues(alpha: 0.06),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            referral.namaBalita,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        RiskBadge(risk: referral.riskLevel),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _ageText(referral),
                      style: const TextStyle(
                        color: LedgerColors.inkSoft,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      'Ibu: ${referral.namaIbu}',
                      style: const TextStyle(
                        color: LedgerColors.inkSoft,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _measurementText(referral),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _readableStatus(referral.status),
                      style: const TextStyle(
                        color: LedgerColors.inkSoft,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
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

class _ReferralContextStrip extends StatelessWidget {
  const _ReferralContextStrip({required this.referral});

  final Referral referral;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MiniInfoTile(
            label: 'Usia',
            value: _ageText(referral).replaceFirst('Usia ', ''),
            icon: Icons.cake_outlined,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MiniInfoTile(
            label: 'BB/TB',
            value: _measurementText(referral).replaceFirst('BB/TB: ', ''),
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
          Icon(icon, size: 18, color: LedgerColors.bidanBlue),
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

class _StockRow extends StatelessWidget {
  const _StockRow({required this.stock});

  final PmtStock stock;

  @override
  Widget build(BuildContext context) {
    return LedgerPanel(
      title: stock.isLow ? 'Prioritas distribusi' : stock.name,
      subtitle: stock.name,
      accent: stock.isLow ? LedgerColors.attention : LedgerColors.primary,
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Stok ${stock.stock} ${stock.unit}',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          Expanded(
            child: Text(
              'Minimum aman ${stock.minimumStock} ${stock.unit}',
              style: const TextStyle(color: LedgerColors.inkSoft),
            ),
          ),
          StatusBadge(
            label: stock.isLow ? 'Stok menipis' : 'Aman',
            color: stock.isLow ? LedgerColors.attention : LedgerColors.primary,
            softColor: stock.isLow
                ? LedgerColors.attentionSoft
                : LedgerColors.primarySoft,
          ),
        ],
      ),
    );
  }
}

class _ReportPicker extends StatelessWidget {
  const _ReportPicker({
    required this.onDownload,
    required this.downloadingType,
  });

  final Future<void> Function(String type) onDownload;
  final String? downloadingType;

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
              buttonLabel: 'Preview Laporan',
              buttonKey: const Key('downloadReport-prediksi'),
              isDownloading: downloadingType == 'prediksi',
              onPressed: () => onDownload('prediksi'),
            ),
            const Divider(height: 1),
            _ReportAction(
              title: 'Kehadiran Posyandu',
              subtitle: 'Daftar balita yang hadir pada sesi.',
              icon: Icons.event_available_outlined,
              buttonLabel: 'Preview Laporan',
              buttonKey: const Key('downloadReport-kehadiran'),
              isDownloading: downloadingType == 'kehadiran',
              onPressed: () => onDownload('kehadiran'),
            ),
            const Divider(height: 1),
            _ReportAction(
              title: 'Distribusi PMT',
              subtitle: 'Catatan paket PMT yang disalurkan.',
              icon: Icons.inventory_outlined,
              buttonLabel: 'Preview Laporan',
              buttonKey: const Key('downloadReport-distribusi-pmt'),
              isDownloading: downloadingType == 'distribusi-pmt',
              onPressed: () => onDownload('distribusi-pmt'),
            ),
            const Divider(height: 1),
            _ReportAction(
              title: 'Semua Laporan (Gabungan)',
              subtitle: 'Menggabungkan semua laporan di atas dalam satu dokumen.',
              icon: Icons.analytics_outlined,
              buttonLabel: 'Preview Semua',
              buttonKey: const Key('downloadReport-semua'),
              isDownloading: downloadingType == 'semua',
              onPressed: () => onDownload('semua'),
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
    required this.isDownloading,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String buttonLabel;
  final Key buttonKey;
  final VoidCallback onPressed;
  final bool isDownloading;

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
            onPressed: isDownloading ? null : onPressed,
            icon: isDownloading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.download_outlined),
            label: Text(isDownloading ? 'Mengunduh...' : buttonLabel),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  HELPERS
// ═══════════════════════════════════════════════════════════

String _readableStatus(String status) {
  return status.replaceAll('_', ' ');
}

String _ageText(Referral referral) {
  final raw = referral.tanggalLahir;
  if (raw == null) return 'Usia belum tercatat';
  final birthDate = DateTime.tryParse(raw);
  if (birthDate == null) return 'Usia belum tercatat';
  final now = DateTime.now();
  var months = (now.year - birthDate.year) * 12 + now.month - birthDate.month;
  if (now.day < birthDate.day) months -= 1;
  if (months < 0) months = 0;
  return 'Usia $months bulan';
}

String _measurementText(Referral referral) {
  final weight = referral.beratBadan;
  final height = referral.tinggiBadan;
  if (weight == null || height == null) return 'BB/TB belum tercatat';
  return 'BB/TB: ${_number(weight)} kg / ${_number(height)} cm';
}

String _number(double value) {
  return value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 1);
}

String _reportLabel(String? type) {
  return switch (type) {
    'prediksi' => 'Prediksi Risiko',
    'kehadiran' => 'Kehadiran Posyandu',
    'distribusi-pmt' => 'Distribusi PMT',
    _ => type ?? 'Posyandu',
  };
}

// ─────────────────────────────────────────────────────────
//  _BidanChildCard Widget and Helpers
// ─────────────────────────────────────────────────────────

class _BidanChildCard extends StatelessWidget {
  const _BidanChildCard({required this.child});

  final Balita child;

  @override
  Widget build(BuildContext context) {
    final ageTextStr = _formatAgeText(child.tanggalLahir);
    final weight = child.latestWeight;
    final height = child.latestHeight;
    final latestMeasured = weight == null || height == null
        ? 'Belum ada riwayat ukur'
        : 'Terakhir: ${_number(weight)} kg / ${_number(height)} cm';

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
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    ageTextStr,
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
                  if (child.nikBalita != null && child.nikBalita!.isNotEmpty)
                    Text(
                      'NIK: ${child.nikBalita}',
                      style: const TextStyle(
                        color: LedgerColors.inkSoft,
                        fontSize: 12,
                      ),
                    ),
                  const SizedBox(height: 6),
                  Text(
                    latestMeasured,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: LedgerColors.primarySoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                child.jenisKelamin == 'L' ? 'Laki-laki' : 'Perempuan',
                style: const TextStyle(
                  color: LedgerColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatAgeText(String? raw) {
  if (raw == null) return 'Usia belum tercatat';
  final birthDate = DateTime.tryParse(raw);
  if (birthDate == null) return 'Usia belum tercatat';
  final now = DateTime.now();
  var months = (now.year - birthDate.year) * 12 + now.month - birthDate.month;
  if (now.day < birthDate.day) months -= 1;
  if (months < 0) months = 0;
  return 'Usia $months bulan';
}
