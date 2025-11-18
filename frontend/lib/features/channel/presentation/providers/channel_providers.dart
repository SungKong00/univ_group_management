import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/repositories/repository_providers.dart';
import '../../../../features/post/presentation/providers/post_repository_provider.dart'
    hide dioClientProvider;
import '../../data/datasources/channel_remote_data_source.dart';
import '../../data/datasources/read_position_local_data_source.dart';
import '../../data/repositories/channel_repository_impl.dart';
import '../../data/repositories/read_position_repository_impl.dart';
import '../../domain/repositories/channel_repository.dart';
import '../../domain/repositories/read_position_repository.dart';
import '../../domain/usecases/get_channel_list_usecase.dart';
import '../../domain/usecases/enter_channel_usecase.dart';
import '../../domain/usecases/calculate_unread_position_usecase.dart';

/// Channel Remote DataSource Provider
///
/// Provides HTTP API client for channel operations.
/// Depends on DioClient from core layer.
final channelRemoteDataSourceProvider = Provider<ChannelRemoteDataSource>((
  ref,
) {
  final dioClient = ref.watch(dioClientProvider);
  return ChannelRemoteDataSourceImpl(dioClient);
});

/// Read Position Local DataSource Provider
///
/// Provides in-memory storage for read positions.
/// Session-scoped, will be reset on app restart.
final readPositionLocalDataSourceProvider =
    Provider<ReadPositionLocalDataSource>((ref) {
  return ReadPositionLocalDataSourceImpl();
});

/// Channel Repository Provider
///
/// Provides channel data access implementation.
/// Bridges domain layer with data layer.
final channelRepositoryProvider = Provider<ChannelRepository>((ref) {
  final dataSource = ref.watch(channelRemoteDataSourceProvider);
  return ChannelRepositoryImpl(dataSource);
});

/// Read Position Repository Provider
///
/// Provides read position storage implementation.
/// Uses in-memory data source for session state.
final readPositionRepositoryProvider = Provider<ReadPositionRepository>((ref) {
  final dataSource = ref.watch(readPositionLocalDataSourceProvider);
  return ReadPositionRepositoryImpl(dataSource);
});

/// Get Channel List UseCase Provider
///
/// Provides business logic for fetching channel list.
/// Depends on ChannelRepository.
final getChannelListUseCaseProvider = Provider<GetChannelListUseCase>((ref) {
  final repository = ref.watch(channelRepositoryProvider);
  return GetChannelListUseCase(repository);
});

/// Enter Channel UseCase Provider
///
/// Provides business logic for entering a channel.
/// Loads permissions and posts in parallel to avoid Race Condition.
/// Depends on ChannelRepository, ReadPositionRepository, and PostRepository.
final enterChannelUseCaseProvider = Provider<EnterChannelUseCase>((ref) {
  final channelRepo = ref.watch(channelRepositoryProvider);
  final readPosRepo = ref.watch(readPositionRepositoryProvider);
  final postRepo = ref.watch(postRepositoryProvider);
  return EnterChannelUseCase(channelRepo, readPosRepo, postRepo);
});

/// Calculate Unread Position UseCase Provider
///
/// Provides business logic for calculating unread position.
/// Pure function with no repository dependencies.
final calculateUnreadPositionUseCaseProvider =
    Provider<CalculateUnreadPositionUseCase>((ref) {
      return CalculateUnreadPositionUseCase();
    });
