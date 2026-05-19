import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers.dart';
import '../../../../core/network/api_exception.dart';
import '../../domain/entities/bidan_dashboard_data.dart';

class BidanDashboardState {
  const BidanDashboardState({
    this.data,
    this.isLoading = true,
    this.isSavingValidation = false,
    this.isDistributingPmt = false,
    this.message,
    this.isError = false,
  });

  final BidanDashboardData? data;
  final bool isLoading;
  final bool isSavingValidation;
  final bool isDistributingPmt;
  final String? message;
  final bool isError;

  BidanDashboardState copyWith({
    BidanDashboardData? data,
    bool? isLoading,
    bool? isSavingValidation,
    bool? isDistributingPmt,
    String? message,
    bool clearMessage = false,
    bool? isError,
  }) {
    return BidanDashboardState(
      data: data ?? this.data,
      isLoading: isLoading ?? this.isLoading,
      isSavingValidation: isSavingValidation ?? this.isSavingValidation,
      isDistributingPmt: isDistributingPmt ?? this.isDistributingPmt,
      message: clearMessage ? null : message ?? this.message,
      isError: isError ?? this.isError,
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
      final bytes = await ref.read(downloadReportProvider)(type);
      state = state.copyWith(
        message: 'PDF berhasil diminta (${bytes.lengthInBytes} byte).',
        isError: false,
      );
    } catch (error) {
      state = state.copyWith(message: _errorText(error), isError: true);
    }
  }

  String _errorText(Object error) {
    if (error is ApiException) return error.message;
    return 'Koneksi ke server belum berhasil. Coba lagi sebentar.';
  }
}

final bidanDashboardControllerProvider =
    NotifierProvider<BidanDashboardController, BidanDashboardState>(
      BidanDashboardController.new,
    );
