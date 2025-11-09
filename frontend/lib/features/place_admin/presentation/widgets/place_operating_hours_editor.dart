import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/place_time_models.dart';
import '../../../../core/providers/place_time_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/utils/snack_bar_helper.dart';
import '../../../../presentation/widgets/buttons/primary_button.dart';
import '../../../../presentation/widgets/buttons/neutral_outlined_button.dart';

/// 장소 운영시간 에디터 (카드 + Range Slider 방식)
///
/// 7개의 요일별 카드로 구성되며, 각 카드는:
/// - 토글 스위치 (on/off로 휴무 설정)
/// - Range Slider (시작/종료 시간 드래그 조정)
/// - 브레이크 타임 섹션 (접기/펼치기 가능)
class PlaceOperatingHoursEditor extends ConsumerStatefulWidget {
  final int placeId;
  final List<OperatingHoursResponse> initialOperatingHours;
  final Future<bool> Function(List<OperatingHoursItem> operatingHours) onSaveOperatingHours;
  final VoidCallback? onSaveCompleted;
  final VoidCallback? onCancel;

  const PlaceOperatingHoursEditor({
    super.key,
    required this.placeId,
    required this.initialOperatingHours,
    required this.onSaveOperatingHours,
    this.onSaveCompleted,
    this.onCancel,
  });

  @override
  ConsumerState<PlaceOperatingHoursEditor> createState() => _PlaceOperatingHoursEditorState();
}

class _PlaceOperatingHoursEditorState extends ConsumerState<PlaceOperatingHoursEditor> {
  // 요일별 운영 상태 (true = 운영, false = 휴무)
  final Map<int, bool> _isOperating = {};

  // 요일별 시간 범위 (슬롯 단위: 0-96, 15분 단위)
  final Map<int, RangeValues> _timeRanges = {};

  // 요일별 수정 상태 추적 (보라색 강조 표시용)
  final Map<int, bool> _modifiedDays = {};

  // 요일별 브레이크 타임 접기/펼치기 상태 (삭제됨 - 항상 표시)
  // final Map<int, bool> _breakTimeExpanded = {};

  // 브레이크 타임별 Range 값 (id → RangeValues)
  final Map<int, RangeValues> _breakTimeRanges = {};

  // 브레이크 타임 변경사항 추적
  final Map<int, List<RestrictedTimeChange>> _pendingBreakTimeChanges = {};

  bool _isDirty = false;
  bool _isSaving = false;

  // 초기 데이터 (롤백용)
  late Map<int, bool> _initialIsOperating;
  late Map<int, RangeValues> _initialTimeRanges;

  // 슬롯 단위 (15분 = 1슬롯, 96슬롯 = 24시간)
  static const int _slotsPerHour = 4; // 15분 단위
  static const int _totalSlots = 96; // 24시간 * 4

  @override
  void initState() {
    super.initState();
    _parseInitialData();
  }

  /// 서버 데이터 파싱
  void _parseInitialData() {
    // 7일 초기화 (기본값: 휴무)
    for (int day = 0; day < 7; day++) {
      _isOperating[day] = false;
      _timeRanges[day] = const RangeValues(36, 72); // 기본 09:00-18:00
      _modifiedDays[day] = false; // 초기 상태는 수정되지 않음
    }

    // 운영시간 파싱
    for (final oh in widget.initialOperatingHours) {
      final day = _dayOfWeekToIndex(oh.dayOfWeek);
      if (day == -1) continue;

      if (!oh.isClosed && oh.startTime != null && oh.endTime != null) {
        _isOperating[day] = true;
        final startSlot = _timeStringToSlot(oh.startTime!);
        final endSlot = _timeStringToSlot(oh.endTime!);
        _timeRanges[day] = RangeValues(startSlot.toDouble(), endSlot.toDouble());
      }
    }

    // 초기 데이터 백업
    _initialIsOperating = Map.from(_isOperating);
    _initialTimeRanges = Map.from(_timeRanges);
  }

  /// 요일 문자열을 인덱스로 변환
  int _dayOfWeekToIndex(String dayOfWeek) {
    const dayMap = {
      'MONDAY': 0,
      'TUESDAY': 1,
      'WEDNESDAY': 2,
      'THURSDAY': 3,
      'FRIDAY': 4,
      'SATURDAY': 5,
      'SUNDAY': 6,
    };
    return dayMap[dayOfWeek] ?? -1;
  }

  /// 인덱스를 요일 문자열로 변환
  String _indexToDayOfWeek(int index) {
    const days = ['MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY', 'SATURDAY', 'SUNDAY'];
    return days[index];
  }

  /// 인덱스를 한글 요일로 변환
  String _indexToDayOfWeekKorean(int index) {
    const days = ['월요일', '화요일', '수요일', '목요일', '금요일', '토요일', '일요일'];
    return days[index];
  }

  /// "HH:mm" 형식을 슬롯으로 변환
  int _timeStringToSlot(String time) {
    final parts = time.split(':');
    if (parts.length != 2) return 0;
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;
    final slot = hour * _slotsPerHour + (minute ~/ 15);
    return slot.clamp(0, 95); // 슬롯 범위 제한 (0-95)
  }

  /// 슬롯을 "HH:mm" 형식으로 변환
  String _slotToTimeString(int slot) {
    final hour = slot ~/ _slotsPerHour;
    final minute = (slot % _slotsPerHour) * 15;
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  /// 충돌 경고 다이얼로그 표시
  Future<bool> _showConflictWarningDialog(
    String dayLabel,
    List<RestrictedTimeResponse> conflicts,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.warning, color: AppColors.warning, size: 24),
            const SizedBox(width: 8),
            Text('운영시간 변경 확인', style: AppTheme.headlineSmall),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$dayLabel의 운영시간 변경으로 다음 브레이크 타임이 삭제됩니다:',
              style: AppTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            ...conflicts.map((c) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(Icons.access_time, color: AppColors.neutral600, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${c.reason ?? '브레이크 타임'}: ${c.startTime} - ${c.endTime}',
                      style: AppTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
        actions: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: NeutralOutlinedButton(
                  text: '취소',
                  onPressed: () => Navigator.pop(context, false),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: PrimaryButton(
                  text: '삭제하고 저장',
                  variant: PrimaryButtonVariant.error,
                  onPressed: () => Navigator.pop(context, true),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    return result ?? false;
  }

  /// 저장 처리
  Future<void> _handleSave() async {
    if (!_isDirty) {
      AppSnackBar.info(context, '변경사항이 없습니다');
      return;
    }

    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      // 1. 모든 브레이크 타임 가져오기 (동기 접근)
      final restrictedTimesAsync = ref.read(restrictedTimesProvider(widget.placeId));
      final allRestrictedTimes = restrictedTimesAsync.asData?.value ?? [];

      // 2. 각 요일별로 충돌 검증
      final allConflicts = <int, List<RestrictedTimeResponse>>{};

      for (int dayIndex = 0; dayIndex < 7; dayIndex++) {
        final dayOfWeek = _indexToDayOfWeek(dayIndex);
        final conflicts = _findConflictingBreakTimes(
          dayIndex,
          dayOfWeek,
          allRestrictedTimes,
        );

        if (conflicts.isNotEmpty) {
          allConflicts[dayIndex] = conflicts;
        }
      }

      // 3. 충돌이 있으면 경고 다이얼로그 표시
      if (allConflicts.isNotEmpty) {
        // 충돌이 있는 요일별로 다이얼로그 표시
        for (final entry in allConflicts.entries) {
          final dayIndex = entry.key;
          final conflicts = entry.value;
          final dayLabel = _indexToDayOfWeekKorean(dayIndex);

          final confirmed = await _showConflictWarningDialog(dayLabel, conflicts);

          if (!confirmed) {
            // 취소 선택 시 저장 중단
            setState(() {
              _isSaving = false;
            });
            return;
          }
        }

        // 4. 충돌하는 브레이크 타임 삭제
        int deletedCount = 0;
        for (final conflicts in allConflicts.values) {
          for (final conflict in conflicts) {
            try {
              final params = DeleteRestrictedTimeParams(
                placeId: widget.placeId,
                restrictedTimeId: conflict.id,
              );
              await ref.read(deleteRestrictedTimeProvider(params).future);
              deletedCount++;
            } catch (e) {
              debugPrint('브레이크 타임 삭제 실패: $e');
            }
          }
        }

        if (mounted && deletedCount > 0) {
          AppSnackBar.info(
            context,
            '운영시간 변경으로 브레이크 타임 $deletedCount개가 삭제되었습니다',
          );
        }
      }

      // 5. 운영시간 저장 (기존 로직)
      final operatingHoursItems = _buildOperatingHoursItems();
      final saveSuccess = await widget.onSaveOperatingHours(operatingHoursItems);

      if (!saveSuccess) {
        if (!mounted) return;
        AppSnackBar.error(context, '운영시간 저장 실패');
        _rollback();
        return;
      }

      // 6. 브레이크 타임 변경사항 저장 (신규)
      int breakTimeChangeCount = 0;

      for (final entry in _pendingBreakTimeChanges.entries) {
        for (final change in entry.value) {
          try {
            switch (change.type) {
              case BreakTimeChangeType.add:
                final params = AddRestrictedTimeParams(
                  placeId: widget.placeId,
                  request: AddRestrictedTimeRequest(
                    dayOfWeek: change.dayOfWeek,
                    startTime: change.startTime,
                    endTime: change.endTime,
                    reason: change.reason,
                  ),
                );
                await ref.read(addRestrictedTimeProvider(params).future);
                breakTimeChangeCount++;
                break;

              case BreakTimeChangeType.update:
                if (change.id != null) {
                  final params = UpdateRestrictedTimeParams(
                    placeId: widget.placeId,
                    restrictedTimeId: change.id!,
                    request: AddRestrictedTimeRequest(
                      dayOfWeek: change.dayOfWeek,
                      startTime: change.startTime,
                      endTime: change.endTime,
                      reason: change.reason,
                    ),
                  );
                  await ref.read(updateRestrictedTimeProvider(params).future);
                  breakTimeChangeCount++;
                }
                break;

              case BreakTimeChangeType.delete:
                if (change.id != null) {
                  final params = DeleteRestrictedTimeParams(
                    placeId: widget.placeId,
                    restrictedTimeId: change.id!,
                  );
                  await ref.read(deleteRestrictedTimeProvider(params).future);
                  breakTimeChangeCount++;
                }
                break;
            }
          } catch (e) {
            debugPrint('브레이크 타임 저장 실패: $e');
            // 부분 저장 허용 - 에러 로그만 출력하고 계속 진행
          }
        }
      }

      // 7. 상태 초기화
      if (!mounted) return;
      setState(() {
        _isDirty = false;
        _modifiedDays.clear();
        _pendingBreakTimeChanges.clear();
        _breakTimeRanges.clear();
        _initialIsOperating = Map.from(_isOperating);
        _initialTimeRanges = Map.from(_timeRanges);
      });

      // 8. 성공 피드백
      if (breakTimeChangeCount > 0) {
        AppSnackBar.success(
          context,
          '운영시간 및 브레이크 타임 $breakTimeChangeCount개가 저장되었습니다',
        );
      } else {
        AppSnackBar.success(context, '운영시간이 저장되었습니다');
      }
      widget.onSaveCompleted?.call();
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.error(context, '저장 실패: $e');
      _rollback();
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  /// 운영시간 아이템 빌드
  List<OperatingHoursItem> _buildOperatingHoursItems() {
    final items = <OperatingHoursItem>[];

    for (int day = 0; day < 7; day++) {
      final dayOfWeek = _indexToDayOfWeek(day);

      if (_isOperating[day] == true) {
        final range = _timeRanges[day]!;
        items.add(OperatingHoursItem(
          dayOfWeek: dayOfWeek,
          startTime: _slotToTimeString(range.start.toInt()),
          endTime: _slotToTimeString(range.end.toInt()),
          isClosed: false,
        ));
      } else {
        items.add(OperatingHoursItem(
          dayOfWeek: dayOfWeek,
          startTime: null,
          endTime: null,
          isClosed: true,
        ));
      }
    }

    return items;
  }

  /// 롤백
  void _rollback() {
    setState(() {
      _isOperating.clear();
      _isOperating.addAll(_initialIsOperating);
      _timeRanges.clear();
      _timeRanges.addAll(_initialTimeRanges);
      _isDirty = false;
    });
  }

  /// 취소 처리
  void _handleCancel() {
    if (_isDirty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.dialog),
          ),
          title: Text('취소 확인', style: AppTheme.headlineSmall),
          content: Text(
            '변경사항이 저장되지 않았습니다.\n취소하시겠습니까?',
            style: AppTheme.bodyMedium,
          ),
          actions: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: NeutralOutlinedButton(
                    text: '돌아가기',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: PrimaryButton(
                    text: '취소',
                    onPressed: () {
                      Navigator.of(context).pop();
                      _rollback();
                      widget.onCancel?.call();
                    },
                    variant: PrimaryButtonVariant.error,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    } else {
      widget.onCancel?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 페이지 헤더
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '시설 운영시간 관리',
                    style: AppTheme.displayMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '주간 운영시간과 임시 휴무를 관리합니다',
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppColors.neutral600,
                    ),
                  ),
                ],
              ),
            ),

            // 주간 운영시간 섹션
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 섹션 헤더 (타이틀 + 버튼)
                  Row(
                    children: [
                      // 아이콘 + 텍스트 (고정 크기)
                      Icon(
                        Icons.schedule,
                        size: 20,
                        color: AppColors.neutral900,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '주간 운영시간',
                        style: AppTheme.headlineMedium,
                      ),
                      // 여백 (유연)
                      const Spacer(),
                      // 버튼 영역 (조건부 표시)
                      if (_isDirty) ...[
                        SizedBox(
                          width: 80,
                          child: NeutralOutlinedButton(
                            text: '취소',
                            onPressed: _isSaving ? null : _handleCancel,
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 100,
                          child: PrimaryButton(
                            text: _isSaving ? '저장 중...' : '저장',
                            onPressed: _isSaving ? null : _handleSave,
                            variant: PrimaryButtonVariant.brand,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 7개의 요일 카드
                  ...List.generate(7, (day) => _buildDayCard(day)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 요일별 카드 빌드 (좌우 분할 레이아웃)
  Widget _buildDayCard(int day) {
    final dayOfWeek = _indexToDayOfWeek(day);

    // 브레이크 타임 데이터 가져오기
    final restrictedTimesAsync = ref.watch(restrictedTimesProvider(widget.placeId));

    return restrictedTimesAsync.when(
      data: (allRestrictedTimes) {
        // 해당 요일의 브레이크 타임만 필터링
        final dayRestrictedTimes = allRestrictedTimes
            .where((rt) => rt.dayOfWeek == dayOfWeek)
            .toList()
          ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));

        return _buildDayCardContent(day, dayOfWeek, dayRestrictedTimes);
      },
      loading: () => _buildDayCardContent(day, dayOfWeek, []),  // 로딩 중에는 빈 리스트
      error: (err, stack) => _buildDayCardContent(day, dayOfWeek, []),  // 에러 시 빈 리스트
    );
  }

  /// 요일별 카드 컨텐츠 빌드
  Widget _buildDayCardContent(int day, String dayOfWeek, List<RestrictedTimeResponse> restrictedTimes) {
    final isOperating = _isOperating[day] ?? false;
    final timeRange = _timeRanges[day] ?? const RangeValues(36, 72);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.lightOutline),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // === 왼쪽: 토글 스위치 + 요일 (가로 배치, 고정 너비 140px) ===
          SizedBox(
            width: 140,
            child: Row(
              children: [
                // 토글 스위치
                Transform.scale(
                  scale: 0.85,
                  child: Switch(
                    value: isOperating,
                    onChanged: (value) {
                      setState(() {
                        _isOperating[day] = value;
                        _isDirty = true;
                      });
                    },
                    activeTrackColor: AppColors.brand,
                  ),
                ),
                const SizedBox(width: 8),
                // 요일 텍스트
                Text(
                  _indexToDayOfWeekKorean(day),
                  style: AppTheme.titleLarge,
                ),
              ],
            ),
          ),

          const SizedBox(width: AppSpacing.md),

          // === 오른쪽: 운영시간 정보 + 드래그 바 (Expanded) ===
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isOperating) ...[
                  // "운영시간" 레이블 (회색)
                  Text(
                    '운영시간',
                    style: AppTheme.bodySmall.copyWith(
                      color: AppColors.neutral600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),

                  // 운영시간 정보 (시작: 왼쪽 끝, 종료: 오른쪽 끝)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // 시작 시간 (왼쪽 끝)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '시작: ',
                            style: AppTheme.bodySmall.copyWith(
                              color: AppColors.neutral700,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          Text(
                            _slotToTimeString(timeRange.start.toInt()),
                            style: AppTheme.bodyMedium.copyWith(
                              color: AppColors.neutral900,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      // 종료 시간 (오른쪽 끝)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '종료: ',
                            style: AppTheme.bodySmall.copyWith(
                              color: AppColors.neutral700,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          Text(
                            _slotToTimeString(timeRange.end.toInt()),
                            style: AppTheme.bodyMedium.copyWith(
                              color: AppColors.neutral900,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  // Range Slider (드래그 바)
                  RangeSlider(
                    values: timeRange,
                    min: 0,
                    max: _totalSlots.toDouble(),
                    divisions: _totalSlots,
                    activeColor: (_modifiedDays[day] ?? false)
                        ? Colors.purple.shade700
                        : AppColors.brand,
                    inactiveColor: AppColors.brandLight,
                    onChanged: (RangeValues values) {
                      setState(() {
                        _timeRanges[day] = values;
                        _modifiedDays[day] = true;
                        _isDirty = true;
                      });
                    },
                  ),

                  // 브레이크 타임 섹션 추가
                  const SizedBox(height: 16),
                  _buildBreakTimeSection(day, dayOfWeek, restrictedTimes),
                ] else ...[
                  // 휴무 상태
                  Text(
                    '전체 휴무',
                    style: AppTheme.bodyMedium.copyWith(color: AppColors.neutral600),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 브레이크 타임 섹션 빌드 (좌측 정렬 제목 + 우측 "+" 버튼)
  Widget _buildBreakTimeSection(int dayIndex, String dayOfWeek, List<RestrictedTimeResponse> restrictedTimes) {
    // 로컬에서 추가된 브레이크 타임 (아직 서버에 저장되지 않음)
    final pendingAdds = (_pendingBreakTimeChanges[dayIndex] ?? [])
        .where((change) => change.type == BreakTimeChangeType.add)
        .toList();

    // 서버 데이터 + 로컬 추가 항목 합치기
    final totalCount = restrictedTimes.length + pendingAdds.length;
    final hasAnyBreakTime = totalCount > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 헤더: 제목 + "+" 버튼
        Row(
          children: [
            Text(
              '브레이크 타임 ($totalCount개)',
              style: AppTheme.bodyMedium.copyWith(
                color: AppColors.neutral700,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.add, size: 20, color: AppColors.brand),
              onPressed: () => _addNewBreakTimeLocal(dayIndex, dayOfWeek),
              tooltip: '브레이크 타임 추가',
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // 브레이크 타임 리스트 (항상 표시)
        if (!hasAnyBreakTime)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              '브레이크 타임을 추가하려면 "+" 버튼을 클릭하세요',
              style: AppTheme.bodySmall.copyWith(color: AppColors.neutral600),
            ),
          )
        else ...[
          // 서버 데이터 (기존 브레이크 타임)
          ...restrictedTimes.asMap().entries.map(
            (entry) => _buildBreakTimeItem(dayIndex, dayOfWeek, entry.value, entry.key),
          ),
          // 로컬 추가 항목 (아직 저장 안 됨)
          ...pendingAdds.map(
            (change) => _buildPendingBreakTimeItem(dayIndex, dayOfWeek, change),
          ),
        ],
      ],
    );
  }

  /// 로컬 추가 브레이크 타임 아이템 빌드 (아직 저장 안 됨)
  Widget _buildPendingBreakTimeItem(int dayIndex, String dayOfWeek, RestrictedTimeChange change) {
    // 임시 고유 키 생성 (저장 전이므로 ID가 없음)
    final tempKey = '${dayOfWeek}_${change.startTime}_${change.endTime}';

    // 현재 Range 값 (로컬 상태 또는 기본값)
    final currentRange = _breakTimeRanges[tempKey.hashCode] ??
        RangeValues(
          _timeStringToSlot(change.startTime).toDouble(),
          _timeStringToSlot(change.endTime).toDouble(),
        );

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 상단: 이유 Chip + 삭제 버튼 + "미저장" 라벨
          Row(
            children: [
              // 이유 Chip (클릭하여 수정 가능)
              InkWell(
                onTap: () => _editPendingReasonLocal(dayIndex, change),
                borderRadius: BorderRadius.circular(16),
                child: Chip(
                  label: Text(
                    change.reason ?? '브레이크 타임',
                    style: AppTheme.bodySmall,
                  ),
                  backgroundColor: Colors.transparent,
                  side: const BorderSide(color: AppColors.neutral400, width: 1),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              const SizedBox(width: 8),
              // "미저장" 라벨
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppColors.warning, width: 1),
                ),
                child: Text(
                  '미저장',
                  style: AppTheme.bodySmall.copyWith(
                    color: AppColors.warning,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              // 삭제 버튼
              IconButton(
                icon: const Icon(Icons.close, size: 16, color: AppColors.neutral600),
                onPressed: () => _deletePendingBreakTimeLocal(dayIndex, change),
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(),
                tooltip: '삭제',
              ),
            ],
          ),
          const SizedBox(height: 8),
          // 시간 표시 Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 시작 시간 (왼쪽 끝)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '시작',
                    style: AppTheme.bodySmall.copyWith(
                      color: AppColors.neutral700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatSlotTime(currentRange.start),
                    style: AppTheme.bodyMedium.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              // 종료 시간 (오른쪽 끝)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '종료',
                    style: AppTheme.bodySmall.copyWith(
                      color: AppColors.neutral700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatSlotTime(currentRange.end),
                    style: AppTheme.bodyMedium.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Range Slider
          RangeSlider(
            values: currentRange,
            min: 0,
            max: 96,
            divisions: 96,
            activeColor: AppColors.brand,
            inactiveColor: AppColors.brandLight,
            onChanged: (values) {
              setState(() {
                _breakTimeRanges[tempKey.hashCode] = values;
              });
            },
            onChangeEnd: (values) => _savePendingBreakTimeRangeLocal(dayIndex, change, values),
          ),
        ],
      ),
    );
  }

  /// 개별 브레이크 타임 아이템 빌드 (Range Slider 방식)
  Widget _buildBreakTimeItem(int dayIndex, String dayOfWeek, RestrictedTimeResponse rt, int index) {
    // 현재 브레이크 타임의 Range 값 (로컬 상태 또는 서버 데이터)
    final currentRange = _breakTimeRanges[rt.id] ?? _parseRestrictedTimeToRange(rt);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 상단: 이유 Chip + 삭제 버튼
          Row(
            children: [
              // 이유 Chip (클릭하여 수정 가능)
              InkWell(
                onTap: () => _editReasonLocal(rt),
                borderRadius: BorderRadius.circular(16),
                child: Chip(
                  label: Text(
                    rt.reason ?? '브레이크 타임',
                    style: AppTheme.bodySmall,
                  ),
                  backgroundColor: Colors.transparent,
                  side: const BorderSide(color: AppColors.neutral400, width: 1),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              const Spacer(),
              // 삭제 버튼
              IconButton(
                icon: const Icon(Icons.close, size: 16, color: AppColors.neutral600),
                onPressed: () => _deleteBreakTimeLocal(rt),
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(),
                tooltip: '삭제',
              ),
            ],
          ),
          const SizedBox(height: 8),
          // 시간 표시 Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 시작 시간 (왼쪽 끝)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '시작',
                    style: AppTheme.bodySmall.copyWith(
                      color: AppColors.neutral700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatSlotTime(currentRange.start),
                    style: AppTheme.bodyMedium.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              // 종료 시간 (오른쪽 끝)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '종료',
                    style: AppTheme.bodySmall.copyWith(
                      color: AppColors.neutral700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatSlotTime(currentRange.end),
                    style: AppTheme.bodyMedium.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Range Slider
          RangeSlider(
            values: currentRange,
            min: 0,
            max: 96,
            divisions: 96,
            activeColor: AppColors.brand,
            inactiveColor: AppColors.brandLight,
            onChanged: (values) {
              setState(() {
                _breakTimeRanges[rt.id] = values;
              });
            },
            onChangeEnd: (values) => _saveBreakTimeRangeLocal(rt, values),
          ),
        ],
      ),
    );
  }

  /// 브레이크 타임 삭제 (로컬 상태)
  Future<void> _deleteBreakTimeLocal(RestrictedTimeResponse rt) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('브레이크 타임 삭제', style: AppTheme.headlineSmall),
        content: Text(
          '이 브레이크 타임을 삭제하시겠습니까?',
          style: AppTheme.bodyMedium,
        ),
        actions: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: NeutralOutlinedButton(
                  text: '취소',
                  onPressed: () => Navigator.pop(context, false),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: PrimaryButton(
                  text: '삭제',
                  variant: PrimaryButtonVariant.error,
                  onPressed: () => Navigator.pop(context, true),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final dayIndex = _dayOfWeekToIndex(rt.dayOfWeek);

      // 변경사항 기록
      _recordBreakTimeChange(
        dayIndex,
        RestrictedTimeChange(
          type: BreakTimeChangeType.delete,
          id: rt.id,
          dayOfWeek: rt.dayOfWeek,
          startTime: rt.startTime,
          endTime: rt.endTime,
          reason: rt.reason,
        ),
      );

      // 해당 요일을 수정됨으로 표시
      setState(() {
        _modifiedDays[dayIndex] = true;
        _isDirty = true;
      });
    }
  }

  /// 슬롯을 TimeOfDay로 변환
  TimeOfDay _slotToTimeOfDay(int slot) {
    final hour = slot ~/ _slotsPerHour;
    final minute = (slot % _slotsPerHour) * 15;
    return TimeOfDay(hour: hour, minute: minute);
  }

  /// 시간이 범위 내에 있는지 확인
  bool _isTimeInRange(TimeOfDay time, TimeOfDay start, TimeOfDay end) {
    final timeMinutes = time.hour * 60 + time.minute;
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;

    return timeMinutes >= startMinutes && timeMinutes <= endMinutes;
  }

  /// 운영시간 변경으로 충돌하는 브레이크 타임 찾기
  List<RestrictedTimeResponse> _findConflictingBreakTimes(
    int dayIndex,
    String dayOfWeek,
    List<RestrictedTimeResponse> allRestrictedTimes,
  ) {
    final conflicts = <RestrictedTimeResponse>[];

    // 해당 요일의 운영 상태 확인
    final isOperating = _isOperating[dayIndex] ?? false;

    // 휴무로 변경한 경우 → 모든 브레이크 타임 삭제
    if (!isOperating) {
      conflicts.addAll(
        allRestrictedTimes.where((rt) => rt.dayOfWeek == dayOfWeek),
      );
      return conflicts;
    }

    // 운영시간 범위 가져오기
    final operatingRange = _timeRanges[dayIndex];
    if (operatingRange == null) return conflicts;

    final operatingStart = _slotToTimeOfDay(operatingRange.start.toInt());
    final operatingEnd = _slotToTimeOfDay(operatingRange.end.toInt());

    // 해당 요일의 브레이크 타임 필터링
    final dayRestrictedTimes = allRestrictedTimes
        .where((rt) => rt.dayOfWeek == dayOfWeek)
        .toList();

    // 각 브레이크 타임이 운영시간 범위를 벗어나는지 체크
    for (final rt in dayRestrictedTimes) {
      final breakStartParts = rt.startTime.split(':');
      final breakEndParts = rt.endTime.split(':');

      final breakStart = TimeOfDay(
        hour: int.parse(breakStartParts[0]),
        minute: int.parse(breakStartParts[1]),
      );
      final breakEnd = TimeOfDay(
        hour: int.parse(breakEndParts[0]),
        minute: int.parse(breakEndParts[1]),
      );

      // 브레이크 타임이 운영시간 범위 밖인 경우
      if (!_isTimeInRange(breakStart, operatingStart, operatingEnd) ||
          !_isTimeInRange(breakEnd, operatingStart, operatingEnd)) {
        conflicts.add(rt);
      }
    }

    return conflicts;
  }

  /// RestrictedTimeResponse → RangeValues 변환
  RangeValues _parseRestrictedTimeToRange(RestrictedTimeResponse rt) {
    final start = _timeStringToSlot(rt.startTime);
    final end = _timeStringToSlot(rt.endTime);
    return RangeValues(start.toDouble(), end.toDouble());
  }

  /// 슬롯 → "HH:mm" (브레이크 타임용)
  String _formatSlotTime(double slot) {
    final totalMinutes = (slot * 15).toInt();
    final hour = totalMinutes ~/ 60;
    final minute = totalMinutes % 60;
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  /// 브레이크 타임 Range 변경 (로컬 상태만 업데이트)
  void _saveBreakTimeRangeLocal(RestrictedTimeResponse rt, RangeValues values) {
    final startTime = _formatSlotTime(values.start);
    final endTime = _formatSlotTime(values.end);

    // 어느 요일의 브레이크 타임인지 찾기
    final dayIndex = _dayOfWeekToIndex(rt.dayOfWeek);
    if (dayIndex != -1) {
      final operatingRange = _timeRanges[dayIndex];

      // 운영시간 범위 체크
      if (operatingRange != null) {
        final operatingStart = _slotToTimeOfDay(operatingRange.start.toInt());
        final operatingEnd = _slotToTimeOfDay(operatingRange.end.toInt());
        final breakStart = _slotToTimeOfDay(values.start.toInt());
        final breakEnd = _slotToTimeOfDay(values.end.toInt());

        // 범위 체크
        if (!_isTimeInRange(breakStart, operatingStart, operatingEnd) ||
            !_isTimeInRange(breakEnd, operatingStart, operatingEnd)) {
          if (mounted) {
            AppSnackBar.error(
              context,
              '브레이크 타임은 운영시간 범위 내에 있어야 합니다',
            );
          }
          // 원래 값으로 복원
          setState(() {
            _breakTimeRanges.remove(rt.id);
          });
          return;
        }
      }

      // 변경사항 기록
      _recordBreakTimeChange(
        dayIndex,
        RestrictedTimeChange(
          type: BreakTimeChangeType.update,
          id: rt.id,
          dayOfWeek: rt.dayOfWeek,
          startTime: startTime,
          endTime: endTime,
          reason: rt.reason,
        ),
      );

      // 해당 요일을 수정됨으로 표시
      setState(() {
        _modifiedDays[dayIndex] = true;
        _isDirty = true;
      });
    }
  }

  /// "+" 버튼 클릭 시 새 브레이크 타임 추가 (로컬 상태)
  void _addNewBreakTimeLocal(int dayIndex, String dayOfWeek) {
    // 운영시간 범위 가져오기
    final operatingRange = _timeRanges[dayIndex];
    String startTime = '12:00';
    String endTime = '13:00';

    // 운영시간이 설정된 경우 범위 내에서 기본값 설정
    if (operatingRange != null) {
      final operatingStart = _slotToTimeOfDay(operatingRange.start.toInt());
      final operatingEnd = _slotToTimeOfDay(operatingRange.end.toInt());

      // 기본 브레이크 타임(12:00-13:00)이 운영시간 범위 밖이면 운영시간 범위 내로 조정
      final defaultBreakStart = const TimeOfDay(hour: 12, minute: 0);
      final defaultBreakEnd = const TimeOfDay(hour: 13, minute: 0);

      if (!_isTimeInRange(defaultBreakStart, operatingStart, operatingEnd) ||
          !_isTimeInRange(defaultBreakEnd, operatingStart, operatingEnd)) {
        // 운영 시작 시간 + 1시간을 기본값으로 설정
        startTime = _slotToTimeString(operatingRange.start.toInt());
        final endSlot = (operatingRange.start.toInt() + 4).clamp(0, operatingRange.end.toInt());
        endTime = _slotToTimeString(endSlot);
      }
    }

    // 변경사항 기록
    _recordBreakTimeChange(
      dayIndex,
      RestrictedTimeChange(
        type: BreakTimeChangeType.add,
        dayOfWeek: dayOfWeek,
        startTime: startTime,
        endTime: endTime,
        reason: '브레이크 타임',
      ),
    );

    // 해당 요일을 수정됨으로 표시
    setState(() {
      _modifiedDays[dayIndex] = true;
      _isDirty = true;
    });
  }

  /// 이유(reason) 수정 (로컬 상태)
  Future<void> _editReasonLocal(RestrictedTimeResponse rt) async {
    final controller = TextEditingController(text: rt.reason ?? '');

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.dialog),
        ),
        title: Text('브레이크 타임 이름', style: AppTheme.headlineSmall),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: '이름 (예: 점심시간)'),
          autofocus: true,
        ),
        actions: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: NeutralOutlinedButton(
                  text: '취소',
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: PrimaryButton(
                  text: '저장',
                  variant: PrimaryButtonVariant.brand,
                  onPressed: () => Navigator.pop(context, controller.text),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (result != null && result != rt.reason && mounted) {
      final dayIndex = _dayOfWeekToIndex(rt.dayOfWeek);

      // 변경사항 기록
      _recordBreakTimeChange(
        dayIndex,
        RestrictedTimeChange(
          type: BreakTimeChangeType.update,
          id: rt.id,
          dayOfWeek: rt.dayOfWeek,
          startTime: rt.startTime,
          endTime: rt.endTime,
          reason: result,
        ),
      );

      // 해당 요일을 수정됨으로 표시
      setState(() {
        _modifiedDays[dayIndex] = true;
        _isDirty = true;
      });
    }
  }

  /// 브레이크 타임 변경사항 기록
  void _recordBreakTimeChange(int dayIndex, RestrictedTimeChange change) {
    if (!_pendingBreakTimeChanges.containsKey(dayIndex)) {
      _pendingBreakTimeChanges[dayIndex] = [];
    }

    // 같은 ID의 기존 변경사항이 있으면 대체
    if (change.id != null) {
      _pendingBreakTimeChanges[dayIndex]!.removeWhere((c) => c.id == change.id);
    }

    _pendingBreakTimeChanges[dayIndex]!.add(change);
  }

  /// 미저장 브레이크 타임 삭제 (로컬 상태)
  void _deletePendingBreakTimeLocal(int dayIndex, RestrictedTimeChange change) {
    setState(() {
      _pendingBreakTimeChanges[dayIndex]?.remove(change);
      _isDirty = _pendingBreakTimeChanges.values.any((list) => list.isNotEmpty);
    });
  }

  /// 미저장 브레이크 타임 이름 수정 (로컬 상태)
  Future<void> _editPendingReasonLocal(int dayIndex, RestrictedTimeChange change) async {
    final controller = TextEditingController(text: change.reason ?? '');

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.dialog),
        ),
        title: Text('브레이크 타임 이름', style: AppTheme.headlineSmall),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: '이름 (예: 점심시간)'),
          autofocus: true,
        ),
        actions: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: NeutralOutlinedButton(
                  text: '취소',
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: PrimaryButton(
                  text: '저장',
                  variant: PrimaryButtonVariant.brand,
                  onPressed: () => Navigator.pop(context, controller.text),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (result != null && result != change.reason && mounted) {
      setState(() {
        // 리스트에서 기존 항목 찾아서 reason 업데이트
        final index = _pendingBreakTimeChanges[dayIndex]?.indexOf(change) ?? -1;
        if (index != -1) {
          _pendingBreakTimeChanges[dayIndex]![index] = RestrictedTimeChange(
            type: change.type,
            id: change.id,
            dayOfWeek: change.dayOfWeek,
            startTime: change.startTime,
            endTime: change.endTime,
            reason: result,
          );
        }
      });
    }
  }

  /// 미저장 브레이크 타임 시간 변경 (로컬 상태)
  void _savePendingBreakTimeRangeLocal(int dayIndex, RestrictedTimeChange change, RangeValues values) {
    final startTime = _formatSlotTime(values.start);
    final endTime = _formatSlotTime(values.end);

    final operatingRange = _timeRanges[dayIndex];

    // 운영시간 범위 체크
    if (operatingRange != null) {
      final operatingStart = _slotToTimeOfDay(operatingRange.start.toInt());
      final operatingEnd = _slotToTimeOfDay(operatingRange.end.toInt());
      final breakStart = _slotToTimeOfDay(values.start.toInt());
      final breakEnd = _slotToTimeOfDay(values.end.toInt());

      // 범위 체크
      if (!_isTimeInRange(breakStart, operatingStart, operatingEnd) ||
          !_isTimeInRange(breakEnd, operatingStart, operatingEnd)) {
        if (mounted) {
          AppSnackBar.error(
            context,
            '브레이크 타임은 운영시간 범위 내에 있어야 합니다',
          );
        }
        // 원래 값으로 복원
        final tempKey = '${change.dayOfWeek}_${change.startTime}_${change.endTime}';
        setState(() {
          _breakTimeRanges.remove(tempKey.hashCode);
        });
        return;
      }
    }

    setState(() {
      // 리스트에서 기존 항목 찾아서 시간 업데이트
      final index = _pendingBreakTimeChanges[dayIndex]?.indexOf(change) ?? -1;
      if (index != -1) {
        _pendingBreakTimeChanges[dayIndex]![index] = RestrictedTimeChange(
          type: change.type,
          id: change.id,
          dayOfWeek: change.dayOfWeek,
          startTime: startTime,
          endTime: endTime,
          reason: change.reason,
        );
      }
    });
  }
}

/// 브레이크 타임 변경 타입
enum BreakTimeChangeType {
  add,    // 새로 추가
  update, // 수정
  delete, // 삭제
}

/// 브레이크 타임 변경사항
class RestrictedTimeChange {
  final BreakTimeChangeType type;
  final int? id;  // update/delete 시 사용
  final String dayOfWeek;
  final String startTime;
  final String endTime;
  final String? reason;

  RestrictedTimeChange({
    required this.type,
    this.id,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.reason,
  });
}
