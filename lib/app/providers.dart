import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/api_client.dart';
import '../core/notifications/fcm_registration_service.dart';
import '../core/token_store.dart';
import '../features/auth/data/datasources/auth_remote_data_source.dart';
import '../features/auth/data/repositories/auth_repository_impl.dart';
import '../features/auth/domain/repositories/auth_repository.dart';
import '../features/auth/domain/usecases/login.dart';
import '../features/auth/domain/usecases/logout.dart';
import '../features/auth/domain/usecases/restore_session.dart';
import '../features/admin/data/datasources/admin_remote_data_source.dart';
import '../features/admin/data/repositories/admin_repository_impl.dart';
import '../features/admin/domain/repositories/admin_repository.dart';
import '../features/bidan/data/datasources/bidan_remote_data_source.dart';
import '../features/bidan/data/repositories/bidan_repository_impl.dart';
import '../features/bidan/domain/repositories/bidan_repository.dart';
import '../features/bidan/domain/usecases/distribute_pmt.dart';
import '../features/bidan/domain/usecases/download_report.dart';
import '../features/bidan/domain/usecases/get_bidan_dashboard.dart';
import '../features/bidan/domain/usecases/validate_referral.dart';
import '../features/kader/data/datasources/kader_remote_data_source.dart';
import '../features/kader/data/repositories/kader_repository_impl.dart';
import '../features/kader/domain/repositories/kader_repository.dart';
import '../features/kader/domain/usecases/create_balita.dart';
import '../features/kader/domain/usecases/get_kader_dashboard.dart';
import '../features/kader/domain/usecases/retry_prediction.dart';
import '../features/kader/domain/usecases/save_measurement.dart';
import '../features/kader/domain/usecases/search_balita.dart';

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

final tokenStoreProvider = Provider<TokenStore>(
  (ref) => SharedPreferencesTokenStore(),
);

final fcmRegistrationServiceProvider = Provider<FcmRegistrationService>(
  (ref) => FcmRegistrationService(ref.watch(apiClientProvider)),
);

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>(
  (ref) => AuthRemoteDataSource(ref.watch(apiClientProvider)),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(
    remoteDataSource: ref.watch(authRemoteDataSourceProvider),
    tokenStore: ref.watch(tokenStoreProvider),
    apiClient: ref.watch(apiClientProvider),
  ),
);

final loginUseCaseProvider = Provider<Login>(
  (ref) => Login(ref.watch(authRepositoryProvider)),
);

final logoutUseCaseProvider = Provider<Logout>(
  (ref) => Logout(ref.watch(authRepositoryProvider)),
);

final restoreSessionUseCaseProvider = Provider<RestoreSession>(
  (ref) => RestoreSession(ref.watch(authRepositoryProvider)),
);

final adminRemoteDataSourceProvider = Provider<AdminRemoteDataSource>(
  (ref) => AdminRemoteDataSource(ref.watch(apiClientProvider)),
);

final adminRepositoryProvider = Provider<AdminRepository>(
  (ref) => AdminRepositoryImpl(ref.watch(adminRemoteDataSourceProvider)),
);

final kaderRemoteDataSourceProvider = Provider<KaderRemoteDataSource>(
  (ref) => KaderRemoteDataSource(ref.watch(apiClientProvider)),
);

final kaderRepositoryProvider = Provider<KaderRepository>(
  (ref) => KaderRepositoryImpl(ref.watch(kaderRemoteDataSourceProvider)),
);

final getKaderDashboardProvider = Provider<GetKaderDashboard>(
  (ref) => GetKaderDashboard(ref.watch(kaderRepositoryProvider)),
);

final searchBalitaProvider = Provider<SearchBalita>(
  (ref) => SearchBalita(ref.watch(kaderRepositoryProvider)),
);

final createBalitaProvider = Provider<CreateBalita>(
  (ref) => CreateBalita(ref.watch(kaderRepositoryProvider)),
);

final saveMeasurementProvider = Provider<SaveMeasurement>(
  (ref) => SaveMeasurement(ref.watch(kaderRepositoryProvider)),
);

final retryPredictionProvider = Provider<RetryPrediction>(
  (ref) => RetryPrediction(ref.watch(kaderRepositoryProvider)),
);

final bidanRemoteDataSourceProvider = Provider<BidanRemoteDataSource>(
  (ref) => BidanRemoteDataSource(ref.watch(apiClientProvider)),
);

final bidanRepositoryProvider = Provider<BidanRepository>(
  (ref) => BidanRepositoryImpl(ref.watch(bidanRemoteDataSourceProvider)),
);

final getBidanDashboardProvider = Provider<GetBidanDashboard>(
  (ref) => GetBidanDashboard(ref.watch(bidanRepositoryProvider)),
);

final validateReferralProvider = Provider<ValidateReferral>(
  (ref) => ValidateReferral(ref.watch(bidanRepositoryProvider)),
);

final distributePmtProvider = Provider<DistributePmt>(
  (ref) => DistributePmt(ref.watch(bidanRepositoryProvider)),
);

final downloadReportProvider = Provider<DownloadReport>(
  (ref) => DownloadReport(ref.watch(bidanRepositoryProvider)),
);
