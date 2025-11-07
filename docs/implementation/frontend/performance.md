# 성능 최적화 (Performance)

## 앱 시작 성능

### 현재 성능 지표

- **초기 로드**: ~13.6초
- **핫 리로드**: < 1초
- **메모리 사용량**: 최적화됨

### 최적화 전략

#### 1. LocalStorage Eager 초기화

```dart
// main.dart에서 앱 시작 직후
await LocalStorage.instance.initEagerData();
```

**이점**:
- 즉시 필요한 데이터만 로드
- 대기 시간 최소화
- 사용자 입력 가능할 때까지 시간 단축

#### 2. 비차단 자동 로그인

```dart
authService.tryAutoLogin().catchError((error) => {});
```

**이점**:
- 로그인 실패해도 앱 시작 지속
- UI 차단 없음
- 약 500ms 시작 시간 단축

## 메모리 관리

### autoDispose 패턴

```dart
// ❌ 메모리에 계속 유지됨
final provider = FutureProvider<Data>((ref) async => ...);

// ✅ 사용하지 않을 때 자동 해제
final provider = FutureProvider.autoDispose<Data>((ref) async => ...);
```

**이점**:
- 불필요한 메모리 사용 제거
- 자동 생명주기 관리
- 메모리 누수 방지

### Provider 초기화

로그아웃 시 모든 사용자 데이터 Provider 초기화:

```dart
resetAllUserDataProviders(ref);
```

이를 통해:
- 계정 전환 시 이전 데이터 표시 방지
- 메모리 효율적인 관리
- 보안 강화

## 개선 계획 (우선순위)

### 1순위: 폰트 및 SVG 최적화 (4-6초 단축)
- 웹폰트 지연 로딩, Google 로그인 SVG 인라인화

### 2순위: 코드 분할 (2-3초 단축)
- 페이지별 lazy loading, 번들 크기 분석

### 3순위: 이미지 최적화 (1-2초 단축)
- WebP 포맷, 반응형 로딩, 캐싱 전략

### 4순위: HTTP 캐싱 (1초 단축)
- 브라우저 캐시, Service Worker

## 성능 모니터링

### 개발 중

```bash
# Chrome DevTools Performance 탭 사용
# Timeline 기록 및 분석
# Network 탭에서 리소스 로딩 시간 확인
```

### 프로덕션

- Web Vitals 모니터링
- 사용자 성능 메트릭 수집
- 정기적인 성능 리뷰

## 성능 테스트 체크리스트

새로운 기능 추가 시:

- [ ] 초기 로드 시간 측정
- [ ] 메모리 사용량 확인
- [ ] CPU 사용량 확인
- [ ] 네트워크 요청 최소화
- [ ] 불필요한 리렌더링 제거
- [ ] autoDispose 적용 여부 확인
