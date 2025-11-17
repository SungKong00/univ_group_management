import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/datasources/post_remote_datasource.dart';
import '../../data/repositories/post_repository_impl.dart';
import '../../domain/repositories/post_repository.dart';

/// DioClient Provider
///
/// 기존 core/network/dio_client.dart 재사용
final dioClientProvider = Provider<DioClient>((ref) {
  return DioClient();
});

/// PostRemoteDataSource Provider
///
/// Dio 클라이언트를 주입받아 DataSource 생성
final postRemoteDataSourceProvider = Provider<PostRemoteDataSource>((ref) {
  final dio = ref.watch(dioClientProvider);
  return PostRemoteDataSource(dio);
});

/// PostRepository Provider
///
/// DataSource를 주입받아 Repository 구현체 생성
final postRepositoryProvider = Provider<PostRepository>((ref) {
  final dataSource = ref.watch(postRemoteDataSourceProvider);
  return PostRepositoryImpl(dataSource);
});
