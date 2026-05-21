import 'dart:typed_data';

import '../../../kader/domain/entities/app_notification.dart';
import '../../domain/entities/bidan_dashboard_data.dart';
import '../../domain/entities/pmt_stock.dart';
import '../../domain/entities/referral.dart';
import '../../domain/entities/validation_result.dart';
import '../../domain/repositories/bidan_repository.dart';
import '../datasources/bidan_remote_data_source.dart';

class BidanRepositoryImpl implements BidanRepository {
  const BidanRepositoryImpl(this._remoteDataSource);

  final BidanRemoteDataSource _remoteDataSource;

  @override
  Future<BidanDashboardData> dashboard() async {
    final referrals = await this.referrals();
    final pmt = await pmtStock();
    final notifications = await this.notifications();
    return BidanDashboardData(
      referrals: referrals,
      pmtStock: pmt,
      notifications: notifications,
    );
  }

  @override
  Future<List<Referral>> referrals({String search = '', String? status}) {
    return _remoteDataSource.referrals(search: search, status: status);
  }

  @override
  Future<ValidationResult> validateReferral({
    required int referralId,
    required String decision,
    required String note,
  }) {
    return _remoteDataSource.validateReferral(
      referralId: referralId,
      decision: decision,
      note: note,
    );
  }

  @override
  Future<void> distributePmt({
    required int validationId,
    required int childId,
    required int pmtId,
    required int quantity,
  }) {
    return _remoteDataSource.distributePmt(
      validationId: validationId,
      childId: childId,
      pmtId: pmtId,
      quantity: quantity,
    );
  }

  @override
  Future<List<PmtStock>> pmtStock() => _remoteDataSource.pmtStock();

  @override
  Future<Uint8List> downloadReport(String type) {
    return _remoteDataSource.downloadReport(type);
  }

  @override
  Future<List<AppNotification>> notifications() {
    return _remoteDataSource.notifications();
  }

  @override
  Future<void> markNotificationRead(int id) {
    return _remoteDataSource.markNotificationRead(id);
  }
}
