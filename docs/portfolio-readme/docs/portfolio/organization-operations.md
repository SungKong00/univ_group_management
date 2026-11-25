# Univ Group Management 조직 운영과 권한

## 상위 조직의 승인과 하위 팀의 운영을 분리했습니다

학생회에 산하 팀을 추가할 때는 그룹을 바로 만들지 않고 개설 요청을 저장합니다. 상위 조직의 그룹장이 승인하면 신청자를 새 팀의 그룹장으로 지정하고, 전용 워크스페이스와 기본 공지·자유게시판 채널을 생성합니다. 하위 그룹을 목록에서 분류하는 일과 개별 조직의 권한을 부여하는 일은 다른 문제였습니다. 상위 그룹장이 심사했다는 이유만으로 하위 팀의 게시판·멤버를 자동 관리하게 하지 않았습니다.

그룹 구조는 대학·단과대·학과·연구실 같은 소속과 공식·자율 그룹을 한 트리에 담습니다. 팀을 만드는 요청과 기존 그룹에 가입하는 요청은 각각 다른 상태와 결과를 가집니다. 가입 승인의 결과는 기존 그룹에 멤버가 추가되는 것이고, 개설 승인의 결과는 새 그룹이 생기는 것입니다.

[요청·승인 서비스](https://github.com/SungKong00/univ_group_management/blob/134edd3/backend/src/main/kotlin/org/castlekong/backend/service/GroupRequestService.kt) · [그룹과 기본 구성 생성](https://github.com/SungKong00/univ_group_management/blob/134edd3/backend/src/main/kotlin/org/castlekong/backend/service/GroupInitializationService.kt)

## 한 사람이 여러 조직에 속해도 권한은 섞이지 않습니다

역할은 그룹 단위로 지정합니다. 그룹별로 누구에게 채널·멤버·모집 등의 관리 권한을 위임할지 정할 수 있습니다. 실제 구현에서 시스템 역할은 수정·삭제할 수 없고, 다른 그룹의 역할을 가져와 멤버에게 지정하지 않습니다. 멤버가 가진 그룹 역할과 채널의 역할 바인딩을 합쳐 그 사람이 읽기, 글 작성, 댓글 작성, 파일 첨부를 할 수 있는지 판단합니다. 채널 설정을 바꿀 수 있다고 해서 그 채널에 자동으로 글을 쓸 수 있는 것은 아닙니다.

| 기능 | 할 수 있는 조건 | 해당 권한이 없을 때 |
| --- | --- | --- |
| 하위 그룹 개설 요청 | 앱의 그룹 홈에서 관리 권한이 있는 역할에 진입 버튼을 노출 | 일반 멤버 화면에는 해당 버튼이 노출되지 않음 |
| 하위 그룹 신청 심사 | 요청을 받은 상위 그룹의 그룹장 | 그 그룹을 관리하는 다른 역할이라도 그룹장 심사 범위를 자동으로 갖지 않음 |
| 커스텀 역할 정의 | 해당 그룹에서 역할을 관리할 수 있는 경로, 생성·수정 시 서버의 그룹장 검사 | 그룹 밖의 역할이나 시스템 역할을 임의 수정할 수 없음 |
| 채널 개설과 바인딩 설정 | 해당 그룹의 채널 관리 권한 | 관리 기능을 사용하지 못함. 채널 글 읽기·쓰기는 별도 판단 |
| 읽기 전용 채널 | 해당 채널에서 자신의 역할에 게시글 읽기 허용 | 읽기 바인딩이 없으면 일반 채널 목록에서 보이지 않음. 읽기만 있으면 작성 불가 |
| 공지 채널 게시 | 해당 그룹의 공지 채널에 자신의 역할이 글 작성 권한 보유 | 읽기가 있으면 볼 수 있지만 작성 불가. 상위 조직에 게시할 권한을 자동으로 얻지 않음 |
| 공식 일정 등록 | 그룹의 캘린더 관리 권한 | 일반 멤버는 비공식 그룹 일정 작성 흐름으로 진입 |
| 비공식 일정 등록·편집 | 그룹 멤버가 등록. 편집은 작성자 또는 캘린더 관리자 | 그룹 멤버라는 이유만으로 다른 구성원의 일정을 수정할 수 없음 |

[그룹 역할 서비스](https://github.com/SungKong00/univ_group_management/blob/134edd3/backend/src/main/kotlin/org/castlekong/backend/service/GroupRoleService.kt) · [콘텐츠 권한 판정](https://github.com/SungKong00/univ_group_management/blob/134edd3/backend/src/main/kotlin/org/castlekong/backend/service/ContentService.kt) · [그룹 일정 서비스](https://github.com/SungKong00/univ_group_management/blob/134edd3/backend/src/main/kotlin/org/castlekong/backend/service/GroupEventService.kt)

## 공지와 모임에서 어디까지 이어지는지

- **그룹별 공지:** 새로 승인된 팀 공지 채널에 게시한 글은 해당 채널에 저장됩니다. 상위 학생회의 공지 목록에는 자동 발행되지 않습니다. 여러 조직의 공지를 한 화면에서 관리하고 작성 가능한 그룹으로 대상을 좁히는 방식은 별도의 설계 기록으로 남겼습니다.
- **멤버 명단:** 멤버 명단에는 역할 필터와 소속·학적 필터가 있습니다. 역할로 조회할 때는 소속 그룹, 학년, 입학년도 조건을 함께 사용하지 않습니다. 학년과 입학년도를 함께 선택하면 둘 중 하나를 만족하는 멤버를 포함합니다. 지정 조건을 이어가는 방식과 그 시점의 명단을 확정하는 방식은 서로 다른 모델입니다. 명단이나 미리보기 API가 있다는 이유로 그 결과가 공지나 투표의 실제 수신자로 연동되었다고 보지는 않았습니다.
- **모임과 공식 일정:** 구성원이 만드는 비공식 그룹 일정과 캘린더 운영자가 만드는 공식 일정을 나눴습니다. 공식 일반 일정은 그룹 캘린더에서 확인할 수 있습니다. 대상 지정과 참여 신청 유형은 화면·모델에 표현되어 있지만 현 버전에서는 준비 중으로 표시됩니다.
- **투표:** 게시글 유형에는 POLL이 있고 활동 피드 기획에도 투표가 있습니다. 그룹 홈의 ‘다음 주 정기 모임 일정 투표’는 예시 문구입니다. 선택지 등록, 투표 제출, 집계를 이어주는 UI와 API는 이 버전에서 확인되지 않아 작동 시연에 넣지 않았습니다.

[통합 공지 기획 메모](https://github.com/SungKong00/univ_group_management/blob/134edd3/specs/013-announcement-board-feature/MEMO.md) · [멤버 선택 흐름](https://github.com/SungKong00/univ_group_management/blob/134edd3/docs/features/member-selection-flow.md) · [활동 피드 기획](https://github.com/SungKong00/univ_group_management/blob/134edd3/docs/ui-ux/pages/my-activity-page.md)
