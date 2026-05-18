import '../entities/measurement_result.dart';
import '../repositories/kader_repository.dart';

class SaveMeasurement {
  const SaveMeasurement(this._repository);

  final KaderRepository _repository;

  Future<MeasurementResult> call({
    required int sessionId,
    required int childId,
    required double weight,
    required double height,
  }) {
    return _repository.saveMeasurement(
      sessionId: sessionId,
      childId: childId,
      weight: weight,
      height: height,
    );
  }
}
