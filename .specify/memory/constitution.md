# 대학 그룹 관리 시스템 프로젝트 헌법

<!--
Sync Impact Report
==================
Version: 1.0.0 → Initial ratification
Modified principles: N/A (new constitution)
Added sections: All sections (initial creation)
Removed sections: N/A
Templates status:
  ✅ plan-template.md - No updates required (principles align with planning approach)
  ✅ spec-template.md - No updates required (principles align with spec requirements)
  ✅ tasks-template.md - No updates required (principles align with task structure)
  ✅ agent-file-template.md - No updates required
  ✅ checklist-template.md - No updates required
Follow-up TODOs: None
-->

## 비전 및 범위 (Vision & Scope)

### 프로젝트 미션
대학 조직(학과, 동아리, 연구실), 장비, 일정, 권한을 통합적으로 관리하는 엔터프라이즈급 협업 플랫폼을 구축한다.

### 핵심 가치
1. **일관된 권한 시스템**: RBAC + Individual Override 패턴으로 모든 기능에 통합된 권한 체계 적용
2. **명확한 책임 분리**: 3-Layer Architecture를 통한 계층별 단일 책임 원칙 준수
3. **테스트 가능한 설계**: 60/30/10 테스트 피라미드 기반의 검증 가능한 시스템
4. **문서 중심 개발**: 100줄 원칙을 따르는 컨텍스트 문서로 지식 관리

### 범위
- **포함**: 그룹 계층 관리, 워크스페이스/채널 시스템, 모집 시스템, 멤버 관리, 캘린더 통합, 권한 관리
- **제외**: 실시간 채팅, 화상 회의, 파일 스토리지 (향후 확장 고려)

## 핵심 원칙 (Core Principles)

### I. 3-Layer Architecture (비협상)
**원칙**:
- Controller Layer: HTTP 요청/응답 처리, DTO 변환, 인증 검증만 수행
- Service Layer: 비즈니스 로직 실행, 트랜잭션 관리, 권한 검증 수행
- Repository Layer: 데이터 접근, JPQL/Native 쿼리, 영속성 관리

**강제 사항**:
- Controller는 Service를 직접 호출하고, Service만 Repository를 호출한다
- Service 간 의존은 허용하되, 순환 의존은 절대 금지
- 모든 Service 메서드는 `@Transactional` 명시 (readOnly = true/false)
- Repository는 JPA `JpaRepository`를 상속하고, 커스텀 쿼리는 `@Query` 사용

**검증**:
- PR 리뷰 시 계층 위반 사항을 최우선 검토
- 아키텍처 다이어그램을 `docs/implementation/backend/architecture.md`에 유지

### II. 표준 응답 형식 (비협상)
**원칙**:
- 모든 REST API는 `ApiResponse<T>` 포맷으로 응답한다
- 성공: `{ "success": true, "data": T, "error": null, "timestamp": "..." }`
- 실패: `{ "success": false, "data": null, "error": { "code": "...", "message": "..." }, "timestamp": "..." }`

**강제 사항**:
- Controller는 항상 `ApiResponse.success(data)` 또는 `ApiResponse.error(code, message)` 반환
- `GlobalExceptionHandler`에서 모든 예외를 `ApiResponse` 형식으로 변환
- 에러 코드는 `ErrorCode` enum으로 중앙 관리

**검증**:
- API 통합 테스트에서 응답 형식 검증 필수
- Swagger/OpenAPI 스키마에 `ApiResponse` 구조 명시

### III. RBAC + Override 권한 시스템 (비협상)
**원칙**:
- **그룹 권한**: RBAC 기반 역할-권한 매핑 (시스템 역할 3개 + 커스텀 역할)
- **채널 권한**: Permission-Centric 바인딩 (권한별로 허용 역할 지정)
- **개인 권한**: Individual Override로 특정 사용자에게 예외 권한 부여 (향후 구현)

**강제 사항**:
- 모든 그룹 관리 API는 `@PreAuthorize("@groupPermissionEvaluator.hasPermission(...)")` 필수
- 시스템 역할(그룹장, 교수, 멤버)은 수정/삭제 금지 (플랫폼 안정성)
- 채널 권한 변경 시 캐시 무효화 이벤트 발행 필수
- 권한 매트릭스는 `docs/concepts/permission-system.md`에 유지

**검증**:
- 권한 테스트는 Permission Matrix 기반으로 모든 역할 조합 검증
- 권한 변경 시 영향받는 API 목록을 트러블슈팅 문서에 기록

### IV. 문서화 100줄 원칙
**원칙**:
- 모든 컨텍스트 문서는 100줄 이내로 작성 (예외: API/DB 레퍼런스, 테스트 전략, 개발 계획)
- 긴 내용은 여러 파일로 분할하고 상호 참조 링크 유지
- 코드 참조는 파일 경로 + 클래스/함수명만 명시 (상세 구현 코드 포함 금지)

**강제 사항**:
- `concepts/`: 비즈니스 개념, 코드 참조 없음
- `implementation/`: 구현 가이드, 파일 경로 + 함수명만
- `backend/`: 기술 설계, 파일 경로 + 클래스명만
- `CLAUDE.md`: 마스터 인덱스, 모든 문서 링크 관리

**검증**:
- 문서 커밋 전 `markdown-guidelines.md` 체크리스트 확인 필수
- PR에 문서 변경 시 관련 문서 동기화 여부 검토

### V. 테스트 피라미드 60/30/10
**원칙**:
- **통합 테스트 (60%)**: 실제 Spring Context 로드, Service + Repository 통합 검증
- **단위 테스트 (30%)**: 복잡한 비즈니스 로직, Mock 기반 격리 테스트
- **E2E 테스트 (10%)**: 핵심 사용자 플로우 (향후 Playwright)

**강제 사항**:
- 모든 Service는 통합 테스트 필수 (`@SpringBootTest` + `@Transactional`)
- 권한 관련 기능은 Permission Matrix 기반 테스트 커버리지 90% 이상
- API 테스트는 `@SpringBootTest(webEnvironment = MOCK)` + `MockMvc` 사용
- 테스트 데이터는 `TestDataFactory`로 중앙 관리, 고유 식별자 생성 (`uniqueEmail()` 등)

**검증**:
- CI/CD에서 테스트 커버리지 보고서 생성 (JaCoCo)
- Service Layer 90%, Controller Layer 80%, Repository Layer 70% 목표

### VI. Flutter MCP 표준 (비협상)
**원칙**:
- **Flutter 개발 시 flutter-mcp-service를 필수로 사용**하여 코드 분석, 도구 호출, 캐시 관리 수행
- **dart&flutter-mcp를 통해 검증 및 디버깅** 진행 (`flutter_analyze`, `flutter_status` 등)
- 로컬 명령(`flutter run`, `dart analyze` 등) 직접 호출 금지

**강제 사항**:
- 모든 Flutter 코드 변경은 MCP를 통해 분석 및 검증
- PR에 MCP 로그 포함 필수 (flutter_analyze, flutter_status)
- MCP 미사용 코드는 검증 절차에서 자동 거부

**검증**:
- PR 템플릿에 MCP 로그 첨부 항목 추가
- CI/CD에서 MCP 기반 검증 스크립트 실행

### VII. 프론트엔드 통합 원칙
**원칙**:
- **디자인 시스템**: Toss 디자인 철학 기반 토큰 시스템 (AppColors, AppSpacing, AppTypography)
- **상태 관리**: Riverpod 기반 Unified Provider 패턴, LocalFilterNotifier
- **인증 처리**: Google OAuth + JWT 자동 갱신, 401/403 통합 에러 핸들링
- **API 통합**: `ApiResponse<T>` 구조에 맞춘 타입 안전 파싱

**강제 사항**:
- 모든 UI 컴포넌트는 디자인 토큰 사용 (하드코딩 금지)
- API 호출은 Provider를 통해서만 수행, 직접 HTTP 호출 금지
- 재사용 컴포넌트는 `docs/implementation/frontend/reusable-components-guide.md`에 등록

**검증**:
- UI 리뷰 시 디자인 토큰 사용 여부 확인
- API 통합 시 에러 핸들링 시나리오 테스트 필수

## 보안 및 성능 기준 (Security & Performance Standards)

### 보안 요구사항
- **인증**: Google OAuth 2.0 ID Token 검증 필수
- **인가**: JWT Access Token (1시간) + Refresh Token (7일) 기반
- **권한 검증**: 모든 변경 작업은 `@PreAuthorize` + `PermissionEvaluator` 2단계 검증
- **SQL Injection**: JPA + Named Parameter 사용, Native Query는 최소화
- **XSS**: 프론트엔드에서 HTML 이스케이프 처리, Sanitizer 적용

### 성능 기준
- **N+1 쿼리 해결**: Fetch Join 또는 2단계 조회 (ID 조회 → IN 절 상세 조회)
- **캐싱**: 권한 정보는 Spring Cache (`@Cacheable`), 이벤트 기반 무효화
- **페이징**: 모든 목록 조회는 `Pageable` 기반, 기본 20개
- **응답 시간**: API 95 percentile 1초 이내 (향후 모니터링)

## 개발 워크플로우 (Development Workflow)

### Git 전략
- **브랜치 전략**: GitHub Flow (main + feature branches)
- **커밋 컨벤션**: Conventional Commits (`feat:`, `fix:`, `refactor:`, `docs:`, `test:`)
- **PR 규칙**:
  - 코드 리뷰 1명 이상 승인 필수
  - CI 통과 필수 (테스트, 린트, 빌드)
  - 관련 문서 업데이트 확인

### 컨텍스트 추적
- **변경 로그**: `docs/context-tracking/context-update-log.md`에 커밋마다 기록
- **동기화 상태**: `docs/context-tracking/sync-status.md`에서 문서 동기화율 관리
- **문서 업데이트**: 코드 변경 시 관련 문서 함께 업데이트 필수

### 리뷰 체크리스트
- [ ] 3-Layer Architecture 준수
- [ ] `ApiResponse<T>` 형식 사용
- [ ] 권한 검증 로직 포함
- [ ] 테스트 커버리지 목표 달성
- [ ] 문서 업데이트 완료
- [ ] 커밋 메시지 컨벤션 준수

## 거버넌스 (Governance)

### 헌법 우선순위
이 헌법은 모든 개발 프랙티스, 가이드라인, 개인 선호도보다 우선한다. 헌법과 충돌하는 코드나 문서는 수정되어야 한다.

### 개정 절차
1. **제안**: GitHub Issue로 개정 제안 제출, 근거와 영향 범위 명시
2. **논의**: 팀 리뷰 및 의견 수렴 (최소 3일)
3. **승인**: 팀 합의 후 헌법 버전 업데이트
4. **마이그레이션**: 영향받는 코드/문서 업데이트 계획 수립 및 실행

### 버전 관리
- **MAJOR**: 핵심 원칙 삭제/재정의, 하위 호환성 파괴
- **MINOR**: 새 원칙 추가, 섹션 확장
- **PATCH**: 표현 개선, 오타 수정

### 준수 검증
- **PR 리뷰**: 모든 PR은 헌법 준수 여부 검증
- **정기 감사**: 분기별 코드베이스 헌법 준수 상태 점검
- **위반 처리**: 헌법 위반 코드는 우선 순위 높음으로 리팩토링

### 런타임 가이던스
일상적인 개발 가이던스는 `CLAUDE.md`를 참조한다. 헌법은 변경 불가능한 원칙만 정의하며, 구현 세부사항은 각 도메인 문서에서 관리한다.

**Version**: 1.0.0 | **Ratified**: 2025-11-09 | **Last Amended**: 2025-11-09
