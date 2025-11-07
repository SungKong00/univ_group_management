import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';
import '../../../core/theme/app_colors.dart';
import '../atoms/selectable_option_card.dart';
import '../molecules/step_header.dart';
import '../molecules/option_card_group.dart';

/// Selectable Option Data Class
///
/// 제네릭 타입 T를 지원하는 선택 가능한 옵션 데이터 모델.
///
/// **사용 예시:**
/// ```dart
/// SelectableOption<EventType>(
///   value: EventType.official,
///   title: '공식 일정',
///   description: '그룹 전체 공지',
///   icon: Icons.event,
/// )
/// ```
class SelectableOption<T> {
  /// 옵션의 실제 값 (제네릭 타입)
  final T value;

  /// 옵션 제목 (짧고 명확한 표현)
  final String title;

  /// 옵션 설명 (친근한 안내 문구)
  final String description;

  /// 옵션 아이콘
  final IconData icon;

  /// 아이콘 색상 (기본값: AppColors.brand)
  final Color? iconColor;

  const SelectableOption({
    required this.value,
    required this.title,
    required this.description,
    required this.icon,
    this.iconColor,
  });
}

/// Single Step Selector Widget
///
/// 단일 선택 다이얼로그를 표시하는 제네릭 위젯.
/// showDialog()를 통해 Material Dialog로 렌더링됩니다.
///
/// **구성 요소:**
/// - StepHeader: 제목 + 뒤로가기 버튼
/// - OptionCardGroup: 카드 리스트 레이아웃
/// - SelectableOptionCard: 각 옵션별 카드
///
/// **사용 예시:**
/// ```dart
/// await showSingleStepSelector<EventType>(
///   context: context,
///   title: '일정 유형 선택',
///   subtitle: '생성할 일정의 종류를 선택해주세요',
///   options: [
///     SelectableOption(
///       value: EventType.official,
///       title: '공식 일정',
///       description: '그룹 전체 공지',
///       icon: Icons.event,
///     ),
///     SelectableOption(
///       value: EventType.unofficial,
///       title: '비공식 일정',
///       description: '개인 메모',
///       icon: Icons.event_note,
///     ),
///   ],
/// );
/// ```
class SingleStepSelector<T> extends StatefulWidget {
  /// 단계 제목
  final String title;

  /// 단계 부제목 (선택적)
  final String? subtitle;

  /// 선택 가능한 옵션 리스트
  final List<SelectableOption<T>> options;

  /// 선택 완료 콜백 (선택된 값 반환)
  final ValueChanged<T> onSelected;

  /// 뒤로가기 콜백 (선택적)
  final VoidCallback? onBack;

  /// 카드 레이아웃 방향 (기본값: 수직)
  final Axis? direction;

  /// 강조 색상 (기본값: AppColors.brand)
  final Color? accentColor;

  const SingleStepSelector({
    super.key,
    required this.title,
    this.subtitle,
    required this.options,
    required this.onSelected,
    this.onBack,
    this.direction = Axis.vertical,
    this.accentColor,
  });

  @override
  State<SingleStepSelector<T>> createState() => _SingleStepSelectorState<T>();
}

class _SingleStepSelectorState<T> extends State<SingleStepSelector<T>> {
  /// 현재 선택된 옵션의 인덱스 (null = 선택 안 됨)
  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 600, // 데스크톱 대응
          maxHeight: 800,
        ),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 헤더
            StepHeader(
              title: widget.title,
              subtitle: widget.subtitle,
              onBack: widget.onBack ?? () => Navigator.of(context).pop(),
            ),
            const SizedBox(height: AppSpacing.lg),
            // 옵션 카드 그룹
            Flexible(
              child: SingleChildScrollView(
                child: OptionCardGroup(
                  direction: widget.direction,
                  spacing: AppSpacing.md,
                  children: List.generate(
                    widget.options.length,
                    (index) => _buildOptionCard(index),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 옵션 카드 생성
  Widget _buildOptionCard(int index) {
    final option = widget.options[index];
    final isSelected = _selectedIndex == index;

    return SelectableOptionCard(
      title: option.title,
      description: option.description,
      icon: Icon(
        option.icon,
        size: 32,
        color: option.iconColor ?? widget.accentColor ?? AppColors.brand,
      ),
      isSelected: isSelected,
      onTap: () => _handleSelection(index),
      accentColor: widget.accentColor,
    );
  }

  /// 선택 처리 및 다이얼로그 닫기
  void _handleSelection(int index) {
    setState(() {
      _selectedIndex = index;
    });

    // 선택 완료 후 약간의 딜레이를 두고 다이얼로그 닫기
    // (사용자가 선택 상태를 시각적으로 확인할 수 있도록)
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        final selectedValue = widget.options[index].value;
        Navigator.of(context).pop(); // 다이얼로그 닫기
        widget.onSelected(selectedValue); // 콜백 호출
      }
    });
  }
}

/// Helper Function: showSingleStepSelector
///
/// SingleStepSelector를 Material Dialog로 표시하는 헬퍼 함수.
///
/// **사용 예시:**
/// ```dart
/// final result = await showSingleStepSelector<EventType>(
///   context: context,
///   title: '일정 유형 선택',
///   options: eventTypeOptions,
/// );
/// if (result != null) {
///   print('선택된 값: $result');
/// }
/// ```
Future<T?> showSingleStepSelector<T>({
  required BuildContext context,
  required String title,
  String? subtitle,
  required List<SelectableOption<T>> options,
  VoidCallback? onBack,
  Axis? direction = Axis.vertical,
  Color? accentColor,
}) async {
  T? selectedValue;

  await showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (context) => SingleStepSelector<T>(
      title: title,
      subtitle: subtitle,
      options: options,
      onSelected: (value) {
        selectedValue = value;
      },
      onBack: onBack,
      direction: direction,
      accentColor: accentColor,
    ),
  );

  return selectedValue;
}
