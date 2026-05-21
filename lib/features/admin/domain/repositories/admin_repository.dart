import '../entities/admin_account.dart';
import '../entities/admin_posyandu.dart';

abstract class AdminRepository {
  Future<List<AdminAccount>> accounts();
  Future<List<AdminPosyandu>> posyandu();
}
