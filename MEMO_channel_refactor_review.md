# MEMO.md 리팩터링 설계 평가

## 1. 개요
- **대상 문서**: `MEMO.md` (2025-11-11 업데이트)
- **목표**: 제안된 채널 스크롤/읽음 처리 리팩터링 방향이 현행 코드, 스펙, 문서와 부합하는지 검토
- **참조 컨텍스트**
  - `frontend/lib/presentation/widgets/post/post_list.dart`
  - `frontend/lib/presentation/providers/workspace_state_provider.dart`
  - `docs/ui-ux/pages/workspace-channel-view.md`
  - `specs/002-workspace-bugs-fix/spec.md`, `plan.md`

## 2. 타당하게 짚은 문제
| 항목 | 근거 | 평가 |
| --- | --- | --- |
| 무한 스크롤 후 읽음 인덱스 미갱신 | `post_list.dart:262-320` | ✅ `_firstUnreadPostIndex`가 초기 계산 이후 갱신되지 않아 재진입 시 잘못된 위치로 이동 |
| Sticky Header 가림 현상 | `post_list.dart:241-265`, `332-398` | ✅ 헤더 높이를 고려하지 않아 읽지 않은 경계선이 헤더 뒤에 숨음 |
| Race condition 가능성 | `post_list.dart:160-217` | ⚠️ `_waitForReadPositionData`는 타임아웃 기반 임시 해결책으로, 안정적 시퀀싱이 필요함 |

## 3. 보완이 필요한 제안
| 제안 | 문제점/리스크 | 근거 |
| --- | --- | --- |
| `PostListController`, `ReadPositionManager`, `VisibilityTracker` 도입 | Riverpod `WorkspaceStateNotifier`가 이미 채널 전환, 읽음 저장, 배지 업데이트를 담당하고 있어 책임 중복 및 상태 불일치 가능 | `workspace_state_provider.dart:880-1015` |
| Post ID 기반 AutoScroll / Flat List 재구성 | `scroll_to_index`는 0..N-1 인덱스를 기준으로 동작. 날짜별 그룹 해체 시 기존 UX(Sticky Header) 재구현 필요, 정확도 보장 어려움 | `post_list.dart:512-568` |
| Sticky Header 높이를 24px 상수로 보정 | `DateDivider`는 테마와 IntrinsicHeight에 따라 높이가 변동 → 상수 사용 시 접근성/로케일 변경에서 틀어짐 | `date_divider.dart:1-52` |
| Visibility 50% + 500ms 조건 | 긴 게시글은 50% 임계값을 만족하지 못해 읽음 처리 불가. 현재 30% + 200ms 디바운스가 spec 요구("즉시 위치")와 더 부합 | `post_list.dart:408-444`, `specs/002-workspace-bugs-fix/spec.md:140-164` |
| 5초 주기 읽음 위치 저장 | 스펙 FR-011은 “채널 이탈 시” 배지 업데이트를 규정. 주기 저장 시 서버 상태와 배지 표시가 어긋나고 API 부하 증가 | `specs/002-workspace-bugs-fix/spec.md:131-139`, `plan.md:28-40` |

## 4. 추천 실행 순서
1. **긴급 수정 세트**  
   - `_firstUnreadPostIndex` 재계산 추가  
   - Sticky Header 오프셋 보정 (측정 기반)  
   - `_anchorLastPostAtTop()`에서 날짜 헤더 전체 높이 고려  
   - → 관련 위젯/통합 테스트 작성 (dart-flutter MCP)
2. **Race condition 근본 해결**  
   - `WorkspaceStateNotifier.selectChannel()` 시퀀스는 이미 `await`을 사용하므로, PostList 진입 전에 `lastReadPostIdMap`이 채워졌는지 플래그로 전달하는 방식을 검토
3. **Sticky Header 정확도 개선**  
   - 상수 대신 각 헤더 `RenderBox` 높이를 누적하거나 `SliverOverlapAbsorber` / `NestedScrollView` 패턴 탐색
4. **추가 리팩터링 검토**  
   - Riverpod 계층과 충돌하지 않는 선에서 controller/manager 필요성을 재평가  
   - Flat List 구조 전환 시 UI/UX 명세(`workspace-channel-view.md:11-45`) 유지 방안 구체화

## 5. 결론 및 재평가
- 반복된 소규모 패치가 실패했다는 배경을 고려하면, **구조 자체를 갈아엎어 불안 요인을 제거하려는 전략은 타당**합니다. 다만 새 구조가 기존 Riverpod 계층, Sticky Header UX, 스펙 요구(FR-011 등)와 충돌하지 않도록 아래 가드레일을 반드시 포함하세요.
  1. **상태 책임 일원화**: 새 컨트롤러를 만들더라도 `WorkspaceStateNotifier`를 대체/위임 관계로 두어 이중 관리가 발생하지 않게 할 것.
  2. **UI 스펙 유지**: Flat List 전환 시에도 날짜별 Sticky Header와 “즉시 위치” 요구를 만족시키는 렌더링 전략을 선행 설계로 문서화.
  3. **서버 부하/배지 정책**: 주기 저장이 필요하면 `specs/002-workspace-bugs-fix/spec.md`와 백엔드 팀 합의를 통해 정책을 갱신하고, 배지 갱신 기준도 함께 바꿀 것.
- 위 가드레일이 충족되는 한, PostList 영역을 전면 재구조화하는 접근은 “수십 번 시도 후 실패” 상황을 타개할 현실적 선택입니다. 단계별로 설계→문서 업데이트→구현→MCP 테스트 순서를 유지하며 진행해 주세요.
