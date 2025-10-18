# 장소 시간 관리 UI 사용 예시

## 개요
장소 시간 관리 UI를 기존 Flutter 앱에 통합하는 방법을 설명합니다.

---

## 1. 장소 캘린더 화면에서 "장소 관리" 버튼 추가

### 기존 장소 캘린더 위젯에 버튼 추가
```dart
// lib/features/calendar/place_calendar/presentation/pages/place_calendar_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/theme.dart';
import '../../../place_admin/presentation/pages/place_admin_settings_page.dart';

class PlaceCalendarPage extends ConsumerWidget {
  final int placeId;
  final String placeName;
  final int managingGroupId; // 관리 그룹 ID

  const PlaceCalendarPage({
    super.key,
    required this.placeId,
    required this.placeName,
    required this.managingGroupId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 현재 사용자의 권한 체크
    final currentUser = ref.watch(authProvider).user;
    final currentGroupId = ref.watch(selectedGroupIdProvider); // 현재 선택된 그룹

    // 관리 버튼 표시 조건:
    // 1. CALENDAR_MANAGE 권한 보유
    // 2. 현재 그룹이 관리 그룹과 동일
    final canManage = currentUser != null &&
        currentUser.permissions.contains('CALENDAR_MANAGE') &&
        currentGroupId == managingGroupId;

    return Scaffold(
      appBar: AppBar(
        title: Text(placeName),
        actions: [
          if (canManage)
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => PlaceAdminSettingsPage(
                      placeId: placeId,
                      placeName: placeName,
                    ),
                  ),
                );
              },
              tooltip: '장소 관리',
            ),
        ],
      ),
      body: Column(
        children: [
          // 관리 그룹 표시
          Container(
            padding: const EdgeInsets.all(12),
            color: AppColors.brandLight,
            child: Row(
              children: [
                const Icon(
                  Icons.admin_panel_settings,
                  size: 18,
                  color: AppColors.brandPrimary,
                ),
                const SizedBox(width: 8),
                Text(
                  '관리 그룹: [그룹명]', // 실제로는 그룹 정보 조회
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.neutral700,
                  ),
                ),
              ],
            ),
          ),

          // 장소 관리 버튼 (카드 형태, 더 눈에 띄게)
          if (canManage)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 2,
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => PlaceAdminSettingsPage(
                          placeId: placeId,
                          placeName: placeName,
                        ),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Icon(
                          Icons.manage_history,
                          color: AppColors.brandPrimary,
                          size: 32,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '장소 시간 관리',
                                style: AppTypography.titleLarge,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '운영시간, 금지시간, 임시 휴무 설정',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.neutral600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // 기존 캘린더 뷰
          Expanded(
            child: _buildCalendarView(),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarView() {
    // 기존 캘린더 뷰 구현
    return Container();
  }
}
```

---

## 2. 직접 페이지로 네비게이션하는 경우

### 예시 1: 그룹 관리 페이지에서 링크
```dart
// lib/presentation/pages/group_admin/group_admin_page.dart

ElevatedButton.icon(
  onPressed: () {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PlaceAdminSettingsPage(
          placeId: selectedPlaceId,
          placeName: selectedPlaceName,
        ),
      ),
    );
  },
  icon: const Icon(Icons.schedule),
  label: const Text('장소 시간 관리'),
)
```

### 예시 2: 장소 목록에서 각 아이템에 관리 버튼
```dart
// lib/features/place/presentation/widgets/place_list_item.dart

ListTile(
  title: Text(place.name),
  subtitle: Text('${place.building}-${place.roomNumber}'),
  trailing: canManage
      ? IconButton(
          icon: const Icon(Icons.settings),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => PlaceAdminSettingsPage(
                  placeId: place.id,
                  placeName: place.name,
                ),
              ),
            );
          },
        )
      : null,
)
```

---

## 3. 라우터에 등록하는 경우 (GoRouter)

### app_router.dart에 추가
```dart
import '../features/place_admin/presentation/pages/place_admin_settings_page.dart';

GoRoute(
  path: '/place/:placeId/admin',
  builder: (context, state) {
    final placeId = int.parse(state.pathParameters['placeId']!);
    final placeName = state.uri.queryParameters['name'] ?? '장소';

    return PlaceAdminSettingsPage(
      placeId: placeId,
      placeName: placeName,
    );
  },
)
```

### 네비게이션
```dart
context.go('/place/$placeId/admin?name=${Uri.encodeComponent(placeName)}');
```

---

## 4. 권한 체크 유틸리티

### 권한 체크 헬퍼 함수 생성
```dart
// lib/core/utils/place_permission_utils.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

class PlacePermissionUtils {
  /// 장소 관리 권한 체크
  ///
  /// 조건:
  /// 1. CALENDAR_MANAGE 권한 보유
  /// 2. 현재 그룹이 관리 그룹과 동일
  static bool canManagePlace({
    required List<String> userPermissions,
    required int currentGroupId,
    required int managingGroupId,
  }) {
    return userPermissions.contains('CALENDAR_MANAGE') &&
        currentGroupId == managingGroupId;
  }

  /// 장소 예약 권한 체크
  ///
  /// 조건:
  /// - PlaceUsageGroup APPROVED 상태 (백엔드에서 확인)
  static bool canReservePlace() {
    // 실제로는 백엔드 API 조회 필요
    // 여기서는 간단히 true 반환 (백엔드에서 검증)
    return true;
  }
}
```

### 사용 예시
```dart
final currentUser = ref.watch(authProvider).user;
final currentGroupId = ref.watch(selectedGroupIdProvider);

if (PlacePermissionUtils.canManagePlace(
  userPermissions: currentUser?.permissions ?? [],
  currentGroupId: currentGroupId,
  managingGroupId: place.managingGroupId,
)) {
  // 관리 버튼 표시
  _buildManageButton();
}
```

---

## 5. 위젯 개별 사용 (고급)

각 위젯을 독립적으로 사용할 수도 있습니다.

### 운영시간만 표시
```dart
import 'package:flutter/material.dart';
import '../widgets/place_operating_hours_dialog.dart';

class MyCustomPage extends StatelessWidget {
  final int placeId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          PlaceOperatingHoursDisplay(placeId: placeId),
        ],
      ),
    );
  }
}
```

### 금지시간만 관리
```dart
import '../widgets/restricted_time_widgets.dart';

RestrictedTimeListWidget(placeId: placeId),
```

### 임시 휴무 캘린더만 표시
```dart
import '../widgets/place_closure_widgets.dart';

PlaceClosureCalendarWidget(placeId: placeId),
```

### 예약 가능 시간만 조회
```dart
import '../widgets/available_times_widget.dart';

AvailableTimesWidget(placeId: placeId),
```

---

## 6. 에러 처리 커스터마이징

### 전역 에러 핸들러 추가 (선택)
```dart
// lib/core/utils/error_handler.dart

class PlaceTimeErrorHandler {
  static String getErrorMessage(Object error) {
    final errorStr = error.toString();

    if (errorStr.contains('PLACE_NOT_FOUND')) {
      return '장소를 찾을 수 없습니다';
    } else if (errorStr.contains('PERMISSION_DENIED')) {
      return '권한이 없습니다';
    } else if (errorStr.contains('CONFLICT')) {
      return '이미 예약이 존재하거나 시간이 겹칩니다';
    } else {
      return '오류가 발생했습니다: $error';
    }
  }
}

// 사용 예시
catch (e) {
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(PlaceTimeErrorHandler.getErrorMessage(e))),
    );
  }
}
```

---

## 7. 테스트 시나리오

### 시나리오 1: 기본 플로우
1. 장소 캘린더 화면 진입
2. "장소 관리" 버튼 클릭
3. PlaceAdminSettingsPage 열림
4. 운영시간 설정 (월-금 09:00-18:00)
5. 금지시간 추가 (수요일 12:00-13:00, 사유: 점심시간)
6. 임시 휴무 추가 (다음 주 월요일 전일 휴무, 사유: 공휴일)
7. 예약 가능 시간 조회 (금요일 선택)
8. 결과 확인: 09:00-12:00, 14:00-18:00 (점심시간 제외)

### 시나리오 2: 권한 없는 사용자
1. CALENDAR_MANAGE 권한이 없는 사용자로 로그인
2. 장소 캘린더 화면 진입
3. "장소 관리" 버튼이 표시되지 않아야 함
4. URL 직접 입력으로 PlaceAdminSettingsPage 접근 시도
5. 백엔드에서 403 Forbidden 응답 (권한 체크)

### 시나리오 3: 다른 그룹의 장소
1. 그룹 A 관리자로 로그인
2. 그룹 B가 관리하는 장소 캘린더 진입
3. "장소 관리" 버튼이 표시되지 않아야 함
4. 예약 가능 시간 조회는 가능 (읽기 권한 공개)

---

## 8. 문제 해결

### 문제 1: 다이얼로그가 열리지 않음
```dart
// 확인 사항:
// 1. import 경로 확인
// 2. showDialog 호출 시 context가 유효한지 확인
// 3. Navigator.of(context)가 올바른 context를 사용하는지 확인

// 해결:
await showDialog<bool>(
  context: context, // 여기
  builder: (context) => PlaceOperatingHoursDialog(
    placeId: placeId,
    initialHours: null,
  ),
);
```

### 문제 2: Provider가 업데이트되지 않음
```dart
// 확인 사항:
// 1. ref.invalidate() 호출 확인
// 2. Provider family 파라미터가 올바른지 확인

// 해결:
await ref.read(setOperatingHoursProvider(params).future);
ref.invalidate(operatingHoursProvider(placeId)); // 이 부분 추가
```

### 문제 3: TimeOfDay picker가 12시간 형식으로 표시됨
```dart
// 해결: builder에서 MediaQuery 설정
await showTimePicker(
  context: context,
  initialTime: TimeOfDay(hour: 9, minute: 0),
  builder: (context, child) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
      child: child!,
    );
  },
);
```

---

## 9. 다음 단계

1. **실제 데이터로 테스트**:
   - 백엔드 실행 후 실제 API 연동 테스트
   - 다양한 시나리오에서 동작 확인

2. **권한 체크 강화**:
   - 프론트엔드에서도 사전 권한 체크 추가
   - 접근 거부 시 명확한 메시지 표시

3. **UX 개선**:
   - 로딩 상태 개선 (skeleton UI)
   - 에러 메시지 구체화
   - 성공 피드백 강화

4. **문서화**:
   - API 문서 업데이트
   - 사용자 가이드 작성

---

## 참고 자료
- [산출물 문서](PLACE_TIME_MANAGEMENT_DELIVERABLES.md)
- [프론트엔드 개발 가이드](docs/implementation/frontend-guide.md)
- [디자인 시스템](docs/ui-ux/concepts/design-system.md)
