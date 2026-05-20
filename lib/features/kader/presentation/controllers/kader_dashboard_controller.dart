import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers.dart';
import '../../../../core/network/api_exception.dart';
import '../../domain/entities/balita.dart';
import '../../domain/entities/create_balita_request.dart';
import '../../domain/entities/kader_dashboard_data.dart';
import '../../domain/entities/measurement_result.dart';

class KaderDashboardState {
  const KaderDashboardState({
    this.data,
    this.lastMeasurement,
    this.selectedChild,
    this.isLoading = true,
    this.isSaving = false,
    this.message,
    this.isError = false,
  });

  final KaderDashboardData? data;
  final MeasurementResult? lastMeasurement;
  final Balita? selectedChild;
  final bool isLoading;
  final bool isSaving;
  final String? message;
  final bool isError;

  List<Balita> get children => data?.children ?? const [];

  KaderDashboardState copyWith({
    KaderDashboardData? data,
    MeasurementResult? lastMeasurement,
    Balita? selectedChild,
    bool? isLoading,
    bool? isSaving,
    String? message,
    bool clearMessage = false,
    bool? isError,
  }) {
    return KaderDashboardState(
      data: data ?? this.data,
      lastMeasurement: lastMeasurement ?? this.lastMeasurement,
      selectedChild: selectedChild ?? this.selectedChild,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      message: clearMessage ? null : message ?? this.message,
      isError: isError ?? this.isError,
    );
  }
}

class KaderDashboardController extends Notifier<KaderDashboardState> {
  @override
  KaderDashboardState build() {
    Future.microtask(load);
    return const KaderDashboardState();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearMessage: true);
    try {
      final data = await ref.read(getKaderDashboardProvider)();
      state = KaderDashboardState(data: data, isLoading: false);
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        message: _errorText(error),
        isError: true,
      );
    }
  }

  Future<void> search(String query) async {
    if (state.data == null) return;
    try {
      final children = await ref.read(searchBalitaProvider)(query);
      final current = state.data!;
      state = state.copyWith(
        data: KaderDashboardData(
          session: current.session,
          children: children,
          screening: current.screening,
          notifications: current.notifications,
        ),
        selectedChild: children.isEmpty ? null : state.selectedChild,
      );
    } catch (error) {
      state = state.copyWith(message: _errorText(error), isError: true);
    }
  }

  void selectChild(Balita child) {
    state = state.copyWith(
      selectedChild: child,
      message: '${child.namaBalita} dipilih untuk pengukuran.',
      isError: false,
    );
  }

  Future<void> createBalita(CreateBalitaRequest request) async {
    state = state.copyWith(isSaving: true, clearMessage: true);
    try {
      final created = await ref.read(createBalitaProvider)(request);
      final children = await ref.read(searchBalitaProvider)('');
      final current = state.data;
      state = KaderDashboardState(
        data: current == null
            ? null
            : KaderDashboardData(
                session: current.session,
                children: children,
                screening: current.screening,
                notifications: current.notifications,
              ),
        selectedChild: created,
        lastMeasurement: state.lastMeasurement,
        isLoading: false,
        message: 'Balita baru tersimpan.',
      );
    } catch (error) {
      state = state.copyWith(
        isSaving: false,
        message: _errorText(error),
        isError: true,
      );
      rethrow;
    }
  }

  Future<void> saveMeasurement({
    required double weight,
    required double height,
  }) async {
    final data = state.data;
    final session = data?.session;
    final child =
        state.selectedChild ??
        (data?.children.isEmpty ?? true ? null : data!.children.first);
    if (session == null || child == null) {
      state = state.copyWith(
        message: 'Pilih balita dulu sebelum menyimpan pengukuran.',
        isError: true,
      );
      return;
    }
    state = state.copyWith(isSaving: true, clearMessage: true);
    try {
      final saved = await ref.read(saveMeasurementProvider)(
        sessionId: session.id,
        childId: child.id,
        weight: weight,
        height: height,
      );
      final screening = await ref
          .read(kaderRepositoryProvider)
          .screening(session.id);
      state = KaderDashboardState(
        data: KaderDashboardData(
          session: session,
          children: data?.children ?? const [],
          screening: screening,
          notifications: data?.notifications ?? const [],
        ),
        lastMeasurement: saved,
        selectedChild: child,
        isLoading: false,
        message: saved.predictionFailed
            ? 'Pengukuran tersimpan. Prediksi dapat dicoba ulang saat koneksi stabil.'
            : 'Pengukuran tersimpan. Hasil skrining diperbarui.',
        isError: saved.predictionFailed,
      );
    } catch (error) {
      state = state.copyWith(
        isSaving: false,
        message: _errorText(error),
        isError: true,
      );
    }
  }

  Future<void> retryPrediction() async {
    final measurement = state.lastMeasurement;
    final data = state.data;
    if (measurement == null || data?.session == null) return;
    try {
      final saved = await ref.read(retryPredictionProvider)(measurement.id);
      final screening = await ref
          .read(kaderRepositoryProvider)
          .screening(data!.session!.id);
      state = state.copyWith(
        data: KaderDashboardData(
          session: data.session,
          children: data.children,
          screening: screening,
          notifications: data.notifications,
        ),
        lastMeasurement: saved,
        message: 'Prediksi berhasil dicoba ulang.',
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

final kaderDashboardControllerProvider =
    NotifierProvider<KaderDashboardController, KaderDashboardState>(
      KaderDashboardController.new,
    );
