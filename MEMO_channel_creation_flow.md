# 채널 생성 프로세스 분석 및 개선안 MEMO

**작성일**: 2025-11-05
**주제**: 새 채널 생성 시 권한 설정 필수화 프로세스 분석
**목표**: 채널 생성 후 권한 설정까지 완료해야만 채널이 생기도록 수정

---

## 📋 목차
1. [현재 설계](#현재-설계)
2. [문제점 분석](#문제점-분석)
3. [개선 방향](#개선-방향)
4. [구현 체크리스트](#구현-체크리스트)

---

## 현재 설계

### 1. 프론트엔드 플로우

#### CreateChannelDialog 역할
- **위치**: `frontend/lib/presentation/pages/workspace/widgets/` (라인 21-104)
- **역할**: 채널 이름/설명 입력 수집
- **입력 항목**:
  - 채널 이름 (필수, 100자 이하)
  - 채널 설명 (선택, 500자 이하)
  - 채널 타입: TEXT로 고정
- **실행 방식**:
  - "채널 만들기" 버튼 클릭 시 즉시 `ChannelService.createChannel()` 호출
  - 채널 생성 성공 시 Channel 객체 받아서 다이얼로그 반환

#### ChannelListSection 플로우
- **위치**: `frontend/lib/presentation/pages/workspace/widgets/` (라인 206-292)
- **역할**: 채널 목록 관리 및 권한 설정 다이얼로그 연결
- **실행 방식**:
  1. CreateChannelDialog 표시 (라인 238-242)
  2. Channel 객체 반환되면 즉시 ChannelPermissionsDialog 표시 (라인 247-253)
  3. isRequired=true로 설정하여 권한 설정 필수화
  4. 권한 설정 결과에 따라 채널 목록 새로고침
- **사용자 안내**: 경고 배너로 "채널 생성 후 권한 설정이 필요하며, 권한 설정 전까지는 아무도 이 채널을 볼 수 없습니다" 표시

### 2. 백엔드 API 구조

#### 채널 생성 API
- **엔드포인트**: `POST /workspaces/{workspaceId}/channels`
- **요청**: CreateChannelRequest (name, description, type)
- **응답**: ChannelResponse (생성된 Channel 객체)
- **위치**: `backend/src/main/kotlin/org/castlekong/backend/controller/ContentController.kt` (라인 111-122)

#### 채널 생성 서비스 로직
- **위치**: `backend/src/main/kotlin/org/castlekong/backend/service/ContentService.kt` (라인 250-286)
- **실행 단계**:
  1. Workspace 존재 확인
  2. 권한 검증: `validateChannelManagePermission()` 호출 → 그룹장 OR CHANNEL_MANAGE 권한 확인
  3. 채널 엔티티 생성 (name, description, type 설정)
  4. 채널 DB 저장
  5. **권한 바인딩 자동 생성 제거됨** (라인 283): 2025-10-01 rev5 정책에 따라 사용자 정의 채널은 권한 0개 상태로 시작
- **특징**: @Transactional 처리되어 원자성 보장

#### 권한 설정 API (분리됨)
- **엔드포인트**: `POST /channels/{channelId}/role-bindings`
- **요청**: CreateChannelRoleBindingRequest (groupRoleId, permissions)
- **응답**: ChannelRoleBindingResponse
- **위치**: `backend/src/main/kotlin/org/castlekong/backend/controller/ContentController.kt` (라인 283-295)
- **특징**: 채널 생성 API와 별도로 분리됨

### 3. 권한(ChannelRoleBinding) 시스템

#### 권한 생성 시점
- **기본 2채널** (공지/자유): 그룹 생성 시 `ChannelInitializationService`에서 자동 생성 (라인 18-31)
  - 공지사항 채널: 그룹장/교수 (전체 권한), 멤버 (읽기+댓글)
  - 자유게시판: 그룹장/교수 (전체 권한), 멤버 (읽기+쓰기+댓글)
- **사용자 정의 채널**: 수동으로 권한 설정 필요 (생성 직후 바인딩 0개)

#### 초기값 및 접근성
- **사용자 정의 채널 초기값**: 아무 바인딩도 없음 (권한 0개)
- **채널 목록 필터링**: `ContentService.getChannelsByWorkspace()` (라인 207-224)
  - POST_READ 권한이 없는 채널은 필터링됨
  - 따라서 권한 없으면 채널 목록에서 조차 보이지 않음

#### 권한 설정 프로세스
- **위치**: `ChannelPermissionsDialog` (라인 92-148)
- **실행 순서**:
  1. 역할 목록 로드
  2. 권한별로 역할 선택 (권한 → Set<RoleId> 매핑)
  3. POST_READ 권한 필수 검증
  4. 권한 매트릭스를 역할별 권한으로 변환
  5. 각 역할별로 createChannelRoleBinding API 호출 (반복)

### 4. 전체 플로우 다이어그램

```
[프론트엔드 - 관리 페이지]
    ↓
1. 사용자: "새 채널 추가" 버튼 클릭
    ↓
2. [CreateChannelDialog 표시]
    - 채널 이름 입력: "개발-논의"
    - 채널 설명 입력 (선택)
    - "채널 만들기" 버튼 클릭
    ↓
3. [프론트엔드 API 호출]
    POST /workspaces/{workspaceId}/channels
    → name: "개발-논의", type: "TEXT"
    ↓
4. [백엔드 - 채널 생성]
    - Workspace 존재 확인
    - 권한 검증: validateChannelManagePermission()
    - Channel 엔티티 생성
    - DB 저장
    ← ChannelResponse 반환
    ↓
5. [프론트엔드 - CreateChannelDialog 닫기]
    - 반환값: Channel 객체
    ↓
6. [프론트엔드 - ChannelPermissionsDialog 표시]
    - isRequired: true (필수)
    - 역할 목록 로드
    - 사용자: 각 권한별로 역할 선택
        * POST_READ: 멤버 ✓
        * POST_WRITE: 그룹장 ✓
        * COMMENT_WRITE: 그룹장, 멤버 ✓
        * FILE_UPLOAD: 그룹장 ✓
    - "저장" 버튼 클릭
    ↓
7. [프론트엔드 - 권한 바인딩 생성 반복 호출]
    For each role:
        POST /channels/{channelId}/role-bindings
        → groupRoleId, permissions: ["POST_READ", "POST_WRITE", ...]
    ↓
8. [백엔드 - 권한 바인딩 생성]
    - ChannelRoleBinding 엔티티 생성
    - DB 저장
    - 권한 캐시 무효화
    ↓
9. [프론트엔드 - ChannelPermissionsDialog 닫기]
    - 채널 목록 새로고침 (ref.invalidate)
    - 성공 메시지 표시
```

---

## 문제점 분석

### 1. 현재 상태의 강점
- ✅ **명확한 권한 정책**: 사용자 정의 채널은 반드시 권한 설정 필요 (보안성)
- ✅ **2단계 필수화**: isRequired=true로 권한 설정 강제 (UX 가이드)
- ✅ **자동 필터링**: 권한 없으면 목록에서 안 보임 (접근 제어)
- ✅ **API 분리**: 채널 생성과 권한 설정이 분리 (유연성)

### 2. 현재 상태의 문제점

#### 🔴 권한 설정 취소 시 처리
- **문제**: ChannelPermissionsDialog를 닫으면 어떻게 되나?
  - 채널은 이미 DB에 저장됨
  - 권한 설정은 하지 않음
  - 결과: 권한 없는 고아 채널 생성
- **사용자 혼란**: 채널이 생성됐으나 보이지 않는 상태

#### 🔴 부분 실패 시 데이터 불일치
- **문제**: 권한 설정 중 일부 역할만 성공, 일부 실패
  - 채널은 생성됨 (이미 커밋)
  - 일부 역할만 권한 설정됨
  - 결과: 부분 권한 상태 (의도하지 않은)
- **복구 불가**: 자동 롤백 메커니즘 없음

#### 🔴 네트워크 왕복 증가
- **문제**: 역할 N개 = API 호출 N+1회
  - 채널 생성: 1회
  - 권한 설정: N회 (각 역할별)
- **성능**: 네트워크 레이턴시 누적

#### 🔴 트랜잭션 원자성 부재
- **문제**: 채널 생성과 권한 설정이 별개 트랜잭션
- **의도**: 둘 다 성공하거나 둘 다 실패해야 함
- **현재**: 채널 생성은 성공했으나 권한 설정 실패 가능

---

## 개선 방향

### 옵션 1: 기본 템플릿 자동 적용 (추천: 낮은 복잡도)

**개념**:
- 채널 생성 후 기본 권한 템플릿을 자동 적용
- 사용자는 (선택적으로) 세부 조정 가능

**장점**:
- 권한 0개 상태 제거 (고아 채널 방지)
- 즉시 사용 가능한 채널 생성
- 사용자 작업량 감소

**단점**:
- 기본 템플릿 결정 필요 (공지? 자유?)
- 기본값이 사용자 의도와 다를 수 있음

**구현 방식**:
1. ContentService.createChannel()에서 기본 템플릿 자동 적용
   - 예: "멤버에게 읽기 권한, 그룹장에게 전체 권한"
2. ChannelPermissionsDialog에서 기본값으로 표시
3. 사용자는 기본값 유지 또는 수정 선택

---

### 옵션 2: 권한 설정 필수 + 자동 롤백 (추천: 안전성 우선)

**개념**:
- 권한 설정 완료 전까지 채널을 "임시" 상태로 유지
- 권한 설정 성공 시에만 채널이 실제 활성화

**장점**:
- 완벽한 원자성 (둘 다 성공 또는 둘 다 실패)
- 고아 채널 생성 불가능
- 데이터 일관성 보장

**단점**:
- 구현 복잡도 높음
- API 설계 변경 필요

**구현 방식**:
1. Channel 엔티티에 status 필드 추가: "DRAFT" → "ACTIVE"
2. ContentService.createChannel()에서 DRAFT 상태로 생성
3. ChannelPermissionsDialog에서:
   - 모든 권한 설정 완료 후 updateChannelStatus(ACTIVE) 호출
   - 실패 시 트랜잭션 전체 롤백 또는 DRAFT 유지
4. getChannelsByWorkspace()에서 ACTIVE 채널만 필터링

---

### 옵션 3: 통합 API (추천: 성능 우선)

**개념**:
- 채널 생성 + 권한 설정을 단일 API로 통합
- 백엔드에서 트랜잭션으로 원자성 보장

**장점**:
- API 호출 1회로 통합 (N+1 → 1)
- 트랜잭션으로 원자성 완벽 보장
- 네트워크 성능 향상

**단점**:
- 프론트엔드/백엔드 API 설계 변경 필요
- 권한 정보를 미리 준비해야 함

**구현 방식**:
1. CreateChannelWithPermissionsRequest 추가
   - name, description, type
   - rolePermissions: Map<groupRoleId, Set<permission>>
2. ContentService.createChannelWithPermissions()
   - 채널 생성
   - 트랜잭션 내에서 권한 바인딩 생성 (반복)
   - 모두 성공 또는 모두 실패
3. 프론트엔드:
   - CreateChannelDialog에서 권한까지 수집
   - 또는 권한 수집 → 채널 생성 순서 유지

---

## 구현 체크리스트

### 기본 설계 검토
- [ ] 선택할 옵션 결정: 템플릿 / 상태 / 통합 API
- [ ] 트레이드오프 분석: 복잡도 vs 안전성 vs 성능
- [ ] 기술 리스크 검토

### API 설계
- [ ] 기존 API 유지 여부 (후방 호환성)
- [ ] 요청/응답 스키마 정의
- [ ] 에러 케이스 명세 (권한 검증 실패, 중복 채널명 등)
- [ ] 트랜잭션 경계 명확화

### 프론트엔드 구현
- [ ] CreateChannelDialog 플로우 수정
  - [ ] 권한 정보 수집 로직 (옵션에 따라)
  - [ ] isRequired 플래그 재검토
- [ ] ChannelPermissionsDialog 통합 여부
  - [ ] 별개 다이얼로그 유지 vs 통합
  - [ ] 기본값 설정 (옵션 1 선택 시)
- [ ] 에러 처리 및 사용자 안내
  - [ ] 권한 설정 취소 시 명확한 메시지
  - [ ] 부분 실패 시 복구 옵션

### 백엔드 구현
- [ ] ContentService 로직 수정
- [ ] Channel 엔티티 수정 (옵션 2 선택 시 status 필드)
- [ ] ChannelRoleBinding 생성 로직 일괄화 (옵션 3 선택 시)
- [ ] 권한 캐시 무효화 타이밍
- [ ] 동시성 제어 (중복 바인딩 방지)

### 데이터베이스
- [ ] Channel/ChannelRoleBinding 스키마 검토
- [ ] 외래키 제약 확인
- [ ] Cascade 설정 (삭제 시 자동 삭제)
- [ ] 인덱스 최적화

### 테스트
- [ ] 성공 케이스
  - [ ] 채널 생성 + 권한 설정 완료
  - [ ] 생성된 채널이 목록에 표시되는지
  - [ ] 올바른 역할만 접근 가능한지
- [ ] 실패 케이스
  - [ ] 권한 검증 실패 (그룹장 아님)
  - [ ] 중복 채널명
  - [ ] 권한 설정 실패 (중복 바인딩)
- [ ] 엣지 케이스
  - [ ] 권한 설정 취소 (고아 채널)
  - [ ] 부분 실패 (일부 역할만 설정)
  - [ ] 네트워크 끊김 (중간에 실패)
- [ ] 권한 재검증
  - [ ] POST_READ 필수 권한
  - [ ] 빈 권한 바인딩 허용 여부

### 문서화
- [ ] API 명세 (createChannelWithPermissions 등)
- [ ] UX 플로우 다이어그램 업데이트
- [ ] 개발 가이드 업데이트 (channel-creation.md)
- [ ] 권한 정책 명문화

### 배포 및 모니터링
- [ ] 마이그레이션 (기존 권한 0인 채널 처리)
- [ ] 로깅 및 모니터링 설정
- [ ] 성능 메트릭 수집

---

## 결론

**현재 상태**:
- 프론트엔드에서 isRequired=true로 권한 설정을 강제함
- 하지만 사용자가 권한 설정 다이얼로그를 취소하면 권한 0인 고아 채널이 생성됨

**개선 필요 여부**:
- **즉시**: 권한 설정 취소 시 사용자 안내 메시지 강화
- **단기**: 옵션 1 (기본 템플릿 자동 적용) 구현 권장
- **장기**: 옵션 3 (통합 API) 또는 옵션 2 (상태 기반) 검토

**다음 단계**:
1. 팀 내 논의: 어느 옵션을 선택할 것인가?
2. 선택된 옵션에 따른 상세 설계
3. 구현 및 테스트
