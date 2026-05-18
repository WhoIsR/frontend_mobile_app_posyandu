import '../entities/measurement_result.dart';
import '../repositories/kader_repository.dart';

class RetryPrediction {
  const RetryPrediction(this._repository);

  final KaderRepository _repository;

  Future<MeasurementResult> call(int measurementId) {
    return _repository.retryPrediction(measurementId);
  }
}
