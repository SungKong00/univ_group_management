import 'package:flutter/material.dart';
import 'app_chip.dart';

/// InputChip - 사용자 입력 결과를 칩으로 표시
///
/// **용도**: 검색 태그, 필터 선택 결과, 입력된 항목 표시
///
/// **특징**:
/// - 삭제 버튼(× icon) 필수
/// - onDeleted 콜백 필수
/// - 선행 아이콘 지원
/// - 호버/활성 상태 시각화
/// - 한줄 텍스트만 표시 (overflow 처리)
///
/// **사용 예시**:
/// ```dart
/// // 검색 태그
/// InputChip(
///   label: '검색어: Flutter',
///   onDeleted: () => removeSearchTag(),
/// )
///
/// // 필터 선택 결과
/// InputChip(
///   label: '역할: 멤버',
///   leadingIcon: Icons.person,
///   onDeleted: () => removeRoleFilter(),
/// )
/// ```
class AppInputChip extends StatelessWidget {
  /// 칩에 표시될 텍스트 (필수)
  final String label;

  /// 삭제 콜백 (필수)
  final VoidCallback onDeleted;

  /// 선행 아이콘 (선택사항)
  final IconData? leadingIcon;

  /// 색상 변형
  final AppChipVariant variant;

  /// 크기 변형
  final AppChipSize size;

  const AppInputChip({
    super.key,
    required this.label,
    required this.onDeleted,
    this.leadingIcon,
    this.variant = AppChipVariant.defaultVariant,
    this.size = AppChipSize.medium,
  });

  @override
  Widget build(BuildContext context) {
    return AppChip(
      label: label,
      leadingIcon: leadingIcon,
      onDeleted: onDeleted,
      variant: variant,
      size: size,
      enabled: true,
    );
  }
}
