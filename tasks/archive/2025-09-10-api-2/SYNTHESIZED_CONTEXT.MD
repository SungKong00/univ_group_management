# SYNTHESIZED_CONTEXT.MD

## 1. 작업 목표 및 제약사항

- **핵심 목표**: 로그인 API 기능에 대한 단위, 통합, 보안 테스트를 포괄적으로 작성합니다.
- **주요 성공 기준**:
  - **단위 테스트**: `JwtTokenProvider` 유틸리티와 인증 관련 `Service` 계층의 로직을 완벽히 검증합니다.
  - **통합 테스트**: 로그인 API 엔드포인트의 요청/응답 흐름을 검증합니다.
  - **보안 테스트**: Spring Security 기반의 인증/인가 규칙(토큰 기반 접근 제어)을 검증합니다.
  - **달성 지표**: 전체 테스트 커버리지 85% 이상을 목표로 합니다.

## 2. 관련 아키텍처 및 핵심 원칙

- **백엔드 아키텍처**: 3-Tier (Controller, Service, Repository) 구조를 따릅니다. 테스트는 각 계층의 책임을 명확히 분리하여 작성해야 합니다.
- **인증 방식**: 상태 비저장(Stateless) JWT 토큰 기반 인증을 사용합니다. 테스트의 핵심은 유효한 토큰 발급 여부와 해당 토큰을 이용한 API 접근 제어 검증입니다.
- **API 응답 형식**: 모든 API 응답은 `api-conventions.md`에 정의된 표준 구조(`success`, `data`, `error`)를 따릅니다. 통합 테스트 시 `jsonPath`를 사용하여 이 구조를 검증해야 합니다.
- **의존성 주입**: 모든 의존성은 생성자 주입(Constructor Injection)을 사용합니다. 테스트 시 Mock 객체를 주입하기 용이한 구조입니다.

## 3. 테스트 대상 핵심 파일 및 모듈

- **주요 테스트 대상 (Production Code)**:
  - `backend/src/main/kotlin/.../security/JwtTokenProvider.kt`: JWT 생성, 유효성 검증, 클레임 추출 로직.
  - `backend/src/main/kotlin/.../service/AuthService.kt` (또는 유사 클래스): 사용자 인증 및 토큰 발급 비즈니스 로직.
  - `backend/src/main/kotlin/.../controller/AuthController.kt`: `/api/v1/auth/login` 등 로그인 관련 엔드포인트.
  - `backend/src/main/kotlin/.../config/SecurityConfig.kt`: HTTP 요청에 대한 인증/인가 규칙 정의.

- **작성/수정할 파일 (Test Code)**:
  - `backend/src/test/kotlin/.../security/JwtTokenProviderTest.kt` (단위 테스트)
  - `backend/src/test/kotlin/.../service/AuthServiceTest.kt` (단위 테스트)
  - `backend/src/test/kotlin/.../controller/AuthControllerTest.kt` (웹 계층 통합 테스트)
  - `backend/src/test/kotlin/.../integration/AuthIntegrationTest.kt` (전체 통합 및 보안 테스트)

## 4. 구현 전략 및 테스트 계획

테스트는 의존성이 적은 순서(단위 → 통합)로 진행하는 것을 권장합니다.

**1단계: 단위 테스트 (Unit Tests)**

- **`JwtTokenProviderTest.kt`**:
  - **Given**: Secret Key, 사용자 ID, 역할(Role).
  - **When**: 토큰 생성.
  - **Then**: 생성된 토큰이 유효한지, 올바른 클레임(사용자 ID, 역할)을 포함하는지, 만료 시간을 올바르게 설정하는지 검증합니다. 유효하지 않은 토큰(만료, 잘못된 서명)에 대한 검증 실패 케이스도 테스트합니다.
- **`AuthServiceTest.kt`**:
  - `UserRepository`, `PasswordEncoder`, `JwtTokenProvider`를 `MockK`로 Mocking 합니다.
  - **성공 케이스**: 올바른 자격 증명(ID/PW) 시, `PasswordEncoder.matches`가 `true`를 반환하고 `JwtTokenProvider`가 호출되어 토큰을 정상적으로 반환하는지 검증합니다.
  - **실패 케이스**:
    - 사용자가 존재하지 않을 때 `UserNotFoundException` 예외가 발생하는지 검증합니다.
    - 비밀번호가 틀렸을 때 `InvalidPasswordException` (또는 유사 예외)가 발생하는지 검증합니다.

**2단계: 통합 및 보안 테스트 (Integration & Security Tests)**

- **`AuthControllerTest.kt` (`@WebMvcTest`)**:
  - `AuthService`를 `@MockBean`으로 등록합니다.
  - **Given**: 유효/비유효 로그인 DTO.
  - **When**: `/api/v1/auth/login` 엔드포인트 호출.
  - **Then**:
    - 유효성 검증(@Valid) 실패 시 `400 Bad Request` 반환 여부 검증.
    - `AuthService`의 Mock 동작에 따라 `200 OK`와 토큰이 포함된 응답 또는 `401 Unauthorized`와 에러 응답이 `api-conventions.md` 형식에 맞게 반환되는지 `jsonPath`로 검증.

- **`AuthIntegrationTest.kt` (`@SpringBootTest`)**:
  - 실제 데이터베이스(H2)와 전체 Application Context를 로드하여 테스트합니다.
  - **시나리오 1: 인증 성공 및 보호된 리소스 접근**
    1. **Given**: 테스트용 사용자 데이터를 DB에 저장.
    2. **When**: `/api/v1/auth/login` API를 실제 호출하여 JWT 토큰 획득.
    3. **Then**: `200 OK` 응답과 토큰 수신 확인.
    4. **When**: 획득한 토큰을 `Authorization` 헤더에 담아 보호된 API(예: `/api/v1/users/profile`) 호출.
    5. **Then**: `200 OK` 응답으로 접근 성공 확인.
  - **시나리오 2: 인증 실패 케이스**
    - 토큰 없이 보호된 API 호출 시 `401 Unauthorized` 반환 확인.
    - 유효하지 않은 토큰으로 보호된 API 호출 시 `401 Unauthorized` 반환 확인.
    - `USER` 권한 토큰으로 `ADMIN` 전용 API(예: `/api/v1/admin/**`) 호출 시 `403 Forbidden` 반환 확인.

## 5. 핵심 가이드라인 및 모범 사례 (Do's & Don'ts)

- **(DO)** **테스트 프레임워크**: **JUnit 5**를 사용하고, Kotlin의 강점을 살릴 수 있는 **MockK** (`mockk`, `every`, `verify`)를 Mocking 라이브러리로 사용합니다.
- **(DO)** **테스트 네이밍**: `should_[기대행위]_when_[테스트상태]` 규칙을 철저히 준수합니다. (예: `should return jwt when valid credentials provided`)
- **(DO)** **테스트 구조**: 모든 테스트는 **Given-When-Then (또는 Arrange-Act-Assert)** 패턴으로 명확하게 구조화합니다.
- **(DO)** **어설션**: **AssertJ** (`assertThat(...)`)를 사용하여 가독성 높은 검증 코드를 작성합니다.
- **(DO)** **테스트 데이터**: `Test Fixtures` 객체를 만들어 테스트 데이터를 일관되고 재사용 가능하게 관리합니다.
- **(DON'T)** 하나의 테스트 메서드에서 여러 가지를 검증하지 마세요. 각 테스트는 하나의 책임만 가집니다.
- **(DON'T)** `Thread.sleep()`을 사용하여 비동기나 시간을 테스트하지 마세요.

## 6. 잠재적 위험 및 엣지 케이스

- **JWT 토큰**: 만료 시간 직전/직후의 토큰 유효성, 서명 키가 다를 경우, 토큰 구조가 깨졌을 경우를 테스트해야 합니다.
- **보안 설정**: `SecurityConfig`에서 `permitAll()`로 설정된 엔드포인트와 인증이 필요한 엔드포인트의 접근 제어가 정확히 동작하는지 교차 확인이 필요합니다.
- **입력값 검증**: 로그인 ID/PW의 공백(trim), 대소문자 구분 정책 등 경계값을 테스트 시나리오에 포함해야 합니다.
