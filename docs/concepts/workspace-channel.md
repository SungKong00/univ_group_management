# 워크스페이스 & 채널 구조

## 구조 다이어그램

```
그룹 (Group) [1:1] 워크스페이스 (Workspace)
└── 그룹 워크스페이스 (자동 생성)
    ├── 일반대화 [텍스트 채널]
    ├── 공지사항 [텍스트 채널 - 공지 라벨]
    └── 기타 채널 [텍스트 채널]

추가 공간이 필요한 경우:
그룹 A → 하위 그룹 생성 → 별도 워크스페이스

워크스페이스 [1:N] 채널 (Channel) [1:N] 게시글 (Post) [1:N] 댓글 (Comment)
```

## 워크스페이스 개념

### 그룹-워크스페이스 1:1 매핑
- **자동 생성**: 그룹 생성 시 워크스페이스 자동 생성
- **동일 이름**: 그룹명과 워크스페이스명 동일
- **기본 채널**: 일반대화, 공지사항 채널 자동 생성
- **수명 연동**: 그룹 삭제 시 워크스페이스도 함께 삭제

### 추가 공간이 필요한 경우
- **하위 그룹 생성**: 프로젝트, 이벤트, 스터디 등을 위한 별도 그룹 생성
- **독립적 관리**: 각 그룹의 워크스페이스는 독립적으로 관리
- **계층 구조 활용**: 부모 그룹 → 하위 그룹 → 별도 워크스페이스

## 채널 타입

### TEXT (텍스트 채널) - 현재 유일한 채널 타입
```typescript
{
  type: "TEXT",
  features: ["게시글", "댓글", "파일첨부", "이모지반응"],
  use_cases: ["일반대화", "질문답변", "토론", "공지사항"]
}
```

**채널 라벨링 시스템**:
- **일반 채널**: 기본 텍스트 채널
- **공지 라벨**: 향후 중요 알림 기능을 위한 라벨링 (현재는 표시만)

### 향후 구현 예정 타입

#### VOICE (음성 채널) - 미구현
```typescript
{
  type: "VOICE",
  features: ["실시간 음성", "화면공유", "녹음"],
  status: "FUTURE_IMPLEMENTATION",
  priority: "LOW"
}
```

**참고**: 파일공유 채널은 필요없음 - 텍스트 채널에서 파일 첨부로 충분

## 채널 접근 제어

### 권한 기반 가시성
```kotlin
// 공개/비공개 개념 제거
// 권한이 있으면 네비게이션에 표시, 없으면 숨김
if (hasChannelPermission(userId, channelId, "READ")) {
    showInNavigation(channel)
} else {
    hideFromNavigation(channel)
}
```

### 채널 권한 체계
```kotlin
ChannelPermission {
    READ,     // 채널 존재 확인 + 게시글 읽기
    WRITE,    // 게시글/댓글 작성
    MANAGE,   // 채널 설정 변경
    DELETE    // 채널 삭제
}
```

**핵심 원칙**:
- READ 권한이 있는 사용자만 채널을 볼 수 있음
- 권한이 없으면 채널 존재 자체를 알 수 없음
- 별도의 공개/비공개 설정 없이 권한으로만 제어

## 컨텐츠 구조

### 게시글 (Post)
```typescript
{
  id: number,
  title?: string,           // 제목 (선택적)
  content: string,          // 본문 (필수)
  type: "GENERAL" | "ANNOUNCEMENT" | "QUESTION" | "POLL",
  author: User,
  channel: Channel,
  isPinned: boolean,        // 상단 고정
  viewCount: number,        // 조회수
  createdAt: DateTime,
  updatedAt: DateTime
}
```

### 댓글 (Comment)
```typescript
{
  id: number,
  content: string,
  author: User,
  post: Post,
  parentComment?: Comment,  // 대댓글 지원
  depth: number,           // 댓글 깊이 (최대 2단계)
  createdAt: DateTime,
  updatedAt: DateTime
}
```

## 채널 UI 패턴

### 채널 목록 (사이드바)
```
📢 공지사항 [공지 라벨]
💬 일반대화
💬 자유게시판
💬 운영진전용 [READ 권한 제한]
```

### 게시글 목록 (메인 컨텐츠)
```
[📌 고정] 신입 모집 안내
[👤 김철수] 스터디 참여자 모집
[👤 이영희] 프로젝트 아이디어 공유
[👤 박민수] 질문이 있습니다
```

### 채팅형 UI (실시간 소통)
```
김철수 | 오후 2:30
안녕하세요! 신입 가입 문의드립니다.

이영희 | 오후 2:31
@김철수 환영합니다! 가입 절차는...

[메시지 입력창]
```

## 채널 생성 플로우

### 1. 채널 생성 권한 확인
```kotlin
@PreAuthorize("@security.hasGroupPerm(#groupId, 'CHANNEL_WRITE')")
fun createChannel(workspaceId: Long, request: CreateChannelRequest)
```

### 2. 자동 설정
```typescript
POST /api/workspaces/{id}/channels
{
  "name": "개발논의",
  "type": "TEXT",  // 또는 "ANNOUNCEMENT"
  "isPrivate": false,
  "description": "개발 관련 논의"
}
```

### 3. 채널 역할 바인딩 생성
- **ChannelRoleBinding**: 그룹 역할별로 채널 권한 설정
- **기본 바인딩**: OWNER와 MEMBER 역할에 대한 기본 권한 자동 설정
- **가시성**: CHANNEL_VIEW 권한이 있어야 네비게이션에 표시

## 실제 사용 시나리오

### 시나리오 1: 동아리 기본 구성
1. 프로그래밍 동아리 생성
2. 동아리 워크스페이스 자동 생성
3. 기본 채널 구성:
   - 📢 공지사항 [ANNOUNCEMENT 타입, OWNER만 POST_WRITE 권한]
   - 💬 자유게시판 [TEXT 타입, 모든 멤버 POST_WRITE 권한]

### 시나리오 2: 프로젝트 별도 공간 필요
1. "해커톤 프로젝트팀" 하위 그룹 생성
2. 프로젝트팀 워크스페이스 자동 생성
3. 프로젝트 전용 채널 구성:
   - 💭 아이디어 논의
   - 👨‍💻 개발 진행상황
   - 📋 회의록
   - 🐛 버그 리포트
4. 프로젝트 종료 시 그룹 비활성화 또는 삭제

### 시나리오 3: 모집 시즌 운영
1. "신입 모집" 하위 그룹 생성
2. 모집팀 워크스페이스 자동 생성
3. 모집 전용 채널 구성:
   - 📝 지원서 접수 [지원자 write 권한]
   - ❓ 질문답변 [지원자 read/write 권한]
   - 📅 면접 일정 [공지 라벨, 운영진만 write]
4. 모집 종료 후 그룹 삭제 또는 다른 용도로 전환

### 시나리오 4: 대규모 이벤트 조직
1. "학과 축제" 이벤트 그룹 생성
2. 이벤트별 하위 그룹들 생성:
   - "기획위원회" 그룹 → 별도 워크스페이스
   - "대외협력팀" 그룹 → 별도 워크스페이스
   - "현장운영팀" 그룹 → 별도 워크스페이스
3. 각 팀별 독립적인 소통 공간 확보

## 관련 구현

### API 참조
- **워크스페이스 관리**: [../implementation/api-reference.md#워크스페이스](../implementation/api-reference.md#워크스페이스)
- **채널 관리**: [../implementation/api-reference.md#채널관리](../implementation/api-reference.md#채널관리)
- **컨텐츠 API**: [../implementation/api-reference.md#컨텐츠](../implementation/api-reference.md#컨텐츠)

### 데이터베이스 설계
- **Workspace 엔티티**: [../implementation/database-reference.md#Workspace](../implementation/database-reference.md#Workspace)
- **Channel 엔티티**: [../implementation/database-reference.md#Channel](../implementation/database-reference.md#Channel)

### UI/UX 설계
- **레이아웃 가이드**: [../ui-ux/layout-guide.md](../ui-ux/layout-guide.md)
- **컴포넌트 가이드**: [../ui-ux/component-guide.md](../ui-ux/component-guide.md)

### 관련 개념
- **그룹 계층**: [group-hierarchy.md](group-hierarchy.md)
- **권한 시스템**: [permission-system.md](permission-system.md)