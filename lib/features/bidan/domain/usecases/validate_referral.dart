import '../entities/validation_result.dart';
import '../repositories/bidan_repository.dart';

class ValidateReferral {
  const ValidateReferral(this._repository);

  final BidanRepository _repository;

  Future<ValidationResult> call({
    required int referralId,
    required String decision,
    required String note,
  }) {
    return _repository.validateReferral(
      referralId: referralId,
      decision: decision,
      note: note,
    );
  }
}
