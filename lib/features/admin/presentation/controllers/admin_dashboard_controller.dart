import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers.dart';
import '../../../../core/network/api_exception.dart';
import '../../domain/entities/admin_account.dart';
import '../../domain/entities/admin_posyandu.dart';

class AdminDashboardState {
  const AdminDashboardState({
    this.accounts = const [],
    this.posyandu = const [],
    this.isLoading = true,
    this.message,
    this.isError = false,
  });

  final List<AdminAccount> accounts;
  final List<AdminPosyandu> posyandu;
  final bool isLoading;
  final String? message;
  final bool isError;
}

class AdminDashboardController extends Notifier<AdminDashboardState> {
  @override
  AdminDashboardState build() {
    Future.microtask(load);
    return const AdminDashboardState();
  }

  Future<void> load() async {
    try {
      final repository = ref.read(adminRepositoryProvider);
      final accounts = await repository.accounts();
      final posyandu = await repository.posyandu();
      state = AdminDashboardState(
        accounts: accounts,
        posyandu: posyandu,
        isLoading: false,
      );
    } catch (error) {
      state = AdminDashboardState(
        isLoading: false,
        message: error is ApiException
            ? error.message
            : 'Data admin belum bisa dimuat.',
        isError: true,
      );
    }
  }
}

final adminDashboardControllerProvider =
    NotifierProvider<AdminDashboardController, AdminDashboardState>(
      AdminDashboardController.new,
    );
