import '../entities/kader_dashboard_data.dart';
import '../repositories/kader_repository.dart';

class GetKaderDashboard {
  const GetKaderDashboard(this._repository);

  final KaderRepository _repository;

  Future<KaderDashboardData> call() => _repository.dashboard();
}
