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
  Future<AdminAccount> saveAccount({
    int? id,
    required String name,
    required String nikNip,
    String? password,
    required String role,
    int? posyanduId,
    required String status,
  }) {
    return _remoteDataSource.saveAccount(
      id: id,
      name: name,
      nikNip: nikNip,
      password: password,
      role: role,
      posyanduId: posyanduId,
      status: status,
    );
  }

  @override
  Future<AdminPosyandu> savePosyandu({
    int? id,
    required String name,
    required String address,
    required String village,
    required String district,
  }) {
    return _remoteDataSource.savePosyandu(
      id: id,
      name: name,
      address: address,
      village: village,
      district: district,
    );
  }

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
