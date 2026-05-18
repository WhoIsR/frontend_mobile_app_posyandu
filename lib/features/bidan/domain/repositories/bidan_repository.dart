import 'dart:typed_data';

import '../../../kader/domain/entities/app_notification.dart';
import '../entities/bidan_dashboard_data.dart';
import '../entities/pmt_stock.dart';
import '../entities/referral.dart';
import '../entities/validation_result.dart';

abstract class BidanRepository {
  Future<BidanDashboardData> dashboard();
  Future<List<Referral>> referrals({String search = '', String? status});
  Future<ValidationResult> validateReferral({
    required int referralId,
    required String decision,
    required String note,
  });
  Future<List<PmtStock>> pmtStock();
  Future<Uint8List> downloadReport(String type);
  Future<List<AppNotification>> notifications();
}
