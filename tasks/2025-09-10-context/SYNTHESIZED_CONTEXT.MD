# SYNTHESIZED CONTEXT - 프로젝트 개발 환경 구성

## 작업 목표 및 제약사항

### 주요 목표
- 프로젝트 개발 환경 구성 및 Context 파일 정리
- Context 디렉토리 구조 정리 및 필수 문서 생성
- 프로젝트 아키텍처 및 개발 규칙 문서 정리
- 백엔드/프론트엔드 개발 환경 검증

### 성공 기준
- Context 디렉토리의 권장 문서 구조 구현
- 백엔드(Spring Boot + Kotlin) 및 프론트엔드(Flutter) 환경 검증
- AI Agent 워크플로우 기반 개발 프로세스 정립

## 프로젝트 아키텍처

### 기술 스택
**백엔드 (Spring Boot + Kotlin)**
- Spring Boot 3.5.5 + Kotlin 1.9.25
- Spring Data JPA, Spring Security, OAuth2 Client
- OpenAPI 3 (Swagger UI)
- H2 (로컬/테스트), PostgreSQL (프로덕션)
- 코드 품질: Ktlint, Detekt

**프론트엔드 (Flutter)**
- 현재 빈 디렉토리 상태 (향후 Flutter 프로젝트 설정 필요)

**AI Agent 워크플로우**
- Gemini CLI: 컨텍스트 종합 및 작업 패키지 관리
- Claude Code: 개발 및 리팩토링
- 작업 패키지 기반 개발 (`tasks/` 디렉토리)

## 관련 모듈 및 파일

### 현재 존재하는 핵심 파일
- `backend/build.gradle`: Kotlin/Spring Boot 의존성 정의
- `backend/src/main/kotlin/org/castlekong/backend/BackendApplication.kt`: 메인 애플리케이션
- `context/README.md`: 정적 지식베이스 가이드
- `docs/ai-agent-workflow.md`: 워크플로우 명세

### 생성해야 할 Context 문서
- `context/architecture.md`: 시스템 아키텍처 개요
- `context/api-conventions.md`: REST API/DTO 규칙
- `context/coding-standards.md`: 코드 스타일 및 네이밍 규칙
- `context/security.md`: 인증/인가, 보안 정책
- `context/testing.md`: 테스트 전략 및 규칙

## 위험요소 및 고려사항

### 개발 환경 위험요소
- 프론트엔드 Flutter 환경이 아직 설정되지 않음
- 데이터베이스 연결 설정 미완료
- 보안 설정 (OAuth2, JWT) 미구현

### 워크플로우 위험요소
- Gemini CLI의 자동 컨텍스트 생성 기능이 완전히 설정되지 않음
- 작업 패키지 간 의존성 관리 필요

## 코딩 스타일 및 패턴

### DO (해야 할 것)
- Context 디렉토리 문서는 kebab-case로 명명
- Kotlin 코드는 Ktlint 규칙 준수
- Spring Boot 표준 패키지 구조 유지 (`org.castlekong.backend`)
- 모든 변경사항은 TASK.MD 작업 로그에 기록
- 보안 모범 사례 적용 (비밀키, 인증정보 노출 금지)

### DON'T (하지 말 것)
- Context 문서에 일회성 정보 포함 금지
- 하드코딩된 설정값 사용 금지
- 테스트 없이 새로운 기능 추가 금지
- 작업 로그 업데이트 없이 파일 수정 금지

### 네이밍 규칙
- 패키지: `org.castlekong.backend.[domain]`
- 클래스: PascalCase (예: `UserController`)
- 함수/변수: camelCase (예: `getUserInfo`)
- 상수: UPPER_SNAKE_CASE (예: `MAX_RETRY_COUNT`)

## 테스트 전략

### 백엔드 테스트
- Spring Boot Test 활용
- 단위 테스트: 각 서비스/컨트롤러 로직
- 통합 테스트: API 엔드포인트 및 데이터베이스 연동
- 보안 테스트: Spring Security Test 활용

### 품질 검증
- Ktlint로 코드 스타일 검사
- Detekt로 코드 품질 분석
- Gradle 빌드 성공 확인

이 컨텍스트를 기반으로 Context 디렉토리 구조 정리 및 개발 환경 구성을 수행합니다.
