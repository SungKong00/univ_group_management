---
description: 적절한 서브에이전트를 자동 선택하여 개발 진행
argument-hint: [개발하고 싶은 기능 설명]
---

# 🎯 서브에이전트 기반 개발

사용자 요청을 분석하여 **적절한 서브에이전트를 즉시 선택하고 호출**하세요.

## 1️⃣ 요청 분석 및 서브에이전트 선택

사용자 요청: **$ARGUMENTS**

위 요청을 분석하여 다음 중 가장 적절한 서브에이전트를 선택하세요:

### 선택 기준

**frontend-specialist** - 프론트엔드 UI/UX 개발
- Flutter/React 컴포넌트 개발
- 페이지 레이아웃/디자인 구현
- 반응형 디자인, 사용자 인터페이스

**frontend-debugger** - 프론트엔드 에러 디버깅
- UI 깨짐, 위젯 렌더링 오류
- 상태 관리(Provider, Zustand) 문제
- 성능 저하, 버벅임 현상 해결
- 권한 관련 UI 표시 오류 수정

**backend-architect** - 백엔드 시스템 개발
- Spring Boot REST API 개발
- 비즈니스 로직, 서비스 계층
- 데이터베이스 스키마 설계
- 3-layer 아키텍처

**backend-debugger** - 백엔드 에러 디버깅
- API 실패, 5xx 에러 분석
- 비즈니스 로직 버그 수정
- 데이터베이스 관련 예외 처리
- 보안/권한 관련 에러 해결

**api-integrator** - API 연동 작업
- 프론트엔드-백엔드 연결
- HTTP 클라이언트 통합
- 인증 플로우, 토큰 관리

**database-optimizer** - 데이터베이스 최적화
- JPA 쿼리 최적화
- N+1 문제 해결
- 인덱스 설계, 성능 개선

**permission-engineer** - 권한 시스템
- RBAC 설계/구현
- 권한 체크 로직
- 권한 에러 디버깅

**test-automation-specialist** - 테스트 자동화
- 통합 테스트 작성
- E2E 테스트 구현
- 권한 기반 테스트 시나리오

**context-manager** - 문서 관리/동기화
- 커밋 요청이 들어왔을 경우 커밋 전에 호출
- 프로젝트 문서 업데이트
- 컨텍스트 일관성 유지
- 문서 구조 최적화

## 2️⃣ Task Tool 호출

선택한 서브에이전트를 즉시 호출하세요:

```
Task tool:
- subagent_type: [선택한 에이전트 타입]
- description: [3-5단어 작업 요약]
- prompt: """
사용자 요청:
$ARGUMENTS

해당 서브에이전트 가이드(docs/agents/)의 워크플로우를 따라 작업을 수행하세요.
"""
```

## 📚 참조

서브에이전트는 각자의 가이드를 따릅니다:
- [docs/agents/](../../docs/agents/) - 서브에이전트별 상세 워크플로우
- [docs/conventions/](../../docs/conventions/) - 개발 컨벤션
- [docs/workflows/](../../docs/workflows/) - 개발 프로세스
- [CLAUDE.md](../../CLAUDE.md) - 프로젝트 전체 컨텍스트

---

**이제 요청을 분석하고 적절한 서브에이전트를 호출하세요.**
