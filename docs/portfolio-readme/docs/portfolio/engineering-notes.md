# Univ Group Management 기술 결정과 개발 과정

## 랩실 앱에서 대학 조직 모델까지

초기 기획은 랩실 개설, 구성원 역할, 공지, 일정과 모집을 관리하는 앱이었습니다. 이후 같은 사용자도 대학, 학과, 자율 모임에 동시에 속할 수 있다는 점을 기준으로 그룹 범위를 넓혔습니다. 부모 관계와 조직 유형은 [Group 엔티티](https://github.com/SungKong00/univ_group_management/blob/134edd3/backend/src/main/kotlin/org/castlekong/backend/entity/Group.kt)에서 볼 수 있습니다. 초기 기획에 있던 면접 슬롯과 QR 출석은 제품 기능으로 옮겨 적지 않았습니다.

## 서버의 권한과 조회

- [PermissionService](https://github.com/SungKong00/univ_group_management/blob/134edd3/backend/src/main/kotlin/org/castlekong/backend/security/PermissionService.kt): 그룹 권한 캐시는 그룹 ID와 사용자 ID를 키로 쓰고, 60초 만료와 최대 1만 항목을 설정합니다. 이는 정책값이지 측정된 응답 시간은 아닙니다.
- [GroupRoleService](https://github.com/SungKong00/univ_group_management/blob/134edd3/backend/src/main/kotlin/org/castlekong/backend/service/GroupRoleService.kt)와 [ContentService](https://github.com/SungKong00/univ_group_management/blob/134edd3/backend/src/main/kotlin/org/castlekong/backend/service/ContentService.kt): 역할의 생성·수정·삭제에서 그룹 권한 캐시를 비우는 경로와, 콘텐츠 요청에서 실제 채널 바인딩을 읽는 경로는 별개입니다. 설정·이벤트가 존재하는 것만으로 콘텐츠 요청이 모두 캐시를 사용한다고 보지 않았습니다.
- [멤버 목록 N+1 개선 커밋](https://github.com/SungKong00/univ_group_management/commit/f923d4a): ID 페이지와 상세 fetch join을 두 단계로 나눴습니다. 테스트에는 그룹에 멤버 100명, 페이지 20명이라는 조건과 총 개수·로딩된 관계에 대한 검사가 있습니다. 테스트 메서드 이름과 달리 쿼리 개수를 직접 단언하지 않으므로, 총 SQL이 항상 두 번이라고 해석하지 않았습니다.

## URL과 상태, 일정의 쓰기 경로

- [GoRouter 구성](https://github.com/SungKong00/univ_group_management/blob/134edd3/frontend/lib/core/router/app_router.dart): 그룹 경로 아래 캘린더와 채널을 둡니다. [그룹 전환 작업](https://github.com/SungKong00/univ_group_management/commit/8f8fde9)은 권한과 최근 맥락을 포함해 전환을 다룬 이력입니다.
- 읽음 위치는 [Post ID 전환](https://github.com/SungKong00/univ_group_management/commit/5f1a9c3), [위젯 종료 후 콜백 수정](https://github.com/SungKong00/univ_group_management/commit/bbf64e5), [게시글 화면의 일부 읽음 기능 제거](https://github.com/SungKong00/univ_group_management/commit/027af0b)를 거쳤습니다. 서버에 있는 읽음 API와 모든 화면이 같은 정도로 지원된다고 보지 않았습니다.
- [GroupEventService](https://github.com/SungKong00/univ_group_management/blob/134edd3/backend/src/main/kotlin/org/castlekong/backend/service/GroupEventService.kt)와 [PlaceReservationService](https://github.com/SungKong00/univ_group_management/blob/134edd3/backend/src/main/kotlin/org/castlekong/backend/service/PlaceReservationService.kt): 반복 규칙을 회차들로 전개하고, 예약 가능 구간과 저장 시 충돌 검사를 별도로 처리합니다. 저장 전 조회를 한다는 사실만으로 동시 요청까지 직렬화된다고 주장하지 않습니다.
- 수정 비용이 커진 시점 이후, [별도 구조 실험](https://github.com/SungKong00/univ_group_management/commit/46e2c5e)에서 백엔드 도메인 경계를 재배치하고 프론트엔드 토큰·공용 컴포넌트를 체계화했습니다. 본 시연은 새 실험판이 아닌 기존 실행 앱입니다.

## 실험판에서 재사용 범위를 넓힌 이유

처음에는 Linear 스타일을 참고해 [테마 JSON과 컴포넌트 쇼케이스](https://github.com/SungKong00/univ_group_management/commit/83bce61)를 만들었습니다. 카드와 화면이 늘어날수록 큰 JSON에서 기존 값을 찾아 쓰기 어려워 같은 역할의 토큰이 다시 정의됐습니다. 이후 카드의 의미·색상, 반응형 크기, 여백을 용도에 따라 분리했고, [GridLayoutTokens](https://github.com/SungKong00/univ_group_management/commit/fdcc73b)는 고정 상수에서 화면 폭에 따라 값을 돌려주는 함수로 바꿨습니다. 카드가 화면 폭마다 각자 그리드를 계산하는 대신 토큰이 계산을 맡도록 옮기고 쇼케이스에서도 같은 함수를 사용했습니다.

인증에서도 비슷한 문제가 있었습니다. 한 계정의 토큰만 지우는 것으로는 그룹을 기억하는 상태까지 초기화되지 않았습니다. 계정 전환 문제를 추적한 뒤 [토큰 저장과 사용자 ID를 지켜보는 그룹 로딩](https://github.com/SungKong00/univ_group_management/commit/f78fada)을 함께 손봤습니다. 로컬 시연은 이 흐름에서 서로 다른 실제 사용자 세션을 각각 사용했습니다.

## 작업 폴더에서 검증 절차로

| 시기 | 고민 | 저장소에 남은 선택 |
| --- | --- | --- |
| 2025.09 초 | 모델을 바꾸면 작업 배경과 출처를 다시 설명해야 함 | [작업 패키지와 Bash 수집기](https://github.com/SungKong00/univ_group_management/commit/f46c35a). 작업 목표, 원문 출처, 합성된 맥락을 파일로 남김 |
| 2025.09 말 | 누적된 작업 폴더와 문서를 에이전트가 그대로 읽으면 기준이 섞임 | [누적 산출물을 걷어내고 역할 가이드로 전환](https://github.com/SungKong00/univ_group_management/commit/6c3e671). 권한, 테스트, 프론트엔드, 백엔드에 읽을 자료와 판단 기준을 분리 |
| 2025.10 | 요청이 모호한데 구현부터 진행하면 수정 범위가 계속 넓어짐 | [사전 확인·승인 절차](https://github.com/SungKong00/univ_group_management/commit/84a7100). 변경 범위와 문서 충돌을 먼저 밝히고 불확실하면 실행 보류 |
| 2025.11 | 요구사항과 구현 이후 문서가 어긋남 | [명세 기반 작업 규칙](https://github.com/SungKong00/univ_group_management/commit/0263cd4)과 [게이트 보강](https://github.com/SungKong00/univ_group_management/commit/ff84ff3). 계획과 작업 목록, 체크리스트와 사용자 결정을 연결 |

초기 구조의 자동화는 Bash 수집기에 해당합니다. 이후 파일들이 보여 주는 것은 역할 라우팅과 검증·승인 절차의 설계이며, 과거 모든 작업에서 자동으로 실행되었다는 뜻은 아닙니다.
