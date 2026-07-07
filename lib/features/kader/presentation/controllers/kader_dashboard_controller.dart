import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers.dart';
import '../../../../core/network/api_exception.dart';
import '../../domain/entities/app_notification.dart';
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
    bool clearSelectedChild = false,
    bool? isLoading,
    bool? isSaving,
    String? message,
    bool clearMessage = false,
    bool? isError,
  }) {
    return KaderDashboardState(
      data: data ?? this.data,
      lastMeasurement: lastMeasurement ?? this.lastMeasurement,
      selectedChild: clearSelectedChild ? null : selectedChild ?? this.selectedChild,
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
    if (state.data == null) {
      state = state.copyWith(isLoading: true, clearMessage: true);
    } else {
      state = state.copyWith(clearMessage: true);
    }
    try {
      final data = await ref.read(getKaderDashboardProvider)();
      state = KaderDashboardState(
        data: data,
        isLoading: false,
        selectedChild: state.selectedChild,
        lastMeasurement: state.lastMeasurement,
      );
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

  void selectChild(Balita? child) {
    if (child == null) {
      state = state.copyWith(
        clearSelectedChild: true,
        clearMessage: true,
        isError: false,
      );
    } else {
      state = state.copyWith(
        selectedChild: child,
        message: '${child.namaBalita} dipilih untuk pengukuran.',
        isError: false,
      );
    }
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
      ref.read(analyticsServiceProvider).logEvent('balita_created', properties: {
        'child_id': created.id,
        'gender': request.jenisKelamin,
      });
    } catch (error) {
      state = state.copyWith(
        isSaving: false,
        message: _errorText(error),
        isError: true,
      );
      rethrow;
    }
  }

  Future<void> updateBalita(int id, CreateBalitaRequest request) async {
    state = state.copyWith(isSaving: true, clearMessage: true);
    try {
      final updated = await ref.read(updateBalitaProvider)(id, request);
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
        selectedChild: updated,
        lastMeasurement: state.lastMeasurement,
        isLoading: false,
        message: 'Profil balita diperbarui.',
      );
      ref.read(analyticsServiceProvider).logEvent('balita_updated', properties: {
        'child_id': id,
      });
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
    ref.read(analyticsServiceProvider).logEvent('measurement_form_started', properties: {
      'child_id': child.id,
    });
    try {
      final saved = await ref.read(saveMeasurementProvider)(
        sessionId: session.id,
        childId: child.id,
        weight: weight,
        height: height,
      );
      
      // Load fresh dashboard data from backend to ensure 100% sync
      final freshData = await ref.read(getKaderDashboardProvider)();
      
      state = KaderDashboardState(
        data: freshData,
        lastMeasurement: saved,
        selectedChild: saved.predictionFailed ? child : null,
        isLoading: false,
        message: saved.predictionFailed
            ? 'Pengukuran tersimpan. Prediksi dapat dicoba ulang saat koneksi stabil.'
            : 'Pengukuran tersimpan. Hasil skrining diperbarui.',
        isError: saved.predictionFailed,
      );
      ref.read(analyticsServiceProvider).logEvent('measurement_form_saved', properties: {
        'child_id': child.id,
        'weight': weight,
        'height': height,
        'prediction_failed': saved.predictionFailed,
        'risk_level': saved.riskLevel,
      });
    } catch (error) {
      final err = _errorText(error);
      ref.read(analyticsServiceProvider).logEvent('measurement_form_failed', properties: {
        'child_id': child.id,
        'error': err,
      });
      state = state.copyWith(
        isSaving: false,
        message: err,
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
        clearSelectedChild: !saved.predictionFailed,
        message: 'Prediksi berhasil dicoba ulang.',
        isError: false,
      );
      ref.read(analyticsServiceProvider).logEvent('prediction_retried', properties: {
        'measurement_id': measurement.id,
        'success': !saved.predictionFailed,
      });
    } catch (error) {
      state = state.copyWith(message: _errorText(error), isError: true);
    }
  }

  Future<void> openNotification(int id) async {
    await ref.read(kaderRepositoryProvider).markNotificationRead(id);
    final current = state.data;
    if (current == null) return;
    state = state.copyWith(
      data: KaderDashboardData(
        session: current.session,
        children: current.children,
        screening: current.screening,
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
}

final kaderDashboardControllerProvider =
    NotifierProvider<KaderDashboardController, KaderDashboardState>(
      KaderDashboardController.new,
    );
