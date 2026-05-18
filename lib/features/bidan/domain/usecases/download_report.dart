import 'dart:typed_data';

import '../repositories/bidan_repository.dart';

class DownloadReport {
  const DownloadReport(this._repository);

  final BidanRepository _repository;

  Future<Uint8List> call(String type) => _repository.downloadReport(type);
}
