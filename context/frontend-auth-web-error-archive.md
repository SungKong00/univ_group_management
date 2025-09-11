# 프론트엔드 에러 해결 아카이브 — 웹 인증 상태 이슈 (뒤로가기/새로고침/로그아웃)

## 문제 요약
- 웹에서 첫 로그인은 성공하나, 메인 화면에서 브라우저 뒤로가기, 새로고침, 또는 로그아웃 시 인증 상태가 깨지거나 화면이 반응하지 않음.
- `flutter clean` 후 재실행/재로그인해야 정상화되는 현상 발생.

## 증상
- 뒤로가기: 로그인 페이지로 이동하지만 즉시 인증 상태가 반영되지 않거나 홈으로 복귀하지 않음.
- 새로고침: 홈에 머물러야 하는데 인증이 해제된 것처럼 보이거나, 반대로 인증이 없는데 홈에 남는 경우 발생.
- 로그아웃: 버튼을 눌러도 UI에 변화가 없거나, 네트워크 대기 때문에 반응이 매우 느림.

## 원인 분석
1. Web 환경에서의 토큰 저장소 선택 문제
   - 기본 `flutter_secure_storage`는 웹/로컬 환경에서 제약이 있어 새로고침/히스토리 이동 후 토큰을 신뢰성 있게 읽지 못할 수 있음.
   - 결과적으로 `isLoggedIn()` 판단이 불안정해 인증 상태가 교란됨.

2. 초기 라우트가 로그인 화면으로 고정됨
   - `initialRoute: '/login'`로 시작해 Splash(인증 점검 로직)를 우회.
   - 뒤로가기/새로고침 시 인증 실체와 화면 라우팅이 쉽게 불일치.

3. 로그아웃 동작이 네트워크 응답에 종속
   - 서버 `/auth/logout` 호출을 기다린 뒤 상태를 변경하므로, CORS/네트워크 지연 시 "아무 반응 없음"으로 체감.

4. 라우트 가드 부재
   - 로그인 페이지에서 이미 인증된 사용자를 홈으로 보내지 않음.
   - 홈에서 인증이 해제된 경우 로그인으로 강제 리다이렉트하지 않음.

## 해결 사항 (코드 변경)
1. Web 전용 토큰 저장소 스위칭
   - `kIsWeb ? SharedPrefsTokenStorage() : SecureTokenStorage()`
   - 파일: `frontend/lib/injection/injection.dart`

2. 앱 진입점을 Splash로 변경하여 인증 상태 기반 라우팅 일원화
   - `initialRoute: '/'` (Splash)
   - 파일: `frontend/lib/main.dart`

3. 로그인/홈 양방향 가드 추가
   - 로그인 화면: 이미 인증된 경우 `profileCompleted=false`면 `'/role-selection'`, 아니면 `'/home'`으로 리다이렉트
   - 홈 화면: 비인증 상태(그리고 로딩 아님)면 `'/login'`으로 리다이렉트
   - 파일: `frontend/lib/presentation/screens/auth/login_screen.dart`, `frontend/lib/presentation/screens/home/home_screen.dart`

4. 로그아웃 UX를 즉시형으로 개선
   - 로컬 세션(토큰/유저) 즉시 클리어 → 상태 `unauthenticated` 반영 → UI/라우팅 즉시 전환
   - 서버 로그아웃과 Google Sign-Out은 백그라운드에서 처리 (실패 무시)
   - 파일: `frontend/lib/presentation/providers/auth_provider.dart`

## 변경 파일 목록
- `frontend/lib/injection/injection.dart`
- `frontend/lib/main.dart`
- `frontend/lib/presentation/screens/auth/login_screen.dart`
- `frontend/lib/presentation/screens/home/home_screen.dart`
- `frontend/lib/presentation/providers/auth_provider.dart`

## 재현 방지 검증 체크리스트
1. `flutter run -d chrome` 실행
2. Google 로그인 완료 → 홈 진입 확인
3. 브라우저 뒤로가기 → 로그인으로 갔다가 즉시 홈 복귀 확인
4. 홈에서 새로고침 → 로그인 유지 시 홈에 머무름 / 미인증 시 로그인으로 이동
5. 로그아웃 클릭 → 즉시 로그인 화면으로 이동, 재로그인 가능 (네트워크 상태와 무관)

## 회귀 및 부작용 고려
- 웹 환경에서 보안 스토리지가 필요한 경우, HTTPS 및 `flutter_secure_storage`의 웹 옵션을 충분히 검토해야 함. 개발/로컬에서는 `SharedPreferences`가 신뢰성과 DX를 보장.
- 서버 로그아웃 실패 시에도 클라이언트는 로그아웃으로 간주함. 보안 정책상 서버 세션 무효화 보장이 필요하면 API 성공 여부를 별도 로깅/모니터링하거나 재시도 큐 도입 고려.

---

# 신규 이슈 기록 — 역할 선택 화면이 순간 표시 후 홈으로 이동 (레이스 컨디션)

## 문제 요약
- Google 로그인 직후 신규 사용자(프로필 미완성)에게 역할 선택 화면이 잠깐 떴다가 즉시 홈으로 전환되는 현상.

## 원인 분석
- 로그인 화면의 `isAuthenticated` 가드가 무조건 `'/home'`으로 보냈고, 동시에 Splash도 라우팅을 시도하여 네비게이션이 충돌.

## 해결 사항 (코드 변경)
- 로그인 화면의 가드를 `profileCompleted` 기준으로 분기하도록 변경.
- 네비게이션 시 `pushNamedAndRemoveUntil`을 사용해 백스택을 정리하고, 중복 콜백으로 인한 레이스를 차단.
- 파일: `frontend/lib/presentation/screens/auth/login_screen.dart`

## 검증 체크리스트
1. 신규 사용자 로그인 → 역할 선택 화면에 머무름
2. 역할 선택 → 프로필 설정 → 홈 이동
3. 기존 사용자 로그인 → 바로 홈 이동

---

# 신규 이슈 기록 — 프로필 완성(저장) 시 401/403 Unauthorized

## 문제 요약
- 프로필 설정 화면에서 "프로필 완성"을 누르면 "접근 권한 없음" 오류가 표시됨.

## 원인 분석
- `AuthService.completeProfile`가 절대 경로 `'/api/users/profile'`를 하드코딩하여 `baseUrl` 결합(이중 `/api`) 또는 라우팅 규칙과 충돌.
- 환경에 따라 Authorization 헤더 전파가 정상적으로 이뤄지지 않는 것으로 보이는 증상 유발.

## 해결 사항 (코드 변경)
- 엔드포인트 상수 `ApiEndpoints.updateProfile`(상대 경로 `'/users/profile'`)로 수정하여 `DioClient`의 `baseUrl`과 일관된 방식으로 결합.
- 파일: `frontend/lib/data/services/auth_service.dart`

## 검증 체크리스트
1. 로그인 → 역할 선택 → 프로필 입력 → 저장 → 200 OK 응답 확인
2. 콘솔 로그에서 `Request: PUT /users/profile` 및 `Authorization: Bearer <token>` 확인
3. 홈 화면에서 닉네임 및 아바타 이니셜 반영 확인

## 운영 팁
- Android 에뮬레이터에서 로컬 백엔드를 사용할 때는 `AppConstants.baseUrl`을 `http://10.0.2.2:8080/api`로 설정해야 함. (현재 기본은 `http://localhost:8080/api`)

# JSON 직렬화 에러 해결 사례

## 문제 요약
- Flutter 웹 환경에서 API 응답을 DTO로 변환할 때 JSON 직렬화 에러 발생
- `json_annotation` 및 `build_runner` 관련 코드 생성 문제로 인한 런타임 에러

## 증상
- API 호출은 성공하지만 응답 데이터를 모델 객체로 변환하는 과정에서 `FormatException` 또는 `TypeError` 발생
- 개발 모드에서는 정상 동작하지만 빌드된 웹에서만 에러 발생
- 콘솔에 "type 'String' is not a subtype of type 'int'" 등의 타입 불일치 에러 출력

## 원인 분석
1. **JSON 키-값 타입 불일치**
   - 서버에서 숫자를 문자열로 전송하거나, null 값을 예상치 못한 타입으로 처리
   - DTO 클래스의 필드 타입과 실제 JSON 응답의 타입 불일치

2. **코드 생성 파일 누락 또는 구버전**
   - `*.g.dart` 파일이 최신 DTO 정의를 반영하지 않음
   - `build_runner` 실행 없이 DTO 필드를 변경한 경우

3. **웹 컴파일러의 엄격한 타입 체킹**
   - Flutter 웹은 다른 플랫폼보다 타입 안정성을 더 엄격하게 검사

## 해결 사항 (코드 변경)
1. **타입 안전 JSON 변환 추가**
   ```dart
   // 기존 코드
   factory UserDto.fromJson(Map<String, dynamic> json) => _$UserDtoFromJson(json);
   
   // 개선된 코드 
   factory UserDto.fromJson(Map<String, dynamic> json) {
     return UserDto(
       id: _parseToInt(json['id']),
       name: json['name']?.toString() ?? '',
       email: json['email']?.toString() ?? '',
       createdAt: json['created_at'] != null 
         ? DateTime.tryParse(json['created_at'].toString())
         : null,
     );
   }
   
   static int _parseToInt(dynamic value) {
     if (value is int) return value;
     if (value is String) return int.tryParse(value) ?? 0;
     return 0;
   }
   ```

2. **build_runner 재실행으로 코드 생성 파일 동기화**
   ```bash
   flutter packages pub run build_runner clean
   flutter packages pub run build_runner build --delete-conflicting-outputs
   ```

3. **nullable 필드 처리 강화**
   ```dart
   // DTO 클래스에서 nullable 명시적 선언
   class UserDto {
     final int id;
     final String name;
     final String email;
     final DateTime? createdAt; // nullable로 명시적 선언
     
     const UserDto({
       required this.id,
       required this.name, 
       required this.email,
       this.createdAt,
     });
   }
   ```

## 변경 파일 목록
- `frontend/lib/data/dto/user_dto.dart`
- `frontend/lib/data/dto/auth_dto.dart`
- `frontend/lib/data/dto/*.g.dart` (자동 생성)

## 재현 방지 검증 체크리스트
1. `flutter clean && flutter pub get` 실행
2. `flutter packages pub run build_runner build --delete-conflicting-outputs` 실행
3. `flutter run -d chrome` 으로 웹 실행
4. API 호출이 포함된 모든 기능 테스트 (로그인, 데이터 조회 등)
5. 브라우저 개발자 도구에서 콘솔 에러 없음 확인
6. `flutter build web --release` 빌드 후 동일 테스트 수행

## 회귀 및 부작용 고려
- 수동 JSON 파싱 코드 추가로 코드 복잡성 증가
- `json_serializable` 자동 생성의 이점 일부 포기 (타입 안전성과의 트레이드오프)
- 새로운 DTO 추가 시 동일한 패턴 적용 필요

## 향후 개선 제안
- `go_router`로 전역 라우트 가드 통합 및 상태 기반 리다이렉트 일관화.
- 토큰 자동 갱신(401 처리) 로직 구현 및 공통 재시도 핸들러 도입.
- 에러/이벤트 로깅(예: Sentry)으로 웹 환경 특이 이슈 추적 강화.
- API 스키마 검증 도구 도입으로 백엔드-프론트엔드 간 타입 불일치 사전 방지.
