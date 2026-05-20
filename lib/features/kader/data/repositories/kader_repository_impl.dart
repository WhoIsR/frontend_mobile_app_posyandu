import '../../domain/entities/app_notification.dart';
import '../../domain/entities/balita.dart';
import '../../domain/entities/create_balita_request.dart';
import '../../domain/entities/kader_dashboard_data.dart';
import '../../domain/entities/measurement_result.dart';
import '../../domain/entities/posyandu_session.dart';
import '../../domain/entities/screening_item.dart';
import '../../domain/repositories/kader_repository.dart';
import '../datasources/kader_remote_data_source.dart';

class KaderRepositoryImpl implements KaderRepository {
  const KaderRepositoryImpl(this._remoteDataSource);

  final KaderRemoteDataSource _remoteDataSource;

  @override
  Future<KaderDashboardData> dashboard() async {
    final session = await activeSession();
    final children = await searchChildren();
    final notifications = await this.notifications();
    final screeningRows = session == null
        ? <ScreeningItem>[]
        : await screening(session.id);
    return KaderDashboardData(
      session: session,
      children: children,
      screening: screeningRows,
      notifications: notifications,
    );
  }

  @override
  Future<PosyanduSession?> activeSession() => _remoteDataSource.activeSession();

  @override
  Future<List<Balita>> searchChildren({String search = ''}) {
    return _remoteDataSource.children(search: search);
  }

  @override
  Future<Balita> createBalita(CreateBalitaRequest request) {
    return _remoteDataSource.createBalita(request);
  }

  @override
  Future<MeasurementResult> saveMeasurement({
    required int sessionId,
    required int childId,
    required double weight,
    required double height,
  }) {
    return _remoteDataSource.saveMeasurement(
      sessionId: sessionId,
      childId: childId,
      weight: weight,
      height: height,
    );
  }

  @override
  Future<MeasurementResult> retryPrediction(int measurementId) {
    return _remoteDataSource.retryPrediction(measurementId);
  }

  @override
  Future<List<ScreeningItem>> screening(int sessionId) {
    return _remoteDataSource.screening(sessionId);
  }

  @override
  Future<List<AppNotification>> notifications() {
    return _remoteDataSource.notifications();
  }
}
