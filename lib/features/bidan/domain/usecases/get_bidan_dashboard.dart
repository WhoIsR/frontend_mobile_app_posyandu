import '../entities/bidan_dashboard_data.dart';
import '../repositories/bidan_repository.dart';

class GetBidanDashboard {
  const GetBidanDashboard(this._repository);

  final BidanRepository _repository;

  Future<BidanDashboardData> call() => _repository.dashboard();
}
