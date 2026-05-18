import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers.dart';
import '../../../../core/network/api_exception.dart';
import '../../domain/entities/bidan_dashboard_data.dart';

class BidanDashboardState {
  const BidanDashboardState({
    this.data,
    this.isLoading = true,
    this.isSavingValidation = false,
    this.message,
    this.isError = false,
  });

  final BidanDashboardData? data;
  final bool isLoading;
  final bool isSavingValidation;
  final String? message;
  final bool isError;

  BidanDashboardState copyWith({
    BidanDashboardData? data,
    bool? isLoading,
    bool? isSavingValidation,
    String? message,
    bool clearMessage = false,
    bool? isError,
  }) {
    return BidanDashboardState(
      data: data ?? this.data,
      isLoading: isLoading ?? this.isLoading,
      isSavingValidation: isSavingValidation ?? this.isSavingValidation,
      message: clearMessage ? null : message ?? this.message,
      isError: isError ?? this.isError,
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
      await ref.read(validateReferralProvider)(
        referralId: referrals.first.id,
        decision: decision,
        note: note.trim().isEmpty ? 'Observasi dan pantau ulang.' : note.trim(),
      );
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
