import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers.dart';
import '../../../../core/network/api_exception.dart';
import '../../../kader/domain/entities/app_notification.dart';
import '../../../kader/domain/entities/balita.dart';
import '../../domain/entities/bidan_dashboard_data.dart';

class PendingPmtItem {
  const PendingPmtItem({
    required this.validationId,
    required this.childId,
    required this.childName,
    required this.referralId,
  });
  final int validationId;
  final int childId;
  final String childName;
  final int referralId;
}

class BidanDashboardState {
  const BidanDashboardState({
    this.data,
    this.isLoading = true,
    this.isSavingValidation = false,
    this.isDistributingPmt = false,
    this.pendingPmtQueue = const [],
    this.downloadingReportType,
    this.message,
    this.isError = false,
    this.reportBytes,
    this.reportType,
    this.reportStartDate,
    this.reportEndDate,
    this.children = const [],
    this.childSearchQuery = '',
    this.referralSearchQuery = '',
  });

  final BidanDashboardData? data;
  final bool isLoading;
  final bool isSavingValidation;
  final bool isDistributingPmt;
  final List<PendingPmtItem> pendingPmtQueue;
  final String? downloadingReportType;
  final String? message;
  final bool isError;
  final Uint8List? reportBytes;
  final String? reportType;
  final String? reportStartDate;
  final String? reportEndDate;
  final List<Balita> children;
  final String childSearchQuery;
  final String referralSearchQuery;

  BidanDashboardState copyWith({
    BidanDashboardData? data,
    bool? isLoading,
    bool? isSavingValidation,
    bool? isDistributingPmt,
    List<PendingPmtItem>? pendingPmtQueue,
    bool clearPendingPmt = false,
    String? downloadingReportType,
    bool clearDownloadingReportType = false,
    String? message,
    bool clearMessage = false,
    bool? isError,
    Uint8List? reportBytes,
    String? reportType,
    bool clearReport = false,
    String? reportStartDate,
    String? reportEndDate,
    List<Balita>? children,
    String? childSearchQuery,
    String? referralSearchQuery,
  }) {
    return BidanDashboardState(
      data: data ?? this.data,
      isLoading: isLoading ?? this.isLoading,
      isSavingValidation: isSavingValidation ?? this.isSavingValidation,
      isDistributingPmt: isDistributingPmt ?? this.isDistributingPmt,
      pendingPmtQueue: clearPendingPmt
          ? const []
          : pendingPmtQueue ?? this.pendingPmtQueue,
      downloadingReportType: clearDownloadingReportType
          ? null
          : downloadingReportType ?? this.downloadingReportType,
      message: clearMessage ? null : message ?? this.message,
      isError: isError ?? this.isError,
      reportBytes: clearReport ? null : reportBytes ?? this.reportBytes,
      reportType: clearReport ? null : reportType ?? this.reportType,
      reportStartDate: reportStartDate ?? this.reportStartDate,
      reportEndDate: reportEndDate ?? this.reportEndDate,
      children: children ?? this.children,
      childSearchQuery: childSearchQuery ?? this.childSearchQuery,
      referralSearchQuery: referralSearchQuery ?? this.referralSearchQuery,
    );
  }
}

class BidanDashboardController extends Notifier<BidanDashboardState> {
  @override
  BidanDashboardState build() {
    Future.microtask(load);
    return const BidanDashboardState();
  }

  Future<void> load() async {
    if (state.data == null) {
      state = state.copyWith(isLoading: true, clearMessage: true);
    } else {
      state = state.copyWith(clearMessage: true);
    }
    try {
      final data = await ref.read(getBidanDashboardProvider)();
      final children = await ref.read(kaderRepositoryProvider).searchChildren(search: '');
      state = BidanDashboardState(
        data: data,
        isLoading: false,
        pendingPmtQueue: state.pendingPmtQueue,
        reportStartDate: state.reportStartDate,
        reportEndDate: state.reportEndDate,
        children: children,
        childSearchQuery: state.childSearchQuery,
        referralSearchQuery: state.referralSearchQuery,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        message: _errorText(error),
        isError: true,
      );
    }
  }

  void searchChildren(String query) {
    state = state.copyWith(childSearchQuery: query);
  }

  void searchReferrals(String query) {
    state = state.copyWith(referralSearchQuery: query);
  }

  Future<void> validateReferral({
    required int referralId,
    required int childId,
    required String childName,
    required String decision,
    required String note,
  }) async {
    state = state.copyWith(isSavingValidation: true, clearMessage: true);
    ref.read(analyticsServiceProvider).logEvent('referral_validation_started', properties: {
      'referral_id': referralId,
      'child_id': childId,
    });
    try {
      final validation = await ref.read(validateReferralProvider)(
        referralId: referralId,
        decision: decision,
        note: note.trim().isEmpty ? 'Observasi dan pantau ulang.' : note.trim(),
      );
      final updatedQueue = validation.decision == 'pmt'
          ? [
              ...state.pendingPmtQueue,
              PendingPmtItem(
                validationId: validation.id,
                childId: childId,
                childName: childName,
                referralId: referralId,
              ),
            ]
          : state.pendingPmtQueue;
      final data = await ref.read(getBidanDashboardProvider)();
      state = BidanDashboardState(
        data: data,
        isLoading: false,
        pendingPmtQueue: updatedQueue,
        message: validation.decision == 'pmt'
            ? 'Validasi tersimpan — lanjut ke tab PMT untuk distribusi'
            : 'Validasi tersimpan',
      );
      ref.read(analyticsServiceProvider).logEvent('referral_validated', properties: {
        'referral_id': referralId,
        'child_id': childId,
        'decision': decision,
      });
    } catch (error) {
      state = state.copyWith(
        isSavingValidation: false,
        message: _errorText(error),
        isError: true,
      );
    }
  }

  Future<void> distributePmt({
    required int pendingIndex,
    required int pmtId,
    required int quantity,
  }) async {
    final queue = state.pendingPmtQueue;
    if (pendingIndex < 0 || pendingIndex >= queue.length) return;
    final item = queue[pendingIndex];
    state = state.copyWith(isDistributingPmt: true, clearMessage: true);
    try {
      await ref.read(distributePmtProvider)(
        validationId: item.validationId,
        childId: item.childId,
        pmtId: pmtId,
        quantity: quantity,
      );
      final updatedQueue = [...queue]..removeAt(pendingIndex);
      final data = await ref.read(getBidanDashboardProvider)();
      state = BidanDashboardState(
        data: data,
        isLoading: false,
        pendingPmtQueue: updatedQueue,
        message: 'Distribusi PMT tersimpan',
      );
      ref.read(analyticsServiceProvider).logEvent('pmt_distributed', properties: {
        'child_id': item.childId,
        'pmt_id': pmtId,
        'quantity': quantity,
      });
    } catch (error) {
      state = state.copyWith(
        isDistributingPmt: false,
        message: _errorText(error),
        isError: true,
      );
    }
  }

  Future<void> downloadReport(String type) async {
    state = state.copyWith(downloadingReportType: type, clearMessage: true);
    try {
      final bytes = await ref.read(downloadReportProvider)(
        type,
        startDate: state.reportStartDate,
        endDate: state.reportEndDate,
      );
      state = state.copyWith(
        clearDownloadingReportType: true,
        message: 'Preview PDF siap',
        isError: false,
        reportBytes: bytes,
        reportType: type,
      );
      ref.read(analyticsServiceProvider).logEvent('report_downloaded', properties: {
        'report_type': type,
        'start_date': state.reportStartDate,
        'end_date': state.reportEndDate,
      });
    } catch (error) {
      state = state.copyWith(
        clearDownloadingReportType: true,
        message: _errorText(error),
        isError: true,
      );
    }
  }

  void setReportRange(DateTime start, DateTime end) {
    state = state.copyWith(
      reportStartDate: _dateOnly(start),
      reportEndDate: _dateOnly(end),
      clearReport: true,
      clearMessage: true,
    );
  }

  Future<void> openNotification(int id) async {
    await ref.read(bidanRepositoryProvider).markNotificationRead(id);
    final current = state.data;
    if (current == null) return;
    state = state.copyWith(
      data: BidanDashboardData(
        referrals: current.referrals,
        pmtStock: current.pmtStock,
        notifications: current.notifications
            .map(
              (row) => row.id == id
                  ? AppNotification(
                      id: row.id,
                      title: row.title,
                      message: row.message,
                      type: row.type,
                      data: row.data,
                      isRead: true,
                    )
                  : row,
            )
            .toList(),
      ),
      message: 'Notifikasi dibuka.',
      isError: false,
    );
    ref.read(analyticsServiceProvider).logEvent('notification_opened', properties: {
      'notification_id': id,
    });
  }

  String _errorText(Object error) {
    if (error is ApiException) return error.message;
    return 'Koneksi ke server belum berhasil. Coba lagi sebentar.';
  }

  String _dateOnly(DateTime value) => value.toIso8601String().split('T').first;
}

final bidanDashboardControllerProvider =
    NotifierProvider<BidanDashboardController, BidanDashboardState>(
      BidanDashboardController.new,
    );
