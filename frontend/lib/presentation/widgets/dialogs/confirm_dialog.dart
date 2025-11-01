import 'package:flutter/material.dart';
import '../buttons/error_button.dart';
import '../buttons/neutral_outlined_button.dart';
import '../buttons/primary_button.dart';

/// 확인 다이얼로그 (공통 컴포넌트)
///
/// 사용자에게 확인을 요청하는 범용 다이얼로그
/// - 일반 확인: PrimaryButton
/// - 삭제 확인: ErrorButton (isDestructive: true)
/// - 취소 버튼 라벨 커스터마이징 가능
class ConfirmDialog extends StatelessWidget {
  const ConfirmDialog({
    required this.title,
    required this.message,
    required this.confirmLabel,
    this.cancelLabel,
    this.isDestructive = false,
    this.confirmVariant = PrimaryButtonVariant.action,
    super.key,
  });

  /// 다이얼로그 제목
  final String title;

  /// 확인 메시지
  final String message;

  /// 확인 버튼 라벨
  final String confirmLabel;

  /// 취소 버튼 라벨 (기본값: "취소")
  final String? cancelLabel;

  /// 위험한 작업 여부 (true: ErrorButton, false: PrimaryButton)
  final bool isDestructive;

  /// PrimaryButton 변형 (isDestructive가 false일 때만 적용)
  final PrimaryButtonVariant confirmVariant;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        NeutralOutlinedButton(
          text: cancelLabel ?? '취소',
          onPressed: () => Navigator.of(context).pop(false),
        ),
        if (isDestructive)
          ErrorButton(
            text: confirmLabel,
            onPressed: () => Navigator.of(context).pop(true),
          )
        else
          PrimaryButton(
            text: confirmLabel,
            onPressed: () => Navigator.of(context).pop(true),
            variant: confirmVariant,
          ),
      ],
    );
  }
}

/// 확인 다이얼로그 헬퍼 함수
///
/// 확인/취소 다이얼로그를 표시하고 결과를 반환
///
/// Returns:
/// - true: 확인 버튼 클릭
/// - false: 취소 버튼 클릭 또는 다이얼로그 닫기
///
/// Example:
/// ```dart
/// // 일반 확인
/// final confirmed = await showConfirmDialog(
///   context,
///   title: '시간 겹침 확인',
///   message: '⚠️ 해당 시간대에 다른 일정이 있습니다. 계속 진행하시겠습니까?',
///   confirmLabel: '계속 진행',
///   cancelLabel: '아니요',
/// );
///
/// // 삭제 확인 (위험)
/// final confirmed = await showConfirmDialog(
///   context,
///   title: '일정 삭제',
///   message: '정말 "$title" 일정을 삭제하시겠습니까?',
///   confirmLabel: '삭제',
///   isDestructive: true,
/// );
/// ```
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = '확인',
  String? cancelLabel,
  bool isDestructive = false,
  PrimaryButtonVariant confirmVariant = PrimaryButtonVariant.action,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => ConfirmDialog(
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      isDestructive: isDestructive,
      confirmVariant: confirmVariant,
    ),
  );
  return result ?? false;
}
