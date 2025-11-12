# Known Issues - 002-workspace-bugs-fix

**Date**: 2025-11-10
**Status**: Documented for Future Improvement

## Overview

이 문서는 002-workspace-bugs-fix 구현 중 발견된 알려진 이슈들을 추적합니다. 이슈들은 기능 동작에는 영향을 주지 않지만, 사용자 경험 개선이 필요한 항목들입니다.

---

## Issue 1: 스크롤 포지션 초기화 오류 (새 게시글 작성 후)

### 발견 일시
- **Date**: 2025-11-10
- **Context**: 테스트 데이터 이후 첫 게시글 작성 시나리오

### 현상
- 읽지 않은 글 구분선(Unread Message Divider)은 정확히 표시됨
- 그러나 스크롤 위치가 읽지 않은 글 경계선이 아닌 **가장 최신 글(맨 아래)**로 이동
- 사용자가 의도한 위치(읽지 않은 글 시작점)에서 읽을 수 없음

### 재현 단계
1. 채널에 읽음 처리된 게시글 여러 개 존재
2. 사용자가 새로운 게시글 작성
3. 채널 재진입 또는 새로고침
4. **Expected**: 스크롤이 새 게시글(읽지 않은 글)로 이동
5. **Actual**: 스크롤이 가장 최신 글(맨 아래)로 이동

### 원인 분석
- **Root Cause**: 새로운 게시글 추가 시 읽음 위치(read position) 갱신 로직 미흡
- **Affected Files**:
  - `frontend/lib/core/utils/read_position_helper.dart` - 읽음 위치 계산 로직
  - `frontend/lib/presentation/widgets/post/post_list.dart` - 스크롤 위치 결정 로직
- **Possible Culprit**:
  - 새 게시글 작성 후 `lastReadPostId`가 갱신되지 않거나
  - 스크롤 타겟 결정 시 "최신 글 우선" 로직이 작동하는 것으로 추정

### 영향도
- **Priority**: Medium
- **Severity**: Low (기능은 정상 작동, 편의성 저하)
- **User Impact**: 사용자가 수동으로 스크롤하여 읽지 않은 글을 찾아야 함
- **Frequency**: 첫 게시글 작성 시나리오에서만 발생 (비교적 드묾)

### 해결 방향
1. **Option A**: `read_position_helper.dart`의 읽음 위치 갱신 로직 검토
   - 새 게시글 작성 후 `lastReadPostId` 업데이트 추가
   - 작성자의 경우 자동으로 읽음 처리할지 결정 필요

2. **Option B**: `post_list.dart`의 스크롤 타겟 결정 로직 개선
   - "읽지 않은 글 있음" 조건을 더 우선순위 높게 처리
   - 최신 글로 스크롤하는 폴백 로직 조건 재검토

3. **Option C**: 읽음 위치 API 응답 구조 검토
   - 백엔드에서 새 게시글 작성 시 `lastReadPostId` 자동 갱신 여부 확인
   - 프론트엔드-백엔드 읽음 위치 동기화 개선

### 예상 작업량
- **Estimated Effort**: 2-4시간
- **Testing Required**:
  - Unit test: 새 게시글 작성 후 읽음 위치 갱신 검증
  - Widget test: 스크롤 타겟이 읽지 않은 글로 설정되는지 검증
  - Integration test: 전체 시나리오 End-to-End 테스트

### 관련 코드 참조
- **읽음 위치 계산**: `frontend/lib/core/utils/read_position_helper.dart`
  - `findFirstUnreadGlobalIndex()` 메서드
  - `calculateUnreadCount()` 메서드

- **스크롤 위치 결정**: `frontend/lib/presentation/widgets/post/post_list.dart`
  - `_determineScrollTarget()` 메서드 (Line ~200-250)
  - `_scrollToUnreadPost()` 메서드
  - `_anchorLastPostAtTop()` 메서드

- **읽음 위치 업데이트**: `frontend/lib/presentation/providers/workspace_state_provider.dart`
  - `selectChannel()` 메서드 - 채널 전환 시 읽음 위치 저장

### 차단 사항
- **Blockers**: None (독립적으로 수정 가능)
- **Dependencies**: None

### 추천 우선순위
- **When to Fix**: Next sprint (post-release)
- **Rationale**:
  - 현재 기능은 정상 작동 중
  - 읽지 않은 글 구분선은 정확히 표시됨
  - 사용자가 수동 스크롤로 회피 가능
  - 릴리즈 블로커가 아님

---

## Future Sections (추가 예정)

### Issue 2: [Title TBD]
(추가 이슈 발견 시 여기에 문서화)

---

## Related Documentation

- **Spec**: [spec.md](./spec.md) - Feature specification
- **Tasks**: [tasks.md](./tasks.md) - Implementation tasks
- **Test Failures**: [MEMO_test_failures.md](./MEMO_test_failures.md) - Test status
- **Code Cleanup**: [MEMO_code_cleanup.md](./MEMO_code_cleanup.md) - Cleanup report

---

## Notes

- 이 문서는 Speckit 작업용 임시 문서로, 100줄 원칙 및 컨텍스트 추적에서 제외됩니다
- PR 병합 후 중요한 이슈는 `docs/troubleshooting/` 또는 GitHub Issues로 이관 권장
- 우선순위 결정: P1(즉시) > P2(다음 스프린트) > P3(백로그)
