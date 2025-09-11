# SYNTHESIZED CONTEXT - Flutter 프론트엔드 개발

## 작업 목표 요약

**목표**: 백엔드 Spring Boot API와 완전히 연동하는 Flutter 대학 그룹 관리 모바일 앱 개발
- JWT 기반 인증 시스템 구현 (로그인/회원가입)
- 그룹 생성, 조회, 참여, 탈퇴 기능 구현
- 토스 디자인 시스템(TDS) 원칙을 적용한 UI/UX

## 백엔드 API 분석

### 인증 API 엔드포인트
- **Base URL**: `http://localhost:8080/api/v1`
- **로그인**: `POST /auth/login`
  - Request: `{ "email": "string", "password": "string" }`
  - Response: `{ "accessToken", "refreshToken", "tokenType": "Bearer", "expiresIn": 86400000, "user": UserResponse }`
- **회원가입**: `POST /auth/register`
  - Request: `{ "name": "string", "email": "string", "password": "string" }`
  - Response: `UserResponse`

### 사용자 데이터 모델
```kotlin
// UserResponse
{
  "id": Long,
  "name": String,
  "email": String,
  "role": "GUEST|USER|MODERATOR|ADMIN",
  "isActive": Boolean,
  "createdAt": LocalDateTime,
  "updatedAt": LocalDateTime
}
```

### API 응답 표준 형식
```json
// 성공 응답
{
  "success": true,
  "data": { /* 실제 데이터 */ },
  "message": "성공 메시지",
  "timestamp": "ISO-8601"
}

// 에러 응답
{
  "success": false,
  "error": {
    "code": "ERROR_CODE",
    "message": "사용자 친화적 메시지",
    "details": "상세 오류 정보"
  },
  "timestamp": "ISO-8601",
  "path": "/api/path"
}
```

## Flutter 앱 아키텍처 설계

### 기술 스택
- **Flutter**: 3.x
- **언어**: Dart
- **상태 관리**: Provider/Riverpod
- **HTTP 통신**: Dio
- **라우팅**: Go Router
- **로컬 저장소**: SharedPreferences (토큰 저장)
- **의존성 주입**: GetIt

### 프로젝트 구조
```
lib/
├── main.dart                   # 앱 진입점
├── core/                      # 핵심 설정 및 유틸리티
│   ├── constants/            # 상수 정의
│   ├── network/              # HTTP 클라이언트 설정
│   ├── storage/              # 로컬 저장소 관리
│   └── utils/                # 유틸리티 함수
├── data/                     # 데이터 계층
│   ├── models/               # 데이터 모델
│   ├── repositories/         # Repository 구현체
│   └── services/             # API 서비스
├── domain/                   # 도메인 계층
│   ├── entities/             # 도메인 엔티티
│   └── repositories/         # Repository 인터페이스
├── presentation/             # UI 계층
│   ├── providers/            # 상태 관리 Provider
│   ├── screens/              # 화면 위젯
│   ├── widgets/              # 재사용 위젯
│   └── theme/                # 앱 테마 설정
└── injection/                # 의존성 주입 설정
```

## UI/UX 디자인 원칙

### 디자인 철학
- **미니멀리즘**: 여백 많고 요소 적게, 깔끔하고 직관적인 인터페이스
- **모던/플랫**: 그림자·그라데이션 최소화, 선명한 색상과 단순한 형태
- **토스식**: 흰 배경 + 심플한 폰트 + 금융 데이터 중심의 레이아웃
- **머티리얼 디자인**: 구글 가이드라인 기반, 버튼·카드·모션 일관성
- **애플 스타일**: 부드러운 곡선, 정제된 폰트, 여백 강조

### UI 컴포넌트 우선순위
- **공통 컴포넌트**: 버튼, 입력 필드, 로딩 인디케이터, 에러 표시
- **폼 유효성 검증**: 실시간 검증 및 사용자 친화적 에러 메시지
- **일관된 스타일링**: 미니멀하고 모던한 스타일 기반 색상, 타이포그래피, 간격

## 구현 순서 및 전략

### Phase 1: 핵심 인프라 구축
1. **Flutter 프로젝트 초기 설정**
   - 패키지 의존성 설정 (dio, provider, go_router 등)
   - 프로젝트 구조 생성
   - 기본 라우팅 설정

2. **네트워크 및 API 클라이언트**
   - Dio HTTP 클라이언트 설정
   - API 응답 모델 정의
   - 인터셉터 설정 (토큰 자동 추가, 에러 처리)

### Phase 2: 인증 시스템
1. **인증 데이터 모델**
   - User, LoginRequest, RegisterRequest 모델 정의
   - JWT 토큰 관리 로직

2. **인증 Repository 및 Service**
   - AuthRepository 인터페이스 및 구현체
   - TokenStorage 서비스 (SharedPreferences)

3. **인증 상태 관리**
   - AuthProvider (로그인 상태, 사용자 정보)
   - 자동 로그인 로직

### Phase 3: UI 화면 구현
1. **온보딩 및 인증 화면**
   - 스플래시 화면
   - 온보딩 화면 (앱 소개)
   - 로그인 화면
   - 회원가입 화면 (단계별)

2. **메인 화면 구조**
   - 홈 화면 (그룹 목록)
   - 프로필 화면
   - 설정 화면

### Phase 4: 그룹 관리 기능
1. **그룹 데이터 모델 및 API 연동** (백엔드 API 완성 후)
2. **그룹 생성/조회/수정 화면**
3. **멤버 관리 기능**

## 기술적 제약사항 및 고려사항

### 보안
- JWT 토큰 안전한 저장 (Flutter Secure Storage 고려)
- API 통신 시 HTTPS 강제
- 민감 정보 로깅 방지

### 성능
- 이미지 캐싱 및 최적화
- 무한 스크롤 구현 (큰 목록의 경우)
- 적절한 상태 관리로 불필요한 리빌드 방지

### 호환성
- Android/iOS 크로스 플랫폼 대응
- 다양한 화면 크기 대응 (반응형 디자인)

## 테스트 전략

### 단위 테스트
- Repository 및 Service 로직 테스트
- 데이터 모델 직렬화/역직렬화 테스트
- 유틸리티 함수 테스트

### 위젯 테스트
- 주요 화면의 UI 컴포넌트 테스트
- 폼 유효성 검증 테스트
- 버튼 동작 및 네비게이션 테스트

### 통합 테스트
- API 연동 테스트
- 로그인/로그아웃 플로우 테스트
- 전체 사용자 시나리오 테스트

## 위험 요소 및 대응 방안

### 위험 요소
1. **백엔드 API 미완성**: 그룹 관련 API가 아직 구현되지 않음
2. **디자인 일관성**: 토스 디자인 시스템의 정확한 구현
3. **상태 관리 복잡성**: 인증 상태와 비즈니스 로직의 분리

### 대응 방안
1. **Mock API 활용**: 백엔드 완성 전까지 Mock 데이터로 UI 개발
2. **컴포넌트 라이브러리**: 재사용 가능한 UI 컴포넌트를 우선 구축
3. **아키텍처 분리**: Clean Architecture 패턴으로 관심사 분리

## 성공 기준

### 기능적 요구사항
- [ ] 회원가입/로그인 기능 완성 및 JWT 토큰 관리
- [ ] 백엔드 API와 완전한 연동 (인증 API)
- [ ] 토스 스타일 UI/UX 구현
- [ ] 앱 빌드 및 실행 성공 (Android/iOS)

### 비기능적 요구사항
- [ ] 응답 속도: 화면 전환 1초 이내
- [ ] 네트워크 에러 처리 및 사용자 친화적 메시지 표시
- [ ] 코드 품질: 단위 테스트 커버리지 80% 이상

## 다음 단계 작업 계획

1. **즉시 착수**: Flutter 프로젝트 생성 및 기본 구조 설정
2. **1단계**: 네트워크 설정 및 인증 API 연동
3. **2단계**: 로그인/회원가입 화면 구현
4. **3단계**: 메인 화면 구조 및 네비게이션
5. **4단계**: 그룹 관리 기능 (백엔드 API 완성 후)

이 계획을 바탕으로 단계적이고 체계적인 Flutter 앱 개발을 진행합니다.
