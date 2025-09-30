# 서브 에이전트 마스터 가이드

## 개요
대학교 그룹 관리 시스템을 위한 7개 전문 서브 에이전트의 역할, 협업 방식, 그리고 효과적인 활용 방법을 안내합니다.

## 서브 에이전트 구성

### 핵심 개발 에이전트 (4개)
- **backend-architect**: Spring Boot 백엔드 아키텍처 전문가
- **frontend-specialist**: Flutter/React UI/UX 구현 전문가
- **permission-engineer**: RBAC 권한 시스템 전문가
- **api-integrator**: 백엔드-프론트엔드 연동 전문가

### 지원 및 품질 에이전트 (3개)
- **database-optimizer**: JPA 쿼리 최적화 및 성능 전문가
- **test-automation**: 통합 테스트 및 자동화 전문가
- **context-manager**: 문서 구조 관리 및 최적화 전문가

## 서브 에이전트 활용 방법

### 단일 에이전트 호출
```
[에이전트명]에게 [구체적 작업] 요청을 합니다.

요구사항:
- [상세 요구사항 1]
- [상세 요구사항 2]

고려사항:
- [제약사항이나 특별한 고려사항]
```

### 협업 에이전트 호출
```
[주 에이전트]에게 [작업] 요청하며, [보조 에이전트]와 협업이 필요합니다.

작업 분담:
- [주 에이전트]: [담당 영역]
- [보조 에이전트]: [담당 영역]

통합 요구사항:
- [전체적인 목표와 제약사항]
```

## 에이전트별 전문 분야

### backend-architect
**전문 분야**: Spring Boot + Kotlin 3레이어 아키텍처
- Controller-Service-Repository 패턴
- REST API 설계 및 구현
- @PreAuthorize 권한 체크
- 복잡한 비즈니스 로직 설계

**활용 시나리오**:
- 새로운 API 엔드포인트 개발
- 복잡한 도메인 로직 구현
- 데이터베이스 트랜잭션 관리
- Spring Security 통합

### frontend-specialist
**전문 분야**: Flutter/React 반응형 UI/UX
- 900px 브레이크포인트 반응형 설계
- Provider/Zustand 상태 관리
- 권한 기반 UI 렌더링
- 디자인 시스템 준수

**활용 시나리오**:
- 새로운 화면/컴포넌트 개발
- 상태 관리 리팩토링
- 반응형 레이아웃 구현
- 사용자 경험 개선

### permission-engineer
**전문 분야**: RBAC + 개인 오버라이드 권한 시스템
- 14가지 그룹 권한 관리
- 복잡한 권한 계산 로직
- 역할 생성 및 커스터마이징
- 권한 디버깅 및 문제 해결

**활용 시나리오**:
- 새로운 권한 추가
- 복잡한 권한 시나리오 구현
- 권한 문제 진단
- 보안 정책 설계

### api-integrator
**전문 분야**: 백엔드-프론트엔드 HTTP 통신
- Dio(Flutter)/Axios(React) 설정
- JWT 토큰 관리 및 갱신
- 통합된 에러 처리
- 네트워크 최적화

**활용 시나리오**:
- 새로운 API 연동
- 인증 플로우 개선
- 네트워크 에러 처리
- 성능 최적화

### database-optimizer
**전문 분야**: JPA 쿼리 최적화 및 성능
- N+1 문제 해결
- 복잡한 쿼리 최적화
- 인덱스 전략 설계
- 캐싱 시스템 구축

**활용 시나리오**:
- 성능 병목 해결
- 대용량 데이터 처리
- 쿼리 최적화
- 데이터베이스 모니터링

### test-automation
**전문 분야**: 통합 테스트 및 자동화
- Spring Boot 통합 테스트
- Flutter Widget/E2E 테스트
- 권한 시나리오 테스트
- 성능 테스트

**활용 시나리오**:
- 테스트 코드 작성
- 테스트 커버리지 향상
- 자동화 파이프라인 구축
- 성능 벤치마킹

### context-manager
**전문 분야**: 문서 구조 관리 및 최적화
- 100줄 원칙 준수
- 계층형 참조 시스템
- 메타데이터 관리
- 문서 품질 향상

**활용 시나리오**:
- 문서 구조 리팩토링
- 컨텍스트 업데이트
- 문서 품질 감사
- 참조 시스템 최적화

## 협업 패턴

### 주요 협업 조합

#### 1. 새로운 기능 개발
```
Primary: backend-architect
Secondary: frontend-specialist, permission-engineer
Support: api-integrator, test-automation
```

#### 2. 성능 최적화
```
Primary: database-optimizer
Secondary: backend-architect
Support: test-automation
```

#### 3. UI/UX 개선
```
Primary: frontend-specialist
Secondary: api-integrator
Support: test-automation
```

#### 4. 권한 시스템 확장
```
Primary: permission-engineer
Secondary: backend-architect, frontend-specialist
Support: test-automation
```

#### 5. 문서화 및 리팩토링
```
Primary: context-manager
Secondary: All agents (각자 전문 분야)
```

## 효과적인 활용 가이드

### 1. 작업 범위 명확화
- **좋은 예시**: "그룹 초대 시스템의 백엔드 API 구현"
- **나쁜 예시**: "그룹 관련 기능 개선"

### 2. 구체적 요구사항 제시
- 기술적 제약사항
- 비즈니스 요구사항
- 성능 기준
- 호환성 요구사항

### 3. 기존 패턴 참조
- 유사한 기존 기능 멘션
- 재사용 가능한 컴포넌트 활용
- 일관된 아키텍처 패턴 유지

### 4. 테스트 및 검증 포함
- 단위/통합 테스트 요구사항
- 성능 기준 설정
- 사용자 시나리오 테스트

## 프로젝트 특화 가이드

### 권한 시스템 관련 작업
모든 그룹 관련 기능은 다음 에이전트들과 협업:
- **Primary**: permission-engineer
- **Implementation**: backend-architect, frontend-specialist
- **Testing**: test-automation

### 성능 중요 기능
대용량 데이터나 복잡한 쿼리가 필요한 작업:
- **Primary**: backend-architect
- **Optimization**: database-optimizer
- **Validation**: test-automation

### UI/UX 중심 작업
사용자 경험이 중요한 기능:
- **Primary**: frontend-specialist
- **Integration**: api-integrator
- **Testing**: test-automation

## 품질 보증 체크리스트

### 개발 완료 기준
- [ ] 모든 보호된 엔드포인트에 권한 체크 적용
- [ ] 반응형 레이아웃 구현 (900px 브레이크포인트)
- [ ] 표준 에러 처리 및 사용자 피드백
- [ ] 통합 테스트 작성 및 통과
- [ ] 성능 기준 만족
- [ ] 문서 업데이트 완료

### 코드 리뷰 체크리스트
- [ ] 기존 패턴 및 컨벤션 준수
- [ ] 보안 취약점 검토
- [ ] 메모리 누수 및 성능 이슈 확인
- [ ] 에러 처리 완전성 검증
- [ ] 테스트 커버리지 충족

## 문제 해결 가이드

### 일반적인 문제 상황별 대응

#### 성능 이슈
1. **database-optimizer**에게 쿼리 분석 요청
2. **backend-architect**와 비즈니스 로직 최적화 협의
3. **test-automation**으로 성능 테스트 설정

#### 권한 관련 버그
1. **permission-engineer**에게 권한 로직 디버깅 요청
2. **backend-architect**와 API 레벨 체크 확인
3. **frontend-specialist**와 UI 권한 표시 검토

#### API 연동 문제
1. **api-integrator**에게 통신 로직 진단 요청
2. **backend-architect**와 API 스펙 확인
3. **frontend-specialist**와 클라이언트 구현 검토

#### 복잡한 UI 버그
1. **frontend-specialist**에게 컴포넌트 분석 요청
2. **api-integrator**와 데이터 흐름 확인
3. **test-automation**으로 시나리오 테스트 작성

## 지속적 개선

### 정기 점검 항목
- 서브 에이전트 역할 분담 효율성
- 협업 패턴 최적화
- 새로운 기술 스택 대응
- 문서 구조 개선

### 피드백 수집
- 각 에이전트 활용 빈도 분석
- 협업 시 발생하는 중복 작업 식별
- 누락되는 전문 영역 파악
- 사용자 만족도 평가

이 가이드를 통해 프로젝트의 복잡성을 효과적으로 관리하고, 각 전문 영역에서 최고 품질의 결과물을 얻을 수 있습니다.