import '../entities/balita.dart';
import '../entities/create_balita_request.dart';
import '../repositories/kader_repository.dart';

class UpdateBalita {
  const UpdateBalita(this._repository);

  final KaderRepository _repository;

  Future<Balita> call(int id, CreateBalitaRequest request) {
    return _repository.updateBalita(id, request);
  }
}
