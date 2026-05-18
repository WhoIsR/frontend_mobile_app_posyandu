import 'app_notification.dart';
import 'balita.dart';
import 'posyandu_session.dart';
import 'screening_item.dart';

class KaderDashboardData {
  const KaderDashboardData({
    required this.session,
    required this.children,
    required this.screening,
    required this.notifications,
  });

  final PosyanduSession? session;
  final List<Balita> children;
  final List<ScreeningItem> screening;
  final List<AppNotification> notifications;
}
