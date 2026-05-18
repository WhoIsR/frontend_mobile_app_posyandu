import '../entities/balita.dart';
import '../repositories/kader_repository.dart';

class SearchBalita {
  const SearchBalita(this._repository);

  final KaderRepository _repository;

  Future<List<Balita>> call(String search) {
    return _repository.searchChildren(search: search);
  }
}
