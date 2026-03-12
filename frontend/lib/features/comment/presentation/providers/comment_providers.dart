import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/repositories/repository_providers.dart';
import '../../data/datasources/comment_remote_data_source.dart';
import '../../data/repositories/comment_repository_impl.dart';
import '../../domain/repositories/comment_repository.dart';
import '../../domain/usecases/get_comments_usecase.dart';
import '../../domain/usecases/create_comment_usecase.dart';
import '../../domain/usecases/delete_comment_usecase.dart';

/// Comment Remote DataSource Provider
///
/// Provides HTTP API client for comment operations.
/// Depends on DioClient from core layer.
final commentRemoteDataSourceProvider = Provider<CommentRemoteDataSource>((
  ref,
) {
  final dioClient = ref.watch(dioClientProvider);
  return CommentRemoteDataSourceImpl(dioClient);
});

/// Comment Repository Provider
///
/// Provides comment data access implementation.
/// Bridges domain layer with data layer.
final commentRepositoryProvider = Provider<CommentRepository>((ref) {
  final dataSource = ref.watch(commentRemoteDataSourceProvider);
  return CommentRepositoryImpl(dataSource);
});

/// Get Comments UseCase Provider
///
/// Provides business logic for fetching comments for a post.
/// Depends on CommentRepository.
final getCommentsUseCaseProvider = Provider<GetCommentsUseCase>((ref) {
  final repository = ref.watch(commentRepositoryProvider);
  return GetCommentsUseCase(repository);
});

/// Create Comment UseCase Provider
///
/// Provides business logic for creating a new comment.
/// Validates input and delegates to CommentRepository.
final createCommentUseCaseProvider = Provider<CreateCommentUseCase>((ref) {
  final repository = ref.watch(commentRepositoryProvider);
  return CreateCommentUseCase(repository);
});

/// Delete Comment UseCase Provider
///
/// Provides business logic for deleting a comment.
/// Validates input and delegates to CommentRepository.
final deleteCommentUseCaseProvider = Provider<DeleteCommentUseCase>((ref) {
  final repository = ref.watch(commentRepositoryProvider);
  return DeleteCommentUseCase(repository);
});
