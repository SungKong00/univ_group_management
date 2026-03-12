import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/usecases/create_post_usecase.dart';
import '../../domain/usecases/delete_post_usecase.dart';
import '../../domain/usecases/get_post_usecase.dart';
import '../../domain/usecases/get_posts_usecase.dart';
import '../../domain/usecases/update_post_usecase.dart';
import 'post_repository_provider.dart';

/// GetPostsUseCase Provider
///
/// 게시글 목록 조회 UseCase
final getPostsUseCaseProvider = Provider<GetPostsUseCase>((ref) {
  final repository = ref.watch(postRepositoryProvider);
  return GetPostsUseCase(repository);
});

/// GetPostUseCase Provider
///
/// 단일 게시글 조회 UseCase
final getPostUseCaseProvider = Provider<GetPostUseCase>((ref) {
  final repository = ref.watch(postRepositoryProvider);
  return GetPostUseCase(repository);
});

/// CreatePostUseCase Provider
///
/// 게시글 생성 UseCase
final createPostUseCaseProvider = Provider<CreatePostUseCase>((ref) {
  final repository = ref.watch(postRepositoryProvider);
  return CreatePostUseCase(repository);
});

/// UpdatePostUseCase Provider
///
/// 게시글 수정 UseCase
final updatePostUseCaseProvider = Provider<UpdatePostUseCase>((ref) {
  final repository = ref.watch(postRepositoryProvider);
  return UpdatePostUseCase(repository);
});

/// DeletePostUseCase Provider
///
/// 게시글 삭제 UseCase
final deletePostUseCaseProvider = Provider<DeletePostUseCase>((ref) {
  final repository = ref.watch(postRepositoryProvider);
  return DeletePostUseCase(repository);
});
