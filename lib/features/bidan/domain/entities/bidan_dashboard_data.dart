import '../../../kader/domain/entities/app_notification.dart';
import 'pmt_stock.dart';
import 'referral.dart';

class BidanDashboardData {
  const BidanDashboardData({
    required this.referrals,
    required this.pmtStock,
    required this.notifications,
  });

  final List<Referral> referrals;
  final List<PmtStock> pmtStock;
  final List<AppNotification> notifications;
}
