import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers.dart';
import '../../../../core/network/api_exception.dart';
import '../../domain/entities/admin_account.dart';
import '../../domain/entities/admin_posyandu.dart';

class AdminDashboardState {
  const AdminDashboardState({
    this.accounts = const [],
    this.posyandu = const [],
    this.isLoading = true,
    this.message,
    this.isError = false,
    this.reportBytes,
    this.reportType,
    this.reportStartDate,
    this.reportEndDate,
  });

  final List<AdminAccount> accounts;
  final List<AdminPosyandu> posyandu;
  final bool isLoading;
  final String? message;
  final bool isError;
  final Uint8List? reportBytes;
  final String? reportType;
  final String? reportStartDate;
  final String? reportEndDate;

  AdminDashboardState copyWith({
    List<AdminAccount>? accounts,
    List<AdminPosyandu>? posyandu,
    bool? isLoading,
    String? message,
    bool clearMessage = false,
    bool? isError,
    Uint8List? reportBytes,
    String? reportType,
    bool clearReport = false,
    String? reportStartDate,
    String? reportEndDate,
  }) {
    return AdminDashboardState(
      accounts: accounts ?? this.accounts,
      posyandu: posyandu ?? this.posyandu,
      isLoading: isLoading ?? this.isLoading,
      message: clearMessage ? null : message ?? this.message,
      isError: isError ?? this.isError,
      reportBytes: clearReport ? null : reportBytes ?? this.reportBytes,
      reportType: clearReport ? null : reportType ?? this.reportType,
      reportStartDate: reportStartDate ?? this.reportStartDate,
      reportEndDate: reportEndDate ?? this.reportEndDate,
    );
  }
}

class AdminDashboardController extends Notifier<AdminDashboardState> {
  @override
  AdminDashboardState build() {
    Future.microtask(load);
    return const AdminDashboardState();
  }

  Future<void> load() async {
    try {
      final repository = ref.read(adminRepositoryProvider);
      final accounts = await repository.accounts();
      final posyandu = await repository.posyandu();
      state = AdminDashboardState(
        accounts: accounts,
        posyandu: posyandu,
        isLoading: false,
      );
    } catch (error) {
      state = AdminDashboardState(
        isLoading: false,
        message: error is ApiException
            ? error.message
            : 'Data admin belum bisa dimuat.',
        isError: true,
      );
    }
  }

  Future<void> downloadReport(String type) async {
    try {
      final bytes = await ref
          .read(adminRepositoryProvider)
          .downloadReport(
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
      state = state.copyWith(
        message: error is ApiException
            ? error.message
            : 'Laporan belum bisa diunduh.',
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

  String _dateOnly(DateTime value) => value.toIso8601String().split('T').first;
}

final adminDashboardControllerProvider =
    NotifierProvider<AdminDashboardController, AdminDashboardState>(
      AdminDashboardController.new,
    );
