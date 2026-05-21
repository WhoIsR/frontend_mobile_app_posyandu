import 'dart:typed_data';

import '../entities/admin_account.dart';
import '../entities/admin_posyandu.dart';
import '../entities/admin_schedule.dart';

abstract class AdminRepository {
  Future<List<AdminAccount>> accounts();
  Future<List<AdminPosyandu>> posyandu();
  Future<List<AdminSchedule>> schedules();
  Future<AdminSession?> activeSession();
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
  Future<AdminSchedule> saveSchedule({
    int? id,
    required int posyanduId,
    required String date,
    required String startTime,
    required String endTime,
    required String location,
    required String note,
  });
  Future<AdminSession> startSession({
    int? scheduleId,
    required int posyanduId,
    required String date,
  });
  Future<AdminSession> closeSession(int id);
  Future<Uint8List> downloadReport(
    String type, {
    String? startDate,
    String? endDate,
  });
}
