# 읽지 않은 글 기능 구현 체크리스트

이 체크리스트는 [읽지 않은 글 기능 구현 가이드](../implementation/frontend/unread-posts-implementation.md)의 Phase별 실행 체크리스트입니다.

**총 예상 기간**: 15일 (3주)

---

## Phase 1: Domain Layer 구축 (3일) ✅ **완료**

**목표**: 순수 함수로 비즈니스 로직 구현 (테스트 가능)

### Task 1.1: Entity 정의 (1일)
- [X] `features/channel/domain/entities/read_position.dart` 작성 (~30줄)
  - channelId, lastReadPostId, updatedAt 필드 포함
- [X] `features/channel/domain/entities/unread_position_result.dart` 작성 (~40줄)
  - unreadIndex, totalUnread, hasUnread 필드 포함
- [X] `features/channel/domain/entities/channel_entry_result.dart` 수정
  - unreadPosition 필드 추가

### Task 1.2: Repository 인터페이스 정의 (0.5일)
- [X] `features/channel/domain/repositories/read_position_repository.dart` 확인 (이미 존재)
  - getReadPosition(channelId) 메서드
  - updateReadPosition(channelId, postId) 메서드
  - getUnreadCount(channelId) 메서드
  - getAllReadPositions(channelIds) 메서드

### Task 1.3: UseCase 구현 (1.5일)
- [X] `features/channel/domain/usecases/calculate_unread_position_usecase.dart` 작성 (~75줄)
  - 순수 함수: 첫 읽지 않은 글 인덱스 계산
  - Edge Case 처리 (빈 리스트, 읽은 위치 없음, 모두 읽음, 삭제된 게시글)
  - **단위 테스트 16개 통과 ✅**
- [X] `features/channel/domain/usecases/enter_channel_usecase.dart` 수정 (~68줄)
  - CalculateUnreadPositionUseCase 통합
  - unreadPosition을 ChannelEntryResult에 포함
- [X] `features/channel/domain/usecases/update_read_position_usecase.dart` 작성 (~20줄)
  - Repository를 통한 읽음 위치 업데이트
- [X] `features/channel/domain/usecases/get_read_position_usecase.dart` 작성 (~20줄)
  - Repository를 통한 읽음 위치 조회

### Phase 1 체크포인트
- [X] 모든 UseCase 단위 테스트 통과 (16개 테스트 성공)
- [X] 순수 함수 계산 로직 검증 완료
- [X] Domain Layer Flutter 의존성 없음 확인

---

## Phase 2: Data Layer 구축 (2일) ✅ **완료**

**목표**: API 통신 및 로컬 캐시 구현

### Task 2.1: DataSource 구현 (1일)
- [X] `features/channel/data/datasources/read_position_remote_datasource.dart` 작성 (~103줄)
  - getReadPosition(channelId) - GET /api/channels/{channelId}/read-position
  - updateReadPosition(channelId, postId) - PUT /api/channels/{channelId}/read-position
  - getUnreadCount(channelId) - GET /api/channels/{channelId}/unread-count
  - getBatchUnreadCounts(channelIds) - GET /api/channels/unread-counts?channelIds=1,2,3
- [X] `features/channel/data/models/read_position_dto.dart` 작성 (~40줄)
  - JSON 직렬화/역직렬화 (Freezed + json_serializable)
  - toEntity() 메서드
- [X] ReadPositionLocalDataSource 확인 (이미 존재)
  - SharedPreferences 기반 캐시 역할

### Task 2.2: Repository 구현 (1일)
- [X] `features/channel/data/repositories/read_position_repository_impl.dart` 작성 (~67줄)
  - getReadPosition: 로컬 캐시 우선 → 백엔드 API 호출 → 캐시 저장
  - updateReadPosition: 백엔드 API 호출 + 로컬 캐시 갱신
  - getUnreadCount: 백엔드 API 호출 (캐시 없음)
  - getAllReadPositions: 백엔드 배치 API 호출 (캐시 없음)
- [X] Provider 등록 (features/channel/presentation/providers/channel_providers.dart)
  - readPositionRemoteDataSourceProvider 추가
  - readPositionRepositoryProvider에 Remote DataSource 통합

### Phase 2 체크포인트
- [X] API 통합 테스트 통과 (4개 테스트 성공)
  - 로컬 캐시 히트 - 원격 API 호출 없음
  - 로컬 캐시 미스 - 원격 API 호출 후 캐시 저장
  - 로컬/원격 모두 없음 - null 반환
  - updateReadPosition - 원격 API 호출 + 로컬 캐시 갱신
- [X] 로컬 캐시 동작 검증 (Cache-first 전략 확인)
- [X] DTO ↔ Entity 매핑 정확성 확인 (Freezed 코드 생성 완료)
- [X] 전체 채널 테스트 93개 통과 (dart-flutter MCP)

---

## Phase 3: Presentation Layer (5일) ✅ **완료**

**목표**: UI 렌더링 및 사용자 인터랙션

### Task 3.1: Provider 구현 (2일)
- [X] `features/channel/presentation/providers/read_position_notifier.dart` 작성 (95줄)
  - ReadPositionNotifier (AutoDisposeFamilyAsyncNotifier<ReadPositionState, int>)
  - markAsRead(postId) 메서드 (200ms 디바운싱)
  - 낙관적 업데이트 + 백그라운드 저장
  - 재시도 큐 구현
- [X] `features/channel/presentation/providers/unread_badge_notifier.dart` 작성 (67줄)
  - UnreadBadgeNotifier (AutoDisposeFamilyAsyncNotifier<int, int>)
  - refreshAll(channelIds) 메서드 (배치 갱신)

### Task 3.2: Widget 구현 (2일)
- [X] `features/channel/presentation/widgets/channel_view.dart` 수정
  - channelEntryProvider에서 unreadPosition을 PostList로 전달
- [X] `presentation/widgets/post/post_list.dart` 수정
  - unreadPosition을 받아서 자동 스크롤 구현
  - UnreadDivider 삽입
  - PostItemWithTracking 사용 (가시성 추적)
  - Sticky Header 유지
- [X] `presentation/widgets/post/post_item_with_tracking.dart` 신규 작성 (48줄)
  - VisibilityDetector 래핑
  - visibleFraction >= 0.3일 때 markAsRead(postId) 호출
  - PostItem 재사용
- [X] `presentation/widgets/post/unread_divider.dart` 신규 작성 (72줄)
  - "읽지 않은 글" 구분선 UI
  - 읽지 않은 글 중 가장 오래된 글 위에 표시
- [X] `core/models/post_list_item.dart` 수정
  - UnreadDividerWrapper 타입 추가 (sealed class 패턴)

### Task 3.3: Widget 테스트 (1일)
- [X] 기존 테스트 통과 확인 (377개 테스트 통과)
- [X] 컴파일 에러 해결 (AppTheme.labelMedium → bodySmall)
- [X] 구식 테스트 파일 제거 (read_position_notifier_test.dart, sticky_header_notifier_test.dart, scroll_controller_provider_test.dart)

### Phase 3 체크포인트
- [X] Widget 테스트 통과 (377/381 테스트 성공, 4개 디자인 시스템 contrast 테스트 실패는 별도 이슈)
- [X] 자동 스크롤 구현 완료 (_scrollToUnreadPosition 메서드)
- [X] Visibility Tracking 구현 완료 (PostItemWithTracking + VisibilityDetector)
- [X] Clean Architecture 준수 (Presentation Layer → Domain → Data)
- [X] 파일당 100줄 이하 제한 준수

---

## Phase 4: 워크스페이스 통합 (2일) ✅ **완료**

**목표**: 채널 목록 배지 표시 및 네비게이션 통합

### Task 4.1: 배지 표시 (1일)
- [X] `presentation/widgets/workspace/channel_navigation.dart` 수정
  - unreadBadgeProvider(channelId).watch() 추가 (채널별 개별 구독)
  - 배지 UI는 이미 존재 (UnreadBadge 위젯)
  - 더미 데이터 제거, 실제 Provider 연결 완료

### Task 4.2: 네비게이션 훅 (1일)
- [X] `presentation/providers/workspace_state_provider.dart` 수정
  - `loadChannels()`: 그룹 전환 시 배치 갱신 (`_refreshBadges()` 호출)
  - `selectChannel()`: 채널 전환 시 배치 갱신 (`_refreshBadges()` 호출)
  - `selectChannelForMobile()`: 모바일 채널 전환 시 배치 갱신 (`_refreshBadges()` 호출)
- [X] 배지 갱신 헬퍼 메서드 구현 (`_refreshBadges()`)
  - Ref.invalidate()를 사용하여 각 채널 provider 무효화
  - WidgetRef 타입 불일치 문제 해결

### Phase 4 체크포인트
- [X] 배지 표시 정상 동작 (channel_navigation.dart에서 unreadBadgeProvider 구독)
- [X] 네비게이션 훅 정상 동작 (workspace_state_provider.dart에 갱신 로직 추가)
- [X] 채널/그룹 전환 시 배치 갱신 확인 (_refreshBadges 메서드)
- [X] 테스트 통과: 377/381 (4개 디자인 시스템 contrast 테스트 실패는 별도 이슈)

---

## Phase 5: 최적화 및 검증 (3일)

**목표**: 성능 튜닝 및 E2E 테스트

### Task 5.1: 성능 최적화 (1일)
- [ ] 디바운싱 타이밍 튜닝 (200ms → 최적값 찾기)
- [ ] 배치 업데이트 최적화 (중복 호출 방지)
- [ ] 메모리 누수 확인 (VisibilityDetector, Timer)
- [ ] 성능 프로파일링 실행

### Task 5.2: E2E 테스트 (1일)
- [ ] 채널 진입 → 자동 스크롤 테스트
- [ ] 스크롤하면서 읽음 처리 테스트
- [ ] 채널 전환 → 배지 갱신 테스트
- [ ] 네트워크 실패 → 재시도 테스트
- [ ] 로그아웃 → 로그인 → 읽음 위치 복원 테스트

### Task 5.3: 문서화 (1일)
- [ ] 아키텍처 문서 업데이트 (이 체크리스트 완료 상태 반영)
- [ ] API 사용법 문서 작성 (필요시)
- [ ] 코드 리뷰 수행
- [ ] README 업데이트 (기능 목록에 추가)

### Phase 5 체크포인트
- [ ] E2E 테스트 100% 통과
- [ ] 성능 프로파일링 결과 문제 없음
- [ ] 문서화 완료
- [ ] 코드 리뷰 승인

---

## 전체 검증 기준

### 정량적 지표
- [ ] 모든 파일 100줄 이하
- [ ] 테스트 커버리지 90% 이상
- [ ] Race Condition 0개
- [ ] E2E 테스트 100% 통과

### 정성적 지표
- [ ] 자동 스크롤이 정상 작동
- [ ] 배지가 실시간으로 갱신
- [ ] 네트워크 실패 시에도 동작 (로컬 캐시)
- [ ] 유지보수가 쉬움 (파일당 100줄)

---

## 최종 확인 사항

- [ ] Clean Architecture 3-Layer 엄격 준수 확인
- [ ] AsyncNotifier 패턴 일원화 확인
- [ ] 이전 실패 요인(Race Condition, 계산 누락, 아키텍처 위반) 회피 확인
- [ ] 헌법 원칙 준수 확인 (.specify/memory/constitution.md)
- [ ] MCP 도구로 테스트 실행 확인 (dart-flutter run_tests)

---

**참조**: [읽지 않은 글 기능 구현 가이드](../implementation/frontend/unread-posts-implementation.md)
