import 'package:flutter/material.dart';

/// 커맨드 팔레트용 커맨드 정의
///
/// 빠른 검색 및 명령 실행을 위한 데이터 모델입니다.
class AppCommand {
  /// 커맨드 ID (고유 식별자)
  final String id;

  /// 표시 라벨
  final String label;

  /// 설명 (선택 사항)
  final String? description;

  /// 아이콘 (선택 사항)
  final IconData? icon;

  /// 단축키 문자열 (선택 사항, 예: '⌘N', 'Ctrl+S')
  final String? shortcut;

  /// 카테고리/그룹 (선택 사항, 예: '파일', '편집', '보기')
  final String? category;

  /// 실행 콜백
  final VoidCallback? onExecute;

  const AppCommand({
    required this.id,
    required this.label,
    this.description,
    this.icon,
    this.shortcut,
    this.category,
    this.onExecute,
  });

  @override
  String toString() =>
      'AppCommand(id: $id, label: $label, category: $category)';
}
