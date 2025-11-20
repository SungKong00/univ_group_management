# 읽지 않은 글 기능 구현 가이드

## 개요

채널 게시글의 읽지 않은 글을 추적하고 사용자에게 시각적으로 표시하는 기능입니다.

**주요 기능**:
- 워크스페이스 채널 목록에 읽지 않은 글 개수 배지 표시
- 채널 진입 시 읽지 않은 글로 자동 스크롤
- 읽지 않은 글 구분선 표시
- 스크롤 기반 자동 읽음 처리 (30% 가시성)
- 화면 전환 시 배치 업데이트

**배경**: 이전 구현(2025-11-19)이 Race Condition과 아키텍처 위반으로 제거되었습니다. 이번 구현은 이러한 실패 요인을 회피하는 데 중점을 둡니다.

## 핵심 설계 원칙

### 1. Clean Architecture 3-Layer 엄격 준수
- **Domain Layer**: 순수 함수로 비즈니스 로직 구현 (Flutter 의존성 없음)
- **Data Layer**: API 통신 및 로컬 캐시 관리
- **Presentation Layer**: UI 렌더링 및 사용자 인터랙션만

### 2. AsyncNotifier 패턴 일원화
- 모든 상태 관리는 AsyncNotifier 사용
- `Provider.build()`가 모든 데이터 로딩 보장
- StateNotifier 사용 금지

### 3. Race Condition 회피
- `EnterChannelUseCase`로 원자적 데이터 로딩 (권한, 읽음 위치, 게시글 동시 로딩)
- PostList는 모든 데이터 준비 완료 후에만 렌더링
- 읽지 않은 글 인덱스 계산을 Domain Layer에서 보장

### 4. 단일 책임 원칙 (SRP)
- 파일당 최대 100줄 유지
- 각 Provider는 1개 책임만
- View는 ViewModel 메서드만 호출

## 아키텍처 개요

### Domain Layer
**엔티티**:
- `ReadPosition`: channelId, lastReadPostId, updatedAt
- `UnreadPositionResult`: firstUnreadIndex, totalUnread, hasUnread, flatItems
- `ChannelEntryResult`: permissions, readPosition, posts, unreadPosition

**UseCases**:
- `CalculateUnreadPositionUseCase`: 읽지 않은 글 인덱스 계산 (순수 함수)
- `EnterChannelUseCase`: 채널 진입 시 모든 데이터 원자적 로딩
- `UpdateReadPositionUseCase`: 읽음 위치 업데이트
- `GetReadPositionUseCase`: 읽음 위치 조회
- `GetBatchUnreadCountsUseCase`: 여러 채널의 읽지 않은 글 개수 조회

### Data Layer
**DataSources**:
- `ReadPositionRemoteDataSource`: 백엔드 API 호출
- `ReadPositionLocalDataSource`: SharedPreferences 캐시 (이미 존재)

**Repository**:
- `ReadPositionRepositoryImpl`: 로컬 캐시 우선 + 백엔드 동기화

### Presentation Layer
**Notifiers**:
- `ChannelEntryNotifier`: 채널 진입 시 EnterChannelUseCase 호출
- `ReadPositionNotifier`: 디바운싱된 읽음 처리 (200ms)
- `UnreadBadgeNotifier`: 배치 갱신

**Widgets**:
- `ChannelView`: channelEntryProvider 감시 (수정)
- `PostList`: 자동 스크롤 (수정)
- `PostItemWithTracking`: VisibilityDetector로 읽음 추적 (신규)
- `UnreadDivider`: 읽지 않은 글 구분선 (신규)

## 구현 로드맵 요약

### Phase 1: Domain Layer (3일)
Domain 엔티티, Repository 인터페이스, UseCase 구현 및 단위 테스트 작성. 순수 함수로 계산 로직을 구현하여 테스트 가능성 확보.

### Phase 2: Data Layer (2일)
DataSource 구현 (Remote/Local), Repository 구현, DTO ↔ Entity 매핑. 통합 테스트로 API 통신 검증.

### Phase 3: Presentation Layer (5일)
Notifier 구현, Widget 수정/추가, Widget 테스트. VisibilityDetector로 스크롤 기반 읽음 처리 구현.

### Phase 4: 워크스페이스 통합 (2일)
채널 목록에 배지 연결, 네비게이션 훅 추가. 채널/그룹/글로벌 네비게이션 전환 시 배치 갱신.

### Phase 5: 최적화 및 검증 (3일)
성능 프로파일링, 메모리 누수 확인, E2E 테스트 작성, 문서 업데이트.

## 이전 실패 원인 회피 전략

### 1. Race Condition 방지
**문제**: 읽음 위치 로딩과 게시글 로딩이 독립적으로 실행되어 PostList가 읽음 위치 없이 먼저 렌더링됨.

**해결책**: `EnterChannelUseCase`가 권한, 읽음 위치, 게시글을 `Future.wait`로 병렬 로딩 후, `CalculateUnreadPositionUseCase`로 계산. ChannelView는 모든 데이터 준비 완료 후에만 PostList 렌더링.

### 2. 계산 누락 방지
**문제**: AsyncNotifier 전환 시 `_firstUnreadPostIndex` 계산 로직이 완전히 누락됨.

**해결책**: Domain Layer의 `CalculateUnreadPositionUseCase`가 순수 함수로 계산 보장. `UnreadPositionResult`에 `firstUnreadIndex` 포함하여 Presentation Layer로 전달.

### 3. 아키텍처 위반 방지
**문제**: PostList 위젯이 836줄로 비대, WorkspaceStateProvider가 1635줄로 God Object.

**해결책**: 파일당 100줄 제한, 각 Provider는 1개 책임만. ChannelEntryNotifier, ReadPositionNotifier, UnreadBadgeNotifier로 분리.

## 관련 문서

- [체크리스트](../../workflows/unread-posts-checklist.md) - Phase별 실행 체크리스트
- [Post 리팩터링 마스터플랜](../../workflows/post-refactoring-masterplan.md) - Clean Architecture 마이그레이션
- [프론트엔드 구현 가이드](README.md) - 전체 프론트엔드 가이드 인덱스
- [3-Layer 아키텍처 가이드](../backend/three-layer-architecture.md) - 아키텍처 원칙
