import 'dart:typed_data';

import '../../domain/entities/admin_account.dart';
import '../../domain/entities/admin_posyandu.dart';
import '../../domain/repositories/admin_repository.dart';
import '../datasources/admin_remote_data_source.dart';

class AdminRepositoryImpl implements AdminRepository {
  const AdminRepositoryImpl(this._remoteDataSource);

  final AdminRemoteDataSource _remoteDataSource;

  @override
  Future<List<AdminAccount>> accounts() => _remoteDataSource.accounts();

  @override
  Future<List<AdminPosyandu>> posyandu() => _remoteDataSource.posyandu();

  @override
  Future<Uint8List> downloadReport(
    String type, {
    String? startDate,
    String? endDate,
  }) {
    return _remoteDataSource.downloadReport(
      type,
      startDate: startDate,
      endDate: endDate,
    );
  }
}
