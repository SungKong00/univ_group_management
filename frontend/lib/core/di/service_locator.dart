import 'package:get_it/get_it.dart';
import '../storage/token_storage.dart';
import '../network/dio_client.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/group_service.dart';
import '../../data/services/workspace_service.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/repositories/group_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/group_repository.dart';
import '../../presentation/providers/group_tree_provider.dart';
import '../../presentation/providers/group_membership_provider.dart';
import '../../presentation/providers/group_subgroups_provider.dart';

final GetIt locator = GetIt.instance;

Future<void> setupServiceLocator() async {
  // Core services
  locator.registerLazySingleton<TokenStorage>(() => SharedPrefsTokenStorage());
  locator.registerLazySingleton<DioClient>(() => DioClient(locator<TokenStorage>()));

  // API services
  locator.registerLazySingleton<AuthService>(() => AuthService(locator<DioClient>()));
  locator.registerLazySingleton<GroupService>(() => GroupService(locator<DioClient>()));
  locator.registerLazySingleton<WorkspaceService>(() => WorkspaceService(locator<DioClient>()));

  // Repositories
  locator.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(
    locator<AuthService>(),
    locator<TokenStorage>(),
  ));
  locator.registerLazySingleton<GroupRepository>(() => GroupRepositoryImpl(locator<DioClient>()));

  // Group-related providers
  locator.registerLazySingleton<GroupTreeProvider>(() => GroupTreeProvider(locator<GroupRepository>()));
  locator.registerLazySingleton<GroupMembershipProvider>(() => GroupMembershipProvider(locator<GroupRepository>()));
  locator.registerLazySingleton<GroupSubgroupsProvider>(() => GroupSubgroupsProvider(locator<GroupRepository>()));
}