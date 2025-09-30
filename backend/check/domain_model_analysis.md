# 도메인 모델 및 관계 분석

이 문서는 백엔드 시스템의 핵심 도메인 엔티티(`Group`, `User`, `Workspace`, `Content` 등)의 설계와 그들 간의 관계를 JPA 엔티티 코드 기준으로 상세히 분석합니다.

## 분석 대상 핵심 엔티티

-   **주체**: `User`, `Group`
-   **멤버십/역할**: `GroupMember`, `GroupRole`, `GroupPermission`
-   **콘텐츠**: `Workspace`, `Channel`, `Post`, `Comment`
-   **권한(채널)**: `ChannelRoleBinding`, `ChannelPermission`
-   **프로세스**: `GroupJoinRequest`, `SubGroupRequest`, `EmailVerification`

## 1. 핵심 주체: `User`와 `Group`

모든 데이터는 `User`와 `Group`이라는 두 개의 핵심 축을 중심으로 구성됩니다.

### `User`

-   **역할**: 시스템에 로그인하는 개별 사용자입니다.
-   **식별**: `email` 필드를 고유 식별자로 사용합니다. (Google OAuth2 기준)
-   **주요 관계**:
    -   `Group`의 소유자(Owner)가 될 수 있습니다. (`One-to-Many`)
    -   여러 `Group`에 멤버로 참여할 수 있습니다. (`Many-to-Many`, `GroupMember` 통해 연결)
    -   `Post`, `Comment` 등 다양한 콘텐츠의 작성자(Author)가 됩니다. (`One-to-Many`)
-   **주요 속성**:
    -   `globalRole`: `STUDENT`, `PROFESSOR`, `ADMIN` 중 하나의 전역 역할을 가집니다.
    -   `profileCompleted`: 온보딩(추가 정보 입력) 완료 여부를 나타내는 상태 값.
    -   학적 정보 (`college`, `department`, `studentNo`) 및 프로필 정보 (`nickname`, `bio`)를 가집니다.

### `Group`

-   **역할**: 사용자들이 모여 활동하는 핵심 단위 공간(커뮤니티)입니다.
-   **주요 관계**:
    -   **소유자(Owner)**: 그룹을 최초 생성하고 최종 관리 권한을 가진 `User`. `Group`에서 `User`로의 `@ManyToOne` 관계이므로, **한 명의 사용자가 여러 그룹의 소유자가 될 수 있습니다.**
    -   **멤버**: 여러 `User`를 멤버로 가집니다. (`One-to-Many` with `GroupMember`)
    -   **계층 구조 (Self-join)**: `parent` 필드를 통해 다른 `Group`을 부모로 가질 수 있습니다. 이를 통해 `대학교 > 단과대학 > 학과` 같은 트리 구조를 형성합니다.
    -   **콘텐츠 소유**: `Workspace`, `Channel` 등 하위 콘텐츠를 소유합니다. (`One-to-Many`)
-   **주요 속성**:
    -   `groupType`: `UNIVERSITY`, `COLLEGE`, `DEPARTMENT`, `LAB`, `AUTONOMOUS`(자율), `OFFICIAL`(공식) 등 그룹의 성격을 정의합니다.
    -   `visibility`: `PUBLIC`, `PRIVATE`, `INVITE_ONLY` 등 그룹의 공개 범위를 설정합니다.

## 2. 그룹 멤버십과 역할/권한 모델 (L1: Group-Level)

그룹 내에서 사용자의 역할과 권한을 관리하는 모델입니다.

-   **`GroupMember` (조인 테이블)**: `User`와 `Group`의 다대다(N:M) 관계를 연결합니다. "어떤 `User`가 어떤 `Group`에 속해있다"를 나타냅니다.
    -   `@ManyToOne` 관계를 통해 `User`와 `Group`을 각각 연결합니다.
    -   **가장 중요한 점은, `GroupMember`가 `GroupRole`에 대한 `@ManyToOne` 관계를 가진다는 것입니다.** 이는 사용자가 그룹에 단순히 속하는 것을 넘어, 특정 역할을 부여받음을 의미합니다.

-   **`GroupRole`**: 그룹 내에서 사용되는 역할(e.g., "그룹장", "운영진", "신입생")을 정의합니다.
    -   `@ManyToOne` to `Group`: 각 그룹은 자신만의 커스텀 역할 세트를 가질 수 있습니다.
    -   `isSystemRole`: `true`일 경우, 시스템이 기본으로 생성하는 역할(그룹장, 멤버 등)임을 의미합니다.
    -   **`permissions` (`@ElementCollection`)**: 이 역할이 어떤 그룹 레벨 권한(`GroupPermission`)들을 갖는지를 `Set<GroupPermission>` 형태로 저장합니다. **역할과 권한을 맵핑하는 핵심 부분입니다.**

-   **`GroupPermission` (`enum`)**: 그룹 레벨에서 수행할 수 있는 동작들을 정의한 열거형입니다. (e.g., `GROUP_MANAGE`, `ADMIN_MANAGE`, `CHANNEL_MANAGE`)

> **요약**: `User` --joins--> `GroupMember` --has a--> `GroupRole` --has set of--> `GroupPermission`
> 한 유저는 그룹의 멤버로서 하나의 역할을 가지며, 그 역할은 여러 개의 그룹 권한을 포함합니다.

## 3. 콘텐츠 계층 구조

콘텐츠는 **`Group` -> `Workspace` -> `Channel` -> `Post` -> `Comment`** 의 명확한 하향식(Top-down) 계층 구조로 설계되었습니다.

-   **`Workspace`**: 그룹 내 콘텐츠를 담는 최상위 컨테이너입니다.
    -   `@ManyToOne` to `Group`: 자신이 속한 `Group`을 참조합니다.

-   **`Channel`**: 워크스페이스 내의 주제별 게시판 또는 대화 채널입니다.
    -   `@ManyToOne` to `Workspace`: 자신이 속한 `Workspace`를 참조합니다.
    -   `@ManyToOne` to `Group`: 데이터 조회 편의성을 위해 `Group`도 직접 참조합니다.

-   **`Post`**: 채널에 작성되는 게시글입니다.
    -   `@ManyToOne` to `Channel`: 자신이 속한 `Channel`을 참조합니다.
    -   `@ManyToOne` to `User` (`author`): 게시글 작성자를 참조합니다.

-   **`Comment`**: 게시글에 달리는 댓글입니다.
    -   `@ManyToOne` to `Post`: 자신이 속한 `Post`를 참조합니다.
    -   `@ManyToOne` to `User` (`author`): 댓글 작성자를 참조합니다.
    -   `@ManyToOne` to `Comment` (`parentComment`): 대댓글 기능을 위한 자기 참조(self-referencing) 관계입니다.

## 4. 세분화된 채널 권한 모델 (L2: Channel-Level)

그룹 전체에 적용되는 역할/권한(L1)과 별개로, 특정 채널에 대해서만 더 세분화된 권한을 적용하기 위한 모델입니다.

-   **`ChannelPermission` (`enum`)**: 채널 레벨에서 수행할 수 있는 동작들을 정의합니다. (e.g., `POST_READ`, `POST_WRITE`, `COMMENT_WRITE`)

-   **`ChannelRoleBinding` (조인 테이블)**: **`Channel`과 `GroupRole`을 연결**하여, 특정 채널에서 특정 역할이 어떤 권한을 갖는지를 정의합니다.
    -   `@ManyToOne` to `Channel`: 어떤 채널에 대한 권한 규칙인지 지정합니다.
    -   `@ManyToOne` to `GroupRole`: 어떤 역할에 이 규칙을 적용할지 지정합니다.
    -   **`permissions` (`@ElementCollection`)**: 해당 `GroupRole`이 해당 `Channel`에서 어떤 `ChannelPermission`들을 갖게 될지를 `Set<ChannelPermission>` 형태로 저장합니다.

> **사용 시나리오 예시**:
> "'일반 멤버'(`GroupRole`) 역할은 '공지사항'(`Channel`) 채널에서는 `ChannelRoleBinding`을 통해 `POST_READ`(`ChannelPermission`) 권한만 부여받고, '자유게시판'(`Channel`) 채널에서는 `POST_READ`, `POST_WRITE`, `COMMENT_WRITE` 권한을 모두 부여받는다."
> 이처럼 같은 역할이라도 채널별로 다른 활동 권한을 세분화하여 부여할 수 있는 유연한 구조를 제공합니다.

## 5. 프로세스 관련 엔티티

-   **`GroupJoinRequest`**: `User`가 `Group`에 가입을 신청하는 과정을 기록합니다. (신청자, 대상 그룹, 상태, 메시지 등)
-   **`SubGroupRequest`**: `User`가 특정 `Group`의 하위 그룹 생성을 요청하는 과정을 기록합니다.
-   **`EmailVerification`**: 학교 이메일 인증 시 사용되는 임시 인증 코드와 만료 시간 등을 관리합니다.

## 6. 자율그룹 vs 공식그룹 상세 분석

그룹 타입 중 사용자가 직접 생성하는 그룹의 핵심 분류인 `AUTONOMOUS`(자율그룹)과 `OFFICIAL`(공식그룹)에 대한 상세 분석입니다.

### 6.1. 자율그룹 (AUTONOMOUS)

-   **정의**: 부모 그룹 내 멤버들이 자유롭게 관심사나 특정 단기 목표를 위해 생성하는 비공식 그룹
-   **생성 특징**:
    -   승인 절차가 없거나 최소화
    -   시스템 기본값으로 설정 (`GroupType.AUTONOMOUS`)
    -   즉시 생성 허용
-   **운영 특징**:
    -   자율적인 운영, 상위 조직의 간섭 최소화
    -   멤버 간의 네트워킹이나 스터디 목적
    -   단기적이고 목적 지향적인 활동
-   **사용 사례**:
    ```
    DEPARTMENT 하위:
    - 코딩 테스트 스터디
    - 캡스톤 디자인 프로젝트 팀

    CLUB 하위:
    - 주말 등산 팟(번개 모임)
    - 공모전 준비팀
    ```

### 6.2. 공식그룹 (OFFICIAL)

-   **정의**: 부모 그룹의 공식적인 활동을 위해 생성되는 그룹
-   **생성 특징**:
    -   부모 그룹 관리자의 **필수 승인** 필요 (명세서상)
    -   공식적인 대표성 보유
    -   그룹의 공식 조직도에 표시
-   **운영 특징**:
    -   체계적인 관리 체계 하에 운영
    -   경우에 따라 예산 지원이나 별도 권한 부여 가능
    -   상위 조직과의 긴밀한 연계
-   **사용 사례**:
    ```
    DEPARTMENT 하위:
    - 졸업준비위원회
    - 신입생환영회 준비위원회

    CLUB 하위:
    - 운영진 그룹
    - 공연 연출팀
    - 회계팀
    ```

### 6.3. 현재 구현 상태

| 구분 | 자율그룹 | 공식그룹 | 구현 상태 |
|------|----------|----------|-----------|
| **데이터 모델** | `GroupType.AUTONOMOUS` | `GroupType.OFFICIAL` | ✅ 완료 |
| **API 필터링** | `groupType` 파라미터 지원 | `groupType` 파라미터 지원 | ✅ 완료 |
| **UI 표시** | '자율그룹' 필터 칩 | '공식그룹' 필터 칩 | ✅ 완료 |
| **승인 프로세스** | 즉시 생성 | 승인 필요 | ❌ 미구현 |
| **권한 차별화** | 기본 권한만 | 추가 권한/예산 | ❌ 미구현 |

### 6.4. 비즈니스 로직 차이점

**현재**: 두 타입 모두 동일한 생성/관리 프로세스

**설계 의도** (명세서 기준):
```kotlin
// 예상되는 차별화 로직 (미구현)
fun createGroup(request: CreateGroupRequest) {
    when (request.groupType) {
        GroupType.OFFICIAL -> {
            // 부모 그룹 관리자 승인 필요
            requireParentGroupApproval()
            // 공식 조직도에 표시
            addToOfficialHierarchy()
        }
        GroupType.AUTONOMOUS -> {
            // 즉시 생성 허용
            createDirectly()
        }
    }
}
```

## 결론: 설계 사상

-   **계층적 구조**: `Group`의 재귀적 관계와 `Group`부터 `Comment`까지 이어지는 콘텐츠의 하향식 구조는 전체 시스템을 명확하고 확장 가능하게 만듭니다.
-   **역할 기반 접근 제어 (RBAC)**: `User`에게 직접 권한을 부여하는 대신, `GroupRole`이라는 중간 계층을 두어 역할을 중심으로 권한을 관리합니다. 이는 유지보수성을 크게 향상시킵니다.
-   **다단계 권한 모델**: 그룹 전체에 적용되는 거시적인 권한(L1)과 채널별로 적용되는 미시적인 권한(L2)을 분리하여, 유연하고 세분화된 접근 제어를 가능하게 합니다.
-   **그룹 타입 분류**: `AUTONOMOUS`와 `OFFICIAL` 그룹 타입을 통해 자율적 활동과 공식적 활동을 구분하여 관리할 수 있는 유연한 구조를 제공합니다.
-   **관계의 명확성**: `@ManyToOne`, `@OneToMany` 등의 JPA 어노테이션을 통해 엔티티 간의 관계가 명확하게 정의되어 있으며, 대부분 지연 로딩(`FetchType.LAZY`)을 사용하여 성능을 최적화하고 있습니다.
