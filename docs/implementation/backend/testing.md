# 테스트 가이드

## 개요
컨트롤러 통합 테스트 및 Spring Security 인증 테스트 가이드입니다.

## 통합 테스트 패턴 (권장)

### @SpringBootTest 사용

**어노테이션**:
- `@SpringBootTest(webEnvironment = MOCK)`: 통합 테스트 환경
- `@AutoConfigureMockMvc`: MockMvc 자동 구성
- `@ActiveProfiles("test")`: 테스트 프로필
- `@Transactional`: 테스트 후 롤백

**주요 구성**:
- `mockMvc`, `userRepository`, `jwtTokenProvider` 주입
- `@BeforeEach`에서 테스트 사용자 생성 및 토큰 발급
- `generateToken()`: JWT 토큰 생성 (UsernamePasswordAuthenticationToken 사용)

**테스트 패턴**: `mockMvc.perform(get(url).header("Authorization", "Bearer $token"))` → 상태 검증 + JsonPath 검증

**구현 위치**: `backend/src/test/kotlin/.../controller/`

## @WebMvcTest vs @SpringBootTest 선택 기준

### @WebMvcTest (슬라이스 테스트)
**사용 시기**:
- Controller만 테스트 (Service는 Mock)
- 빠른 테스트 실행 필요
- 단순한 컨트롤러 (적은 의존성)

**단점**:
- 다중 Service 의존성 시 Mock 설정 복잡
- Spring Security 통합 제한적

### @SpringBootTest (통합 테스트) ✅ 권장
**사용 시기**:
- 실제 환경과 동일한 인증/권한 흐름 검증
- 다중 Service 의존성이 있는 컨트롤러
- Spring Security 통합 필요
- 실제 Repository/Service 동작 검증

**예시: MeController의 경우**:
- UserService + GroupMemberService 의존
- `@WebMvcTest` 사용 시 `NoSuchBeanDefinitionException` 발생
- `@SpringBootTest` 사용으로 모든 빈 로드 → 실제 환경과 동일

## Spring Security 인증 테스트

### JWT 토큰 생성
**패턴**: `UsernamePasswordAuthenticationToken(email, null, authorities)` → `jwtTokenProvider.generateAccessToken()`

### MockMvc 요청
**패턴**: `.header("Authorization", "Bearer $token")` + `.accept(MediaType.APPLICATION_JSON)`

### 상태 검증
- ❌ 잘못된 예: `.andExpect(status().isUnauthorized)` - 401만 허용
- ✅ 올바른 예: `.andExpect(status().is4xxClientError)` - 401 or 403 허용
- **이유**: Spring Security는 상황에 따라 401/403 반환

## 권한 기반 테스트

### @WithMockUser 사용
**패턴**: `@WithMockUser(username = "email", roles = ["ROLE"])` - Mock 인증 자동 생성

### 커스텀 권한 테스트
**패턴**: 실제 사용자 생성 → JWT 토큰 발급 → `.header("Authorization", "Bearer $token")` 사용

## 주요 테스트 시나리오

### 1. 시스템 역할 불변성 테스트
**시나리오**: 시스템 역할 수정 시도
**기대 결과**: `SYSTEM_ROLE_IMMUTABLE` (403)

### 2. 채널 권한 검증 테스트
**시나리오**: 새 채널 생성 직후 읽기 시도 (바인딩 없음)
**기대 결과**: FORBIDDEN (403)

### 3. 캐시 무효화 검증 테스트
**시나리오**: 권한 부여 → 접근 성공 확인 → 권한 제거 → 접근 실패 확인
**기대 결과**: 캐시 무효화되어 이전 권한으로 접근 불가

## 주요 테스트 라이브러리

**의존성**: MockMvc (HTTP 모킹), JUnit 5 (테스트), AssertJ (단언), Spring Security Test (보안)

**유용한 단언문**:
- `jsonPath("$.success").value(true)` - JSON 필드 검증
- `status().isOk` / `status().is4xxClientError` - 상태 코드 검증
- `content().contentType(MediaType.APPLICATION_JSON)` - 컨텐츠 타입 검증

## 관련 문서
- [권한 검증](./permission-checking.md) - 권한 로직 구현
- [트랜잭션 패턴](./transaction-patterns.md) - 트랜잭션 관리
- [테스트 데이터](../../testing/test-data-reference.md) - 테스트 데이터 구조
