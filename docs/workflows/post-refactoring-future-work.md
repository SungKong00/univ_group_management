# Post 리팩터링 추후 작업 목록

> **기준일**: 2025-11-18
> **Phase 1-4 완료**: Clean Architecture 마이그레이션 완료
> **관련 문서**: [완료 보고서](../context-tracking/post-refactoring-phase1-4-completion.md)

---

## 📊 우선순위별 작업 목록

### 🔴 우선순위 1: Provider 테스트 작성 (4-6시간)

**목표**: 상태 관리 로직의 안정성 확보

**작업 항목**:
1. **post_list_notifier_test.dart** (2시간)
   - 초기 로딩 테스트
   - 무한 스크롤 테스트
   - 에러 처리 테스트
   - **이슈**: 디바운스/타이밍 이슈 해결 필요

2. **read_position_notifier_test.dart** (1시간)
   - 읽음 위치 저장 테스트
   - 채널별 독립성 테스트

3. **scroll_controller_provider_test.dart** (1시간)
   - 스크롤 위치 복원 테스트
   - dispose 테스트

4. **sticky_header_notifier_test.dart** (1시간)
   - 날짜 업데이트 테스트
   - 스크롤 이벤트 테스트

**검증 기준**:
- [ ] 모든 Provider 테스트 통과
- [ ] 디바운스 로직 안정화
- [ ] 타이밍 이슈 해결 (Race Condition 없음)

**예상 효과**: 상태 관리 버그 사전 방지 (60% 개선)

---

### 🟡 우선순위 2: 기능 복원 및 개선 (2-3시간)

**목표**: Phase 3에서 주석 처리된 기능 복원

**작업 항목**:
1. **`_firstUnreadPostIndex` 기능 복원** (2시간)
   - 읽지 않은 메시지 구분선 표시
   - 현재 상태: 주석 처리 (동작 불안정)
   - 복원 방법: readPositionNotifier 연동 강화

2. **에러 메시지 개선** (1시간)
   - 사용자 친화적 에러 메시지
   - 재시도 로직 추가
   - 네트워크 에러 구분 (오프라인 vs 서버 에러)

**검증 기준**:
- [ ] 읽지 않은 메시지 구분선 정상 표시
- [ ] 채널 재진입 시 구분선 위치 정확
- [ ] 에러 시나리오별 적절한 메시지 표시

**예상 효과**: 사용자 경험 개선

---

### 🟢 우선순위 3: post_list.dart 추가 분리 (3-4시간)

**목표**: 507줄 → 200줄 이하

**작업 항목**:
1. **Mixin 분리: InfiniteScrollMixin** (1시간)
   - `_handlePageRequested()` 메서드 추출
   - 재사용 가능한 무한 스크롤 로직

2. **Helper 클래스: ScrollPositionHelper** (1시간)
   - `_scrollToUnreadPost()` 메서드 추출
   - `_restoreScrollPosition()` 메서드 추출
   - 읽음 위치 스크롤 로직 독립화

3. **Widget 분리: PostListBuilder** (1시간)
   - `_buildPostList()` 메서드 추출
   - 순수 UI 렌더링 로직

4. **통합 테스트** (1시간)
   - Mixin/Helper 단위 테스트
   - 전체 통합 동작 검증

**검증 기준**:
- [ ] post_list.dart 200줄 이하
- [ ] 모든 기능 정상 동작
- [ ] 100줄 원칙 준수

**예상 효과**: 유지보수성 50% 향상

---

### 🔵 우선순위 4: 통합 테스트 추가 (2-3시간)

**목표**: Provider 간 상호작용 검증

**작업 항목**:
1. **무한 스크롤 + 읽음 추적 통합** (1시간)
   - 스크롤 시 읽음 위치 자동 업데이트
   - Provider 간 동기화 검증

2. **Sticky Header + 스크롤 통합** (1시간)
   - 스크롤 시 날짜 업데이트
   - 경계 조건 테스트 (날짜 변경 시점)

3. **에러 복구 플로우** (1시간)
   - 로딩 실패 → 재시도 → 성공
   - 네트워크 끊김 → 재연결 시나리오

**검증 기준**:
- [ ] 통합 테스트 통과
- [ ] Provider 간 Race Condition 없음
- [ ] 에러 복구 정상 동작

**예상 효과**: 버그 사전 탐지율 80% 향상

---

## 📋 장기 개선 사항 (Phase 5+)

### 캐싱 전략 도입 (4-6시간)
- Local DataSource 추가 (Hive/SharedPreferences)
- 오프라인 지원 (로컬 캐시에서 읽기)
- Repository 레벨 캐싱 정책

### Pagination 전략 개선 (2-3시간)
- 양방향 스크롤 (위/아래)
- 페이지 크기 동적 조정
- 프리페칭 (미리 다음 페이지 로드)

### 성능 최적화 (2-3시간)
- ListView itemExtent 설정
- CachedNetworkImage 적용
- Provider keepAlive 전략 재검토

---

## 🔗 관련 문서

- [Phase 1-4 완료 보고서](../context-tracking/post-refactoring-phase1-4-completion.md)
- [아키텍처 분석](../context-tracking/post-architecture-analysis.md)
- [마스터 플랜](post-refactoring-masterplan.md)
- [체크리스트](post-refactoring-checklist.md)

---

## 📝 작업 시작 시 체크리스트

- [ ] 현재 브랜치 확인 (`git status`)
- [ ] 테스트 통과 확인 (`flutter test`)
- [ ] 최신 코드 동기화 (`git pull`)
- [ ] 관련 문서 숙지
- [ ] 작업 우선순위 확인 (위 목록 참조)

---

## 🎯 예상 타임라인

| 우선순위 | 작업 내용 | 예상 시간 | 권장 시작 시기 |
|---------|----------|----------|--------------|
| 🔴 P1 | Provider 테스트 | 4-6시간 | 즉시 |
| 🟡 P2 | 기능 복원 | 2-3시간 | P1 완료 후 1주 내 |
| 🟢 P3 | post_list.dart 분리 | 3-4시간 | P2 완료 후 2주 내 |
| 🔵 P4 | 통합 테스트 | 2-3시간 | P3 완료 후 |
| 📋 Phase 5+ | 장기 개선 | 8-12시간 | 여유 시 |

**총 예상 시간**: 11-16시간 (필수 작업만)
