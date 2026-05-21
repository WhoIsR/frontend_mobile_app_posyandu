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
    this.isSaving = false,
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
  final bool isSaving;
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
    bool? isSaving,
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
      isSaving: isSaving ?? this.isSaving,
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

  Future<void> saveAccount({
    int? id,
    required String name,
    required String nikNip,
    String? password,
    required String role,
    int? posyanduId,
    required String status,
  }) async {
    state = state.copyWith(isSaving: true, clearMessage: true);
    try {
      await ref
          .read(adminRepositoryProvider)
          .saveAccount(
            id: id,
            name: name,
            nikNip: nikNip,
            password: password,
            role: role,
            posyanduId: posyanduId,
            status: status,
          );
      final repository = ref.read(adminRepositoryProvider);
      state = state.copyWith(
        accounts: await repository.accounts(),
        isSaving: false,
        message: id == null ? 'Akun tersimpan.' : 'Status akun diperbarui.',
        isError: false,
      );
    } catch (error) {
      state = state.copyWith(
        isSaving: false,
        message: error is ApiException
            ? error.message
            : 'Akun belum bisa disimpan.',
        isError: true,
      );
      rethrow;
    }
  }

  Future<void> savePosyandu({
    int? id,
    required String name,
    required String address,
    required String village,
    required String district,
  }) async {
    state = state.copyWith(isSaving: true, clearMessage: true);
    try {
      await ref
          .read(adminRepositoryProvider)
          .savePosyandu(
            id: id,
            name: name,
            address: address,
            village: village,
            district: district,
          );
      final repository = ref.read(adminRepositoryProvider);
      state = state.copyWith(
        posyandu: await repository.posyandu(),
        isSaving: false,
        message: 'Posyandu tersimpan.',
        isError: false,
      );
    } catch (error) {
      state = state.copyWith(
        isSaving: false,
        message: error is ApiException
            ? error.message
            : 'Posyandu belum bisa disimpan.',
        isError: true,
      );
      rethrow;
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
