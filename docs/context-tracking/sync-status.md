# 문서 동기화 상태 (Sync Status)

이 파일은 각 컨텍스트 문서의 현재 동기화 상태를 추적합니다.

## 📊 전체 현황

**마지막 업데이트**: 2025-10-17 (장소 예약 API 문서 동기화)
**총 문서 수**: 43개
**동기화 완료**: 43개 (100%)
**업데이트 필요**: 0개 (0%)

---

## 📁 디렉토리별 상태

### `/` - 최상위 문서
| 파일명 | 상태 | 마지막 동기화 | 관련 커밋 | 비고 |
|--------|------|---------------|-----------|------|
| `GEMINI.md` | ✅ 최신 | 2025-10-05 | `현재` | 에이전트 마스터 워크플로우 |

### `/docs/concepts/` - 도메인 개념 문서
| 파일명 | 상태 | 마지막 동기화 | 관련 커밋 | 비고 |
|--------|------|---------------|-----------|------|
| `domain-overview.md` | ✅ 최신 | 2025-10-06 | `현재` | 캘린더 도메인 추가 |
| `group-hierarchy.md` | ✅ 최신 | 2024-09-25 | `f2ca868` | |
| `permission-system.md` | ✅ 최신 | 2025-10-13 | `현재` | 서비스 레벨 권한 확인 로직 반영 |
| `workspace-channel.md` | ✅ 최신 | 2024-09-28 | `86b8cf6` | |
| `user-lifecycle.md` | ✅ 최신 | 2024-09-28 | `86b8cf6` | |
| `calendar-system.md` | ✅ 최신 | 2025-10-12 | `현재` | API 권한 v1.4 업데이트, 반복 일정 생성 UI 설계 추가 |
| `calendar-design-decisions.md` | ✅ 최신 | 2025-10-12 | `현재` | DD-CAL-001 권한 1개로 재단순화, DD-CAL-002 UI 설계 명확화 |
| `calendar-place-management.md` | ✅ 최신 | 2025-10-12 | `현재` | 멤버십 기반 예약 권한, CALENDAR_MANAGE 통합 |
| `recruitment-system.md` | ✅ 최신 | 2025-10-06 | `현재` | JPA 최적화, 엔티티 구조 변경 반영 |
| `channel-permissions.md` | ✅ 최신 | 2024-09-25 | `f2ca868` | |

### `/docs/implementation/` - 구현 가이드
| 파일명 | 상태 | 마지막 동기화 | 관련 커밋 | 비고 |
|--------|------|---------------|-----------|------|
| `backend-guide.md` | ✅ 최신 | 2025-10-09 | `현재` | 로컬 개발 환경 가이드 추가 |
| `frontend-guide.md` | ✅ 최신 | 2025-10-06 | `현재` | 채팅형 스크롤 패턴 추가 |
| `frontend-workspace-guide.md` | ✅ 최신 | 2025-10-10 | `현재` | 워크스페이스/네비게이션 구현 패턴 가이드 |
| `component-reusability-guide.md` | ✅ 최신 | 2025-10-07 | `현재` | SlidePanel, PostPreviewWidget 추가 |
| `frontend-implementation-status.md` | ✅ 최신 | 2025-10-08 | `현재` | 워크스페이스 진입 로직 개선 반영 |
| `workspace-refactoring-status.md` | ✅ 최신 | 2025-10-07 | `현재` | Phase 1-10 진행 상황 추적 문서 (신규) |
| `api-reference.md` | ✅ 최신 | 2025-10-17 | `현재` | 장소 예약 API 구현 상태 반영 |
| `database-reference.md` | ✅ 최신 | 2025-10-12 | `현재` | recurrence_rule JSON 형식 예시 추가 (SQL DDL 및 JPA 엔티티) |

### `/docs/ui-ux/concepts/` - UI/UX 개념
| 파일명 | 상태 | 마지막 동기화 | 관련 커밋 | 비고 |
|--------|------|---------------|-----------|------|
| `design-system.md` | ✅ 최신 | 2025-10-09 | `현재` | 헤더 역할 표시 기능 추가 |
| `color-guide.md` | ✅ 최신 | 2024-09-28 | `86b8cf6` | |
| `responsive-design-guide.md` | ✅ 최신 | 2025-10-09 | `현재` | Medium 레이아웃 동작 정의 추가 |
| `form-and-interaction-components.md` | ✅ 최신 | 2024-09-28 | `86b8cf6` | |

### `/docs/ui-ux/pages/` - 페이지별 명세
| 파일명 | 상태 | 마지막 동기화 | 관련 커밋 | 비고 |
|--------|------|---------------|-----------|------|
| `authentication-pages.md` | ✅ 최신 | 2024-09-28 | `86b8cf6` | |
| `navigation-and-page-flow.md` | ✅ 최신 | 2025-10-07 | `현재` | 그룹 관리 페이지 상태 변경 방식 반영 |
| `workspace-pages.md` | ✅ 최신 | 2025-10-10 | `현재` | 그룹 관리 페이지 구현 상태 반영 |
| `home-page.md` | ✅ 최신 | 2024-09-28 | `86b8cf6` | |
| `channel-pages.md` | ✅ 최신 | 2025-10-07 | `현재` | 게시글 목록 Sticky Header UI 명세 추가 |
| `my-activity-page.md` | ✅ 최신 | 2024-09-28 | `86b8cf6` | |
| `recruitment-pages.md` | ✅ 최신 | 2024-09-28 | `86b8cf6` | |
| `group-admin-page.md` | ✅ 최신 | 2025-10-08 | `현재` | 접근 권한 업데이트 |

### `/docs/maintenance/` - 유지보수 가이드
| 파일명 | 상태 | 마지막 동기화 | 관련 커밋 | 비고 |
|--------|------|---------------|-----------|------|
| `group-management-permissions.md` | ✅ 최신 | 2025-10-08 | `현재` | 권한 이름 변경 반영 |

### `/docs/features/` - 기능별 개발 계획
| 파일명 | 상태 | 마지막 동기화 | 관련 커밋 | 비고 |
|--------|------|---------------|-----------|------|
| `personal-calendar-mvp.md` | ✅ 최신 | 2025-10-06 | `현재` | 개인 캘린더 구현 완료 |
| `group-calendar-development-plan.md` | ✅ 최신 | 2025-10-12 | `현재` | Phase 1-5 개발 계획 |
| `group-calendar-phase5-api-integration.md` | ✅ 최신 | 2025-10-12 | `현재` | API 연동 수정 완료 |
| `group-calendar-phase6-edit-delete.md` | ✅ 최신 | 2025-10-13 | `현재` | 수정/삭제 구현 완료 (신규) |
| `group-calendar-phase9-ui-improvement.md` | ✅ 최신 | 2025-10-13 | `현재` | UI 개선 계획 (Phase 6→9 변경) |
| `place-calendar-specification.md` | ✅ 최신 | 2025-10-17 | `현재` | 장소 예약 API 명세 동기화 |
| `place-calendar-phase2-frontend-basic.md` | ✅ 최신 | 2025-10-13 | `현재` | Phase 2 프론트엔드 상세 계획 (신규) |
| `place-calendar-phase3-usage-permission.md` | ✅ 최신 | 2025-10-13 | `현재` | Phase 3 예약 권한 신청 계획 (신규) |
| `calendar-integration-roadmap.md` | ✅ 최신 | 2025-10-13 | `현재` | 통합 로드맵 (신규) |

### `/docs/workflows/` - 개발 프로세스
| 파일명 | 상태 | 마지막 동기화 | 관련 커밋 | 비고 |
|--------|------|---------------|-----------|------|
| `development-flow.md` | ✅ 최신 | 2024-09-29 | `현재` | Git 전략 연동 완료 |
| `testing-strategy.md` | ✅ 최신 | 2025-10-06 | `현재` | 통합 테스트 패턴 추가 |

### `/docs/testing/` - 테스트 관리
| 파일명 | 상태 | 마지막 동기화 | 관련 커밋 | 비고 |
|--------|------|---------------|-----------|------|
| `test-data-reference.md` | ✅ 최신 | 2025-10-16 | `현재` | TestDataRunner 구조 및 사용자/그룹 정보 (신규) |

### `/docs/conventions/` - 컨벤션 (신규)
| 파일명 | 상태 | 마지막 동기화 | 관련 커밋 | 비고 |
|--------|------|---------------|-----------|------|
| `git-strategy.md` | ✅ 최신 | 2024-09-29 | `현재` | 신규 생성 |
| `commit-conventions.md` | ✅ 최신 | 2024-09-29 | `현재` | 신규 생성 |
| `pr-guidelines.md` | ✅ 최신 | 2024-09-29 | `현재` | 신규 생성 |
| `code-review-standards.md` | ✅ 최신 | 2024-09-29 | `현재` | 신규 생성 |

### `/docs/agents/` - 서브 에이전트
| 파일명 | 상태 | 마지막 동기화 | 관련 커밋 | 비고 |
|--------|------|---------------|-----------|------|
| `frontend-development-agent.md` | ✅ 최신 | 2024-09-29 | `현재` | 동적 문서 검토 기능 추가 |

### `/docs/troubleshooting/` - 문제 해결
| 파일명 | 상태 | 마지막 동기화 | 관련 커밋 | 비고 |
|--------|------|---------------|-----------|------|
| `permission-errors.md` | ✅ 최신 | 2024-09-25 | `f2ca868` | |
| `common-errors.md` | ✅ 최신 | 2025-10-09 | `현재` | DB/HTTP 에러 케이스 추가 |

### `/docs/context-tracking/` - 컨텍스트 추적 (신규)
| 파일명 | 상태 | 마지막 동기화 | 관련 커밋 | 비고 |
|--------|------|---------------|-----------|------|
| `context-update-log.md` | ✅ 최신 | 2025-10-13 | `현재` | 권한 로직 리팩토링 로그 추가 |
| `pending-updates.md` | ✅ 최신 | 2025-10-06 | `현재` | 컨트롤러 테스트 문서화 완료 기록 |
| `sync-status.md` | ✅ 최신 | 2025-10-09 | `현재` | 현재 파일 (변경사항 반영) |

---

## 🎯 상태별 분류

### ✅ 최신 상태 (43개)
모든 코드 변경사항이 반영되어 동기화된 문서들

**주요 업데이트 (2025-10-16)**:
- 테스트 데이터 관리 문서 신규 생성 (test-data-reference.md)
  - TestDataRunner 실행 순서 및 데이터 구조 명세
  - 테스트 사용자 3명 정보 (이메일, 소속, 권한)
  - 테스트 그룹 6개 정보 (기본 4개 + 커스텀 2개)
  - 테스트 시나리오별 활용 가이드
  - CLAUDE.md 네비게이션 추가

**주요 업데이트 (2025-10-13)**:
- 장소 캘린더 최종 설계 문서화 (10개 질문 답변 반영)
- Phase 2-3 상세 구현 계획 문서 신규 생성
- 예약 권한 신청 플로우 확정 (PlaceUsageGroup 활용)
- UI/UX 설계 구체화 (멀티 플레이스 뷰, 드롭다운 구조, 액션 버튼 배치)
- Phase 번호 충돌 해결 (Phase 6 → Phase 9 UI 개선)
- 장소 캘린더 Phase 1 완료 반영
- 통합 로드맵 문서 신규 생성
- 그룹 캘린더 Phase 6 수정/삭제 문서화

### 🔄 업데이트 진행 중 (0개)
없음

### ❌ 업데이트 필요 (0개)
없음

### ❓ 확인 필요 (0개)
없음
