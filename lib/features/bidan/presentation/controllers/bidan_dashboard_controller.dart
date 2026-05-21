import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers.dart';
import '../../../../core/network/api_exception.dart';
import '../../../kader/domain/entities/app_notification.dart';
import '../../domain/entities/bidan_dashboard_data.dart';

class BidanDashboardState {
  const BidanDashboardState({
    this.data,
    this.isLoading = true,
    this.isSavingValidation = false,
    this.isDistributingPmt = false,
    this.message,
    this.isError = false,
    this.reportBytes,
    this.reportType,
    this.reportStartDate,
    this.reportEndDate,
  });

  final BidanDashboardData? data;
  final bool isLoading;
  final bool isSavingValidation;
  final bool isDistributingPmt;
  final String? message;
  final bool isError;
  final Uint8List? reportBytes;
  final String? reportType;
  final String? reportStartDate;
  final String? reportEndDate;

  BidanDashboardState copyWith({
    BidanDashboardData? data,
    bool? isLoading,
    bool? isSavingValidation,
    bool? isDistributingPmt,
    String? message,
    bool clearMessage = false,
    bool? isError,
    Uint8List? reportBytes,
    String? reportType,
    bool clearReport = false,
    String? reportStartDate,
    String? reportEndDate,
  }) {
    return BidanDashboardState(
      data: data ?? this.data,
      isLoading: isLoading ?? this.isLoading,
      isSavingValidation: isSavingValidation ?? this.isSavingValidation,
      isDistributingPmt: isDistributingPmt ?? this.isDistributingPmt,
      message: clearMessage ? null : message ?? this.message,
      isError: isError ?? this.isError,
      reportBytes: clearReport ? null : reportBytes ?? this.reportBytes,
      reportType: clearReport ? null : reportType ?? this.reportType,
      reportStartDate: reportStartDate ?? this.reportStartDate,
      reportEndDate: reportEndDate ?? this.reportEndDate,
    );
  }
}

class BidanDashboardController extends Notifier<BidanDashboardState> {
  int? _lastPmtValidationId;
  int? _lastPmtChildId;

  @override
  BidanDashboardState build() {
    Future.microtask(load);
    return const BidanDashboardState();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearMessage: true);
    try {
      final data = await ref.read(getBidanDashboardProvider)();
      state = BidanDashboardState(data: data, isLoading: false);
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        message: _errorText(error),
        isError: true,
      );
    }
  }

  Future<void> validateFirstReferral({
    required String decision,
    required String note,
  }) async {
    final referrals = state.data?.referrals ?? const [];
    if (referrals.isEmpty) {
      state = state.copyWith(
        message: 'Belum ada rujukan untuk divalidasi.',
        isError: true,
      );
      return;
    }
    state = state.copyWith(isSavingValidation: true, clearMessage: true);
    try {
      final validation = await ref.read(validateReferralProvider)(
        referralId: referrals.first.id,
        decision: decision,
        note: note.trim().isEmpty ? 'Observasi dan pantau ulang.' : note.trim(),
      );
      if (validation.decision == 'pmt') {
        _lastPmtValidationId = validation.id;
        _lastPmtChildId = referrals.first.childId;
      }
      final data = await ref.read(getBidanDashboardProvider)();
      state = BidanDashboardState(
        data: data,
        isLoading: false,
        message: 'Validasi tersimpan',
      );
    } catch (error) {
      state = state.copyWith(
        isSavingValidation: false,
        message: _errorText(error),
        isError: true,
      );
    }
  }

  Future<void> distributeFirstPmt() async {
    final pmtStock = state.data?.pmtStock ?? const [];
    final validationId = _lastPmtValidationId;
    final childId = _lastPmtChildId;
    if (validationId == null || childId == null) {
      state = state.copyWith(
        message: 'Simpan validasi dengan keputusan PMT terlebih dulu.',
        isError: true,
      );
      return;
    }
    if (pmtStock.isEmpty) {
      state = state.copyWith(message: 'Belum ada stok PMT.', isError: true);
      return;
    }
    state = state.copyWith(isDistributingPmt: true, clearMessage: true);
    try {
      await ref.read(distributePmtProvider)(
        validationId: validationId,
        childId: childId,
        pmtId: pmtStock.first.id,
        quantity: 1,
      );
      final data = await ref.read(getBidanDashboardProvider)();
      state = BidanDashboardState(
        data: data,
        isLoading: false,
        message: 'Distribusi PMT tersimpan',
      );
    } catch (error) {
      state = state.copyWith(
        isDistributingPmt: false,
        message: _errorText(error),
        isError: true,
      );
    }
  }

  Future<void> downloadReport(String type) async {
    try {
      final bytes = await ref.read(downloadReportProvider)(
        type,
        startDate: state.reportStartDate,
        endDate: state.reportEndDate,
      );
      state = state.copyWith(
        message: 'Preview PDF siap',
        isError: false,
        reportBytes: bytes,
        reportType: type,
      );
    } catch (error) {
      state = state.copyWith(message: _errorText(error), isError: true);
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
