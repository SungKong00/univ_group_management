import 'package:get_it/get_it.dart';
import '../core/network/dio_client.dart';
import '../core/storage/token_storage.dart';
import '../data/services/auth_service.dart';
import '../data/repositories/auth_repository_impl.dart';
import '../domain/repositories/auth_repository.dart';
import '../presentation/providers/auth_provider.dart';

final GetIt getIt = GetIt.instance;

Future<void> setupDependencyInjection() async {
  // Core
  getIt.registerLazySingleton<DioClient>(() => DioClient());
  getIt.registerLazySingleton<TokenStorage>(() => SecureTokenStorage());

  // Services
  getIt.registerLazySingleton<AuthService>(
    () => AuthService(getIt<DioClient>()),
  );

  // Repositories
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      getIt<AuthService>(),
      getIt<TokenStorage>(),
    ),
  );

  // Providers
  getIt.registerFactory<AuthProvider>(
    () => AuthProvider(getIt<AuthRepository>()),
  );
}