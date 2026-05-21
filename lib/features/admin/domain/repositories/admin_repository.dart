import 'dart:typed_data';

import '../entities/admin_account.dart';
import '../entities/admin_posyandu.dart';

abstract class AdminRepository {
  Future<List<AdminAccount>> accounts();
  Future<List<AdminPosyandu>> posyandu();
  Future<AdminAccount> saveAccount({
    int? id,
    required String name,
    required String nikNip,
    String? password,
    required String role,
    int? posyanduId,
    required String status,
  });
  Future<AdminPosyandu> savePosyandu({
    int? id,
    required String name,
    required String address,
    required String village,
    required String district,
  });
  Future<Uint8List> downloadReport(
    String type, {
    String? startDate,
    String? endDate,
  });
}
