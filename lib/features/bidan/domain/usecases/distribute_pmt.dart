import '../repositories/bidan_repository.dart';

class DistributePmt {
  const DistributePmt(this._repository);

  final BidanRepository _repository;

  Future<void> call({
    required int validationId,
    required int childId,
    required int pmtId,
    required int quantity,
  }) {
    return _repository.distributePmt(
      validationId: validationId,
      childId: childId,
      pmtId: pmtId,
      quantity: quantity,
    );
  }
}
