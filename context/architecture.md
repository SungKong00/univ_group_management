# 시스템 아키텍처

## 개요

대학 그룹 관리 시스템은 Spring Boot(백엔드)와 Flutter(프론트엔드)로 구성된 풀스택 웹 애플리케이션입니다. REST API 기반의 3-tier 아키텍처를 채택하여 확장 가능하고 유지보수하기 쉬운 구조로 설계되었습니다.

## 전체 시스템 구성

```
┌─────────────────┐    HTTP/REST API    ┌─────────────────┐
│   Flutter Web   │ ←──────────────────→ │  Spring Boot    │
│   (Frontend)    │    JSON Response    │   (Backend)     │
└─────────────────┘                     └─────────────────┘
                                                 │
                                        JPA/Hibernate
                                                 │
                                        ┌─────────────────┐
                                        │   PostgreSQL    │
                                        │   (Production)  │
                                        │       H2        │
                                        │  (Development)  │
                                        └─────────────────┘
```

## 백엔드 아키텍처 (Spring Boot)

### 기술 스택
- **런타임**: JVM 17, Kotlin 1.9.25
- **프레임워크**: Spring Boot 3.5.5
- **주요 모듈**:
  - Spring Data JPA (데이터 접근)
  - Spring Security (인증/인가)
  - Spring Web (REST API)
  - OAuth2 Client (소셜 로그인)
- **문서화**: SpringDoc OpenAPI 3 (Swagger UI)
- **코드 품질**: Ktlint, Detekt

### 패키지 구조
```
org.castlekong.backend/
├── config/          # 설정 클래스들
├── controller/      # REST 컨트롤러
├── service/         # 비즈니스 로직
├── repository/      # 데이터 접근 계층
├── entity/          # JPA 엔티티
├── dto/             # 데이터 전송 객체
├── security/        # 보안 설정
└── exception/       # 예외 처리
```

### 레이어별 책임
- **Controller Layer**: HTTP 요청/응답 처리, 입력 검증
- **Service Layer**: 비즈니스 로직 구현, 트랜잭션 관리
- **Repository Layer**: 데이터베이스 CRUD 연산
- **Entity Layer**: 도메인 모델 정의

## 프론트엔드 아키텍처 (Flutter)

### 기술 스택 (계획)
- **프레임워크**: Flutter 3.x
- **언어**: Dart
- **상태 관리**: Provider/Riverpod (예정)
- **HTTP 통신**: Dio
- **라우팅**: Go Router

### 구조 (계획)
```
lib/
├── main.dart
├── models/          # 데이터 모델
├── services/        # API 서비스
├── providers/       # 상태 관리
├── screens/         # 화면 위젯
├── widgets/         # 재사용 위젯
└── utils/           # 유틸리티 함수
```

## 데이터베이스 설계

### 데이터베이스 전략
- **개발/테스트**: H2 인메모리 데이터베이스
- **프로덕션**: PostgreSQL
- **ORM**: Hibernate (Spring Data JPA)
- **마이그레이션**: Flyway (향후 도입 예정)

### 주요 도메인 (예상)
- **User**: 사용자 정보
- **Group**: 그룹 정보
- **Member**: 그룹 멤버십
- **Role**: 사용자 권한

## 보안 아키텍처

### 인증/인가
- **인증 방식**: OAuth2 + JWT (계획)
- **소셜 로그인**: 구글, 카카오 등 (계획)
- **권한 관리**: Spring Security RBAC
- **세션 관리**: Stateless JWT 토큰

### 보안 정책
- HTTPS 강제 적용
- CORS 설정
- XSS, CSRF 방어
- SQL Injection 방어 (JPA 사용)

## 배포 및 인프라

### 개발 환경
- **로컬 개발**: Spring Boot DevTools, H2 Console
- **빌드 도구**: Gradle
- **코드 품질**: Ktlint, Detekt 자동화

### 배포 전략 (계획)
- **컨테이너화**: Docker
- **클라우드 배포**: AWS/GCP (예정)
- **CI/CD**: GitHub Actions (예정)

## 확장성 고려사항

### 성능 최적화
- JPA 쿼리 최적화 (N+1 문제 방지)
- 데이터베이스 인덱싱
- API 응답 캐싱 (Redis 도입 검토)

### 모니터링
- Spring Boot Actuator
- 애플리케이션 로그 전략
- 성능 메트릭 수집 (향후)

## 제약사항 및 고려사항

### 현재 제약사항
- 프론트엔드 Flutter 프로젝트 미설정
- 데이터베이스 스키마 미정의
- 인증/인가 시스템 미구현
- API 엔드포인트 미정의

### 향후 개선 계획
- 마이크로서비스 아키텍처 전환 고려
- 실시간 알림 시스템 (WebSocket)
- 파일 업로드/다운로드 기능
- 다국어 지원 (i18n)