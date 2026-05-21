import '../entities/app_notification.dart';
import '../entities/balita.dart';
import '../entities/create_balita_request.dart';
import '../entities/kader_dashboard_data.dart';
import '../entities/measurement_result.dart';
import '../entities/posyandu_session.dart';
import '../entities/screening_item.dart';

abstract class KaderRepository {
  Future<KaderDashboardData> dashboard();
  Future<PosyanduSession?> activeSession();
  Future<List<Balita>> searchChildren({String search = ''});
  Future<Balita> createBalita(CreateBalitaRequest request);
  Future<MeasurementResult> saveMeasurement({
    required int sessionId,
    required int childId,
    required double weight,
    required double height,
  });
  Future<MeasurementResult> retryPrediction(int measurementId);
  Future<List<ScreeningItem>> screening(int sessionId);
  Future<List<AppNotification>> notifications();
  Future<void> markNotificationRead(int id);
}
