import '../entities/balita.dart';
import '../entities/create_balita_request.dart';
import '../repositories/kader_repository.dart';

class CreateBalita {
  const CreateBalita(this._repository);

  final KaderRepository _repository;

  Future<Balita> call(CreateBalitaRequest request) {
    return _repository.createBalita(request);
  }
}
