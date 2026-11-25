# Univ Group Management

**학과와 동아리의 공지, 소통, 모집, 일정을 하나의 그룹 공간에서 관리하는 대학 조직 플랫폼입니다.**

학교 안에서 같은 학생이 학과 구성원이면서 동아리 운영진일 수 있습니다. 학과 공지는 전체 학생이 보되 작성은 운영진에게 맡기고, 동아리에서는 팀별로 별도 채널을 열 수 있어야 합니다. 메신저, 모집 폼, 시간표를 따로 쓰면서 이런 운영 규칙이 도구 밖에 남는 문제에서 출발했습니다.

2025년 9~12월에 진행한 개인 프로젝트입니다. 기획부터 조직·권한 모델, Kotlin 백엔드, Flutter 화면, 테스트와 개발 도구까지 맡았습니다. 처음에는 랩실 운영을 기준으로 기획했고, 이후 대학의 공식 계층과 자율 모임을 함께 다룰 수 있도록 범위를 넓혔습니다.

[시연](#시연) · [시스템 구조](#시스템-구조) · [기술적 고민](#기술적-고민) · [AI 개발 워크플로](#ai-개발-워크플로) · [로컬 실행](#로컬-실행)

## 주요 기능

| 기능 | 학생·멤버 | 그룹 운영자 |
| --- | --- | --- |
| 조직과 워크스페이스 | 소속 그룹을 찾고 그룹 홈과 채널로 전환 | 대학·단과대·학과·연구실 등 조직 관계와 그룹 운영 범위 설정 |
| 채널과 콘텐츠 | 공지 읽기, 자유게시판에 글 작성, 댓글로 대화 | 채널 만들기, 역할별 읽기·작성 권한 설정 |
| 일정과 장소 | 주간 시간표와 개인 캘린더, 그룹 행사 확인 | 그룹 캘린더에서 행사·반복 일정 관리, 장소별 예약 가능 시간 확인 |
| 모집 | 공고의 질문에 답하고 지원 | 공고, 지원자 답변과 심사 상태 관리 |

## 시연

### 1. 학생 · 학교 계층에서 코딩 스터디 찾기

대학 → 계열 → 학과로 이어지는 계층을 열어 소속을 확인합니다. 목록에서 **코딩 스터디**를 검색하면 학과 아래에 속한 해당 그룹만 남습니다.

![학생이 대학 계층을 탐색하고 코딩 스터디로 목록을 좁히는 화면](docs/portfolio-readme/docs/portfolio/media/explorer.gif)

**iPhone 앱**

![iPhone 앱에서 학교와 학과를 펼치고 코딩 스터디를 찾는 화면](docs/portfolio-readme/docs/portfolio/media/ios/iphone-explorer.gif)

### 2. 학생 · 공지 읽기와 자유게시판 작성

공지사항에서는 일반 멤버의 작성 입력창이 비활성화됩니다. 자유게시판으로 바꿔 스터디 안내를 쓰면, 전송한 글이 작성자와 함께 채널에 표시됩니다.

![공지 채널에서 자유게시판으로 바꿔 실제 글을 작성하는 화면](docs/portfolio-readme/docs/portfolio/media/discussion.gif)

**iPhone 앱**

![iPhone 앱에서 공지를 읽고 자유게시판에 스터디 글을 올리는 화면](docs/portfolio-readme/docs/portfolio/media/ios/iphone-discussion.gif)

### 3. 운영자 · 행사 채널을 만들고 읽을 역할 지정

그룹장이 ‘행사 준비’ 채널에 설명을 쓰고 읽을 역할을 지정합니다. 저장 후 채널이 워크스페이스에 추가됩니다.

![그룹장이 행사 준비 채널을 만들고 역할의 읽기 권한을 지정하는 화면](docs/portfolio-readme/docs/portfolio/media/channel.gif)

**iPhone 앱**

![iPhone 앱에서 운영자가 채널을 만들고 읽기 역할을 지정하는 화면](docs/portfolio-readme/docs/portfolio/media/ios/iphone-channel.gif)

### 4. 학생 · 시간표에서 개인 캘린더로 전환하고 일정 저장

주간 수업 시간표를 확인하고 캘린더 탭으로 이동합니다. ‘포트폴리오 스터디’를 추가하고 선택한 날의 일정 목록에서 확인합니다.

![학생이 시간표를 확인하고 개인 캘린더에 스터디 일정을 저장하는 화면](docs/portfolio-readme/docs/portfolio/media/personal.gif)

**iPhone 앱**

![iPhone 앱에서 시간표를 확인하고 개인 일정에 스터디를 저장하는 화면](docs/portfolio-readme/docs/portfolio/media/ios/iphone-personal.gif)

### 5. 멤버 · 그룹 캘린더에 스터디 모임 등록

개인 시간이 아닌 소속 그룹 안에서 ‘오픈소스 스터디 첫 모임’을 만듭니다. 저장 후 그룹 달력의 선택 날짜에 모임이 표시됩니다.

![멤버가 그룹 캘린더에서 스터디 모임을 만드는 화면](docs/portfolio-readme/docs/portfolio/media/group-event.gif)

**iPhone 앱**

![iPhone 앱에서 멤버가 그룹 모임을 캘린더에 등록하는 화면](docs/portfolio-readme/docs/portfolio/media/ios/iphone-group-event.gif)

### 6. 운영자 · 장소를 고르고 예약 확인

장소 캘린더에서 세미나실을 필터링한 뒤 발표 리허설 예약을 추가합니다. 장소, 시간, 예약자가 달력에 표시됩니다.

![세미나실을 선택해 발표 리허설을 예약하고 달력에서 확인하는 화면](docs/portfolio-readme/docs/portfolio/media/group-calendar.gif)

**iPhone 앱**

![iPhone 앱에서 세미나실을 예약하고 그룹 일정에서 확인하는 화면](docs/portfolio-readme/docs/portfolio/media/ios/iphone-group-calendar.gif)

### 7. 학생 · 학생회 공고에 지원

학생회 행사기획팀 공고에서 질문 두 개에 답해 제출합니다. 공고의 버튼이 ‘지원 완료’로 바뀝니다.

![학생이 학생회 공고를 읽고 답변을 제출하는 화면](docs/portfolio-readme/docs/portfolio/media/recruit.gif)

**iPhone 앱**

![iPhone 앱에서 행사기획팀 공고에 지원하는 화면](docs/portfolio-readme/docs/portfolio/media/ios/iphone-recruit.gif)

### 8. 학생회 운영자 · 방금 접수된 지원 승인

운영자가 같은 지원을 찾아 승인합니다. 상태가 ‘대기 중’에서 ‘승인됨’으로 바뀌고, 승인된 지원자가 그룹 멤버로 연결됩니다.

![학생회 운영자가 같은 지원서를 승인하는 화면](docs/portfolio-readme/docs/portfolio/media/recruit-admin.gif)

**iPhone 앱**

![iPhone 앱에서 운영자가 같은 공고의 지원서를 승인하는 화면](docs/portfolio-readme/docs/portfolio/media/ios/iphone-recruit-admin.gif)

## 조직 운영 심화 시연

산하 조직을 만들고 권한을 위임한 뒤, 운영자와 멤버 화면에서 무엇이 달라지는지 확인합니다.

| 역할 | 가능한 일 | 역할만으로 할 수 없는 일 |
| --- | --- | --- |
| 상위 조직 그룹장 | 해당 조직에 들어온 산하 팀 개설 요청 심사 | 산하 팀의 채널과 멤버를 자동으로 관리 |
| 산하 팀 그룹장 | 자기 팀의 역할 구성, 채널 운영, 팀 공지 | 상위 조직이나 다른 팀에 같은 권한으로 게시 |
| 채널 관리 권한을 받은 운영진 | 자기 조직에서 채널 개설과 권한 설정 | 읽기나 쓰기 바인딩 없이 해당 채널의 콘텐츠 열람·작성 |
| 읽기 전용 역할 | 읽기 권한을 받은 채널에서 게시글 확인 | 작성 권한이 없는 채널에 게시 |
| 일반 멤버 | 열려 있는 채널 이용, 비공식 그룹 일정 등록 | 공식 일정 등록, 관리 권한 없이 타인의 일정 수정 |

### 산하 팀 개설 · 신청자와 승인자

학생회 구성원이 산하 팀 개설을 신청합니다. 상위 학생회 그룹장이 승인하면 신청자가 새 팀의 그룹장이 되고, 그 팀에 공지와 자유게시판이 생깁니다. 기존 그룹의 가입 승인과는 다른 흐름입니다.

**웹 · 산하 팀 개설 신청**

![웹 · 산하 팀 개설 신청](docs/portfolio-readme/docs/portfolio/media/organization/hierarchy_request.gif)

**웹 · 상위 조직의 심사와 승인**

![웹 · 상위 조직의 심사와 승인](docs/portfolio-readme/docs/portfolio/media/organization/hierarchy_approve.gif)

**iPhone 앱 · 산하 팀 개설 신청**

![iPhone 앱 · 산하 팀 개설 신청](docs/portfolio-readme/docs/portfolio/media/organization/iphone-hierarchy_request.gif)

**iPhone 앱 · 상위 조직의 심사와 승인**

![iPhone 앱 · 상위 조직의 심사와 승인](docs/portfolio-readme/docs/portfolio/media/organization/iphone-hierarchy_approve.gif)

### 운영진 역할 만들기와 배정

먼저 대학 그룹에서 채널 관리만 위임하는 ‘축제 운영진’을 정의하고 최하린에게 배정합니다. 같은 사람이 속한 학생회의 ‘학생회 간부’ 역할은 바뀌지 않습니다. 웹에서는 배정까지, iPhone 앱에서는 권한을 골라 역할을 만드는 단계까지 보여줍니다.

**웹 · 운영진 역할 정의와 멤버 배정**

![웹 · 운영진 역할 정의와 멤버 배정](docs/portfolio-readme/docs/portfolio/media/organization/org_role.gif)

**iPhone 앱 · 채널 관리만 가능한 역할 만들기**

![iPhone 앱 · 채널 관리만 가능한 역할 만들기](docs/portfolio-readme/docs/portfolio/media/organization/iphone-org_role.gif)

**웹 · 운영진 역할로 멤버 명단 좁히기**

![웹 · 운영진 역할로 멤버 명단 좁히기](docs/portfolio-readme/docs/portfolio/media/organization/org_filter.gif)

### 채널 접근과 글 쓰기

그룹에서 맡은 역할과 채널별 열람·작성 권한은 따로 판단합니다. 운영자가 ‘동아리 운영 자료’를 열어 ‘축제 운영진’에게 읽기만 허용하면, 해당 운영진은 채널을 열어도 글을 쓸 수 없습니다. 읽기 권한을 받지 않은 일반 멤버의 채널 목록에는 나타나지 않습니다.

**웹 · 운영진에게만 게시글 읽기를 허용한 채널 만들기**

![웹 · 운영진에게만 게시글 읽기를 허용한 채널 만들기](docs/portfolio-readme/docs/portfolio/media/organization/org_binding.gif)

**웹 · 운영진 계정에서 글 작성이 막힌 화면**

![웹 · 운영진 계정에서 글 작성이 막힌 화면](docs/portfolio-readme/docs/portfolio/media/organization/org_readonly.gif)

**iPhone 앱 · 읽기 권한만 있는 운영진의 채널 화면**

![iPhone 앱 · 읽기 권한만 있는 운영진의 채널 화면](docs/portfolio-readme/docs/portfolio/media/organization/iphone-org_readonly.gif)

### 공지 · 상위 조직과 산하 팀

산하 팀의 그룹장이 팀 공지 채널에 행사 안내를 게시합니다. 같은 글은 상위 학생회의 공지 채널에 자동으로 올라가지 않습니다. 여러 조직의 공지를 한 화면에서 관리하거나 대상을 골라 발행하는 기능은 그룹별 게시와 별도로 설계했습니다.

**웹 · 새로 승인된 팀의 공지 채널에 글 작성**

![웹 · 새로 승인된 팀의 공지 채널에 글 작성](docs/portfolio-readme/docs/portfolio/media/organization/org_notice.gif)

**iPhone 앱 · 산하 팀 공지 채널에 글 작성**

![iPhone 앱 · 산하 팀 공지 채널에 글 작성](docs/portfolio-readme/docs/portfolio/media/organization/iphone-org_notice.gif)

### 모임 · 멤버 일정과 공식 일정

멤버가 만드는 비공식 그룹 모임은 기존 시연 5번에서 볼 수 있습니다. 아래에서는 운영자가 공식 일반 일정을 등록하고 그룹 캘린더에서 확인합니다. 해당 버전에서 대상 지정형 일정과 참여 신청 유형은 별도로 구분됩니다.

**웹 · 그룹의 공식 일반 일정 등록**

![웹 · 그룹의 공식 일반 일정 등록](docs/portfolio-readme/docs/portfolio/media/organization/org_official.gif)

**iPhone 앱 · 그룹의 공식 일반 일정 등록**

![iPhone 앱 · 그룹의 공식 일반 일정 등록](docs/portfolio-readme/docs/portfolio/media/organization/iphone-org_official.gif)

**투표와 통합 공지:** 회의 일정 투표는 기획과 화면 예시에 남아 있고, 선택지 등록·투표·집계까지 이어지는 기능은 확인되지 않았습니다. 아래 상세 문서에 현재 동작하는 그룹별 공지·일정과 별도로 정리했습니다.

[조직 운영과 권한 상세](docs/portfolio-readme/docs/portfolio/organization-operations.md)

## 시설 운영과 반복 일정

예약하는 화면 외에, 시설을 관리하는 쪽에도 별도의 흐름이 있습니다. 학생회는 세미나실의 운영시간과 휴무를 설정하고, 멤버는 그룹 달력에서 반복 모임을 관리합니다.

### 시설 운영 · 세미나실 운영시간과 임시 휴무

학생회가 관리하는 세미나실에서 요일별 운영시간과 브레이크 타임을 확인합니다. 장비 점검일을 전일 휴무로 저장한 뒤, 그날의 가용시간 목록이 비는 것까지 확인했습니다. 매주 반복되는 제한 시간과 특정 날짜의 휴무를 나눠 관리합니다.

![웹에서 세미나실의 전일 휴무를 설정하는 화면](docs/portfolio-readme/docs/portfolio/media/facility/more_facility.gif)

**iPhone 앱**

![iPhone 앱에서 세미나실 임시 휴무를 등록하는 화면](docs/portfolio-readme/docs/portfolio/media/facility/iphone-more_facility.gif)

### 그룹 일정 · 정기 모임을 여러 회차로 등록

멤버가 스터디 날짜를 3일에 걸쳐 매일 반복하도록 등록합니다. 달력에는 회차별 일정이 나타나고, 서버에는 같은 반복 묶음의 일정 3건이 저장됩니다. 수정·삭제할 때는 한 회차와 이후 회차를 구분하는 구조입니다.

![웹에서 매일 반복되는 스터디 일정을 등록하는 화면](docs/portfolio-readme/docs/portfolio/media/facility/more_repeat.gif)

**iPhone 앱**

![iPhone 앱에서 매일 반복되는 스터디 일정을 등록하는 화면](docs/portfolio-readme/docs/portfolio/media/facility/iphone-more_repeat.gif)

### API에서 찾은 다른 기능

다른 그룹의 시설 사용 신청과 승인·회수, 개인 일정과 수업 시간표의 개별 편집, 채널의 읽은 위치와 읽지 않은 글 수, 공고 마감·보관과 지원 철회까지 확인했습니다. 아래 인덱스에 실제 앱 화면에서 연결된 흐름과 API·위젯으로만 확인한 기능을 구분했습니다.

- [시설·일정 및 추가 기능 근거](docs/portfolio-readme/docs/portfolio/facilities-and-scheduling.md)
- [백엔드 HTTP API 인덱스](docs/portfolio-readme/docs/portfolio/api-inventory.md)

## 시스템 구조

![시스템 구조: Flutter Web, Spring Boot API, 권한 평가, JPA 데이터](docs/portfolio-readme/docs/portfolio/diagrams/system.png)

Flutter 앱의 URL과 화면 상태는 GoRouter와 Riverpod으로 관리합니다. Spring Boot에서는 요청을 받은 뒤에 그룹·콘텐츠·일정별 서비스가 조직 규칙과 권한을 판단하고 JPA로 데이터를 조회하거나 저장합니다. 화면에서 작성 버튼을 숨기더라도 서버가 요청의 권한을 다시 판단합니다.

<details>
<summary>실행 환경 및 채널 권한 흐름</summary>

![실행 환경](docs/portfolio-readme/docs/portfolio/diagrams/runtime.png)

![채널 권한 흐름](docs/portfolio-readme/docs/portfolio/diagrams/workspace-policy.png)

</details>

| 영역 | 기술 |
| --- | --- |
| 웹·iPhone 앱 | Flutter 3.35, Dart 3.9, Riverpod, GoRouter, Dio |
| 백엔드 | Kotlin 1.9.25, Java 17, Spring Boot 3.5.5, JPA/Hibernate |
| 인증·저장 | Google OAuth 2.0, JWT, H2 개발 DB, Caffeine, PostgreSQL 운영 대상 드라이버 |
| 검증 | JUnit 5, Spring Boot Test, Flutter Test |

## 기술적 고민

### 1. 조직에서 맡은 역할과 채널에서 할 수 있는 일을 분리했습니다

학생회 운영진이라는 역할 하나만으로는 공지, 자유게시판, 행사 준비 채널이 각기 다른 이유로 열려 있다는 점을 표현할 수 없었습니다. 채널마다 새 역할을 정의하는 방식도 생각할 수 있지만, 채널이 늘 때마다 조직의 역할 체계까지 커집니다. 대신 **그룹 역할은 누구인지, 채널 바인딩은 그 역할이 특정 채널에서 무엇을 할 수 있는지**를 나타내도록 분리했습니다.

워크스페이스의 목록과 콘텐츠 API가 권한을 따로 판단합니다. 예를 들어 공지 채널에는 일반 멤버 읽기를 열어두고, 자유게시판에서만 작성할 수 있도록 설정할 수 있습니다. 일반 콘텐츠 검사에서 채널과 역할에 해당하는 바인딩이 없으면 허용하지 않습니다. 역할 하나로 모든 화면을 제어하는 대신 초기 채널을 만들 때 설정할 값이 늘었고, 읽기 권한을 하나 이상 지정하도록 생성 화면에서 확인합니다.

### 2. 멤버 목록의 페이지 경계와 연관 데이터 로딩을 분리했습니다

멤버 카드에 이름·그룹·역할을 표시하기 시작하면서, 멤버를 조회한 뒤 카드마다 연관 정보에 접근하는 문제가 드러났습니다. 반대로 컬렉션까지 한꺼번에 조인한 결과를 그대로 페이지로 자르면 행이 늘어나 멤버 기준으로 페이지를 설명하기 어렵습니다.

먼저 **현재 페이지에 해당하는 멤버 ID**를 가져오고, 이어 그 ID 집합의 사용자·그룹·역할 정보를 fetch join으로 조회하는 방식으로 바꿨습니다. 기본 목록은 두 조회 모두 가입일 내림차순으로 정렬합니다. 별도 목록 쿼리를 관리하는 비용이 생겼지만, 페이지의 기준이 되는 회원과 화면에 필요한 세부 조회를 분리할 수 있었습니다. 빈 페이지에서는 상세 조회를 하지 않습니다.

그룹 권한을 반복해서 계산하는 경로에는 분산 캐시 대신 프로세스 내 Caffeine을 두었습니다. 권한 집합을 그룹과 사용자 단위로 저장하고 역할 변경 시 그룹 범위를 무효화합니다. 단일 프로세스에서 외부 캐시를 운영하지 않아도 되지만, 인스턴스를 여러 개 두면 무효화 신호를 어떻게 공유할지 별도 설계가 필요합니다.

### 3. 그룹 전환에서 URL, 권한, 화면 상태를 한곳에 모았습니다

그룹과 채널을 오갈 때마다 화면을 명령형으로 쌓으면 뒤로가기가 어느 그룹으로 돌아가는지, 새로고침하면 어느 채널을 다시 여는지, 권한이 달라졌을 때 어떻게 빠져나오는지가 각 화면 코드로 흩어집니다. 특히 로그아웃 후 다른 계정으로 들어갔을 때 이전 그룹 상태가 다음 세션에 남는 문제도 따로 살펴봤습니다.

워크스페이스와 그룹·채널을 GoRouter 경로로 표현하고, 현재 사용자와 탐색 상태를 함께 평가하도록 라우팅과 상태를 정리했습니다. 경로, 접근 상태, 마지막 그룹 선택을 한 구조로 다룰 수 있는 대신 초기 인증·권한 조회와 리다이렉트의 순서를 관리해야 했습니다. 읽음 위치에서도 시각 비교를 게시글 ID로 바꾸고 위젯 종료 직후의 콜백 문제를 고쳤지만, 후속 정리에서는 불안정했던 일부 읽음 UI를 걷어내고 기본 게시글 경로를 남겼습니다.

### 4. 캘린더에 보이는 빈칸과 실제 예약 가능한 시간을 구분했습니다

장소 캘린더에서 빈칸으로 보인다고 곧바로 예약할 수 있는 것은 아닙니다. 요일별 운영 시간, 제한 시간, 휴관과 기존 예약이 모두 판단에 들어갑니다. 읽기 화면은 예약 가능 구간을 보여주고, 쓰기 서비스는 저장 직전에 시간과 충돌 조건을 별도로 검사합니다. 화면 쪽 검사는 사용자가 불가능한 시간을 고르지 않도록 돕는 장치이고, 최종 결정은 서버에서 합니다.

반복 그룹 일정은 규칙을 함께 저장하면서 회차를 전개하는 방식으로 설계했습니다. 범위 조회는 단순해지는 대신, 한 회차 수정인지 이후 전체 수정인지 쓰기 경로에서 구분해야 합니다. 개인 일정, 그룹 행사, 장소 예약을 탭으로 나누고 각기 다른 소유자와 수정 규칙을 적용했습니다. 장소 예약은 그룹 일정과 다른 레코드로 저장하고 일정 ID로 연결해 두 화면에서 같은 일정을 따라갈 수 있게 했습니다.

[기술 결정과 코드 근거 더 보기](docs/portfolio-readme/docs/portfolio/engineering-notes.md)

## AI 개발 워크플로

![AI 개발 워크플로](docs/portfolio-readme/docs/portfolio/diagrams/agent-workflow.png)

이 프로젝트에서는 앱뿐 아니라 **개발 도중 에이전트가 어떤 문서를 읽고 언제 멈춰야 하는지**도 설계했습니다. 처음엔 모델마다 대화를 새로 설명하는 일을 줄이려고 작업 목표, 참고 파일, 합성한 맥락을 하나의 작업 폴더에 모았습니다. Bash 스크립트가 Markdown을 수집하고 출처를 남겼지만, 작업 폴더가 쌓일수록 오래된 문서와 현재 규칙을 구분하기 어려워졌습니다.

그 이후에는 자료를 모두 전달하는 대신 프론트엔드, 백엔드, 권한, 테스트 등 작업별로 책임과 먼저 읽을 문서를 가이드에 나눴습니다. 구현 전에는 요구사항과 영향 범위를 확인하고, 명세·계획·작업 목록 사이에 충돌이 있거나 검증이 끝나지 않으면 사람의 결정을 받도록 했습니다. 코드와 함께 다음 작업이 읽을 문서를 갱신하는 절차도 정의했습니다. 여러 모델을 많이 호출하는 것보다, 다음 작업이 **어떤 근거로 무엇을 바꿨는지 다시 따라갈 수 있는 것**이 중요한 선택이었습니다.

[작업 구조의 변천과 커밋 근거](docs/portfolio-readme/docs/portfolio/engineering-notes.md#작업-폴더에서-검증-절차로)

## 로컬 실행

Java 17, Gradle 8.14.x, Flutter 3.35.x, Chrome을 사용합니다. 저장소에 Gradle Wrapper JAR가 포함되지 않은 체크아웃에서는 설치된 Gradle로 백엔드를 실행합니다.

```bash
# 백엔드: 새 터미널에서
cd backend
gradle bootRun
```

```bash
# 웹: 저장소 루트에서
cd frontend
cp .env.example .env
flutter pub get
flutter run -d chrome --web-hostname 127.0.0.1 --web-port 5173
```

일반 로그인에는 Google OAuth 클라이언트 설정이 필요합니다. 화면과 API의 기준 코드는 `frontend/`와 `backend/`에 있습니다. `frontend_new/`는 디자인 토큰과 반응형 컴포넌트, `backend_new/`는 도메인 중심 구조 개편을 별도로 검증한 경로입니다.

## 더 보기

- [기술 결정과 개발 과정](docs/portfolio-readme/docs/portfolio/engineering-notes.md)
- 편집 가능한 draw.io 원본: [시스템](docs/portfolio-readme/docs/portfolio/diagrams/system.drawio) · [실행 환경](docs/portfolio-readme/docs/portfolio/diagrams/runtime.drawio) · [채널 권한](docs/portfolio-readme/docs/portfolio/diagrams/workspace-policy.drawio) · [AI 작업 흐름](docs/portfolio-readme/docs/portfolio/diagrams/agent-workflow.drawio)


<details>
<summary>기존 설치·개발 안내</summary>

# 🏛️ 대학 그룹 관리 플랫폼 (Univ Group Management)

> **"카카오톡, 구글 폼, 엑셀, 노션... 흩어진 대학 생활을 하나의 워크스페이스로."**
> 학과, 동아리, 학회를 위한 통합 커뮤니케이션 및 관리 솔루션입니다.

[![Flutter](https://img.shields.io/badge/Flutter-3.9-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Spring Boot](https://img.shields.io/badge/Spring_Boot-3.5-6DB33F?logo=spring-boot&logoColor=white)](https://spring.io/projects/spring-boot)
[![Kotlin](https://img.shields.io/badge/Kotlin-1.9-7F52FF?logo=kotlin&logoColor=white)](https://kotlinlang.org)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-15-4169E1?logo=postgresql&logoColor=white)](https://www.postgresql.org)
[![JUnit5](https://img.shields.io/badge/Tests-450+-success?logo=junit5&logoColor=white)](#-프로젝트-통계)

---

## 🚀 프로젝트 소개

대학의 실제 조직 구조(대학 → 단과대 → 학과 → 동아리/학회)를 시스템에 그대로 투영했습니다. 그룹마다 독립적인 **워크스페이스**가 생성되며, 강력한 **2계층 권한 시스템**을 통해 안전하고 체계적인 그룹 운영을 지원합니다.

백엔드(Spring) 개발자로서의 역량을 기반으로, 프론트엔드(Flutter)까지 확장하여 설계부터 배포까지 전 과정을 경험한 **풀스택 프로젝트**입니다.

---

## 🛠 Tech Stack

### Frontend
- **Framework**: ![Flutter](https://img.shields.io/badge/Flutter-02569B?style=flat-square&logo=Flutter&logoColor=white) (Web)
- **State Management**: ![Riverpod](https://img.shields.io/badge/Riverpod-02569B?style=flat-square)
- **Navigation**: ![Navigator 2.0](https://img.shields.io/badge/Navigator_2.0-02569B?style=flat-square) / ![Go Router](https://img.shields.io/badge/Go_Router-02569B?style=flat-square)

### Backend
- **Language**: ![Kotlin](https://img.shields.io/badge/Kotlin-7F52FF?style=flat-square&logo=Kotlin&logoColor=white)
- **Framework**: ![Spring Boot](https://img.shields.io/badge/Spring_Boot-6DB33F?style=flat-square&logo=Spring-Boot&logoColor=white) 3.5
- **ORM**: ![JPA/Hibernate](https://img.shields.io/badge/JPA/Hibernate-59666C?style=flat-square&logo=Hibernate&logoColor=white)
- **Cache**: ![Caffeine](https://img.shields.io/badge/Caffeine_Cache-orange?style=flat-square)

### Infrastructure & Tools
- **Database**: ![PostgreSQL](https://img.shields.io/badge/PostgreSQL-4169E1?style=flat-square&logo=PostgreSQL&logoColor=white) / ![H2](https://img.shields.io/badge/H2-blue?style=flat-square)
- **Auth**: ![Google OAuth 2.0](https://img.shields.io/badge/Google_OAuth_2.0-4285F4?style=flat-square&logo=Google&logoColor=white) / ![JWT](https://img.shields.io/badge/JWT-black?style=flat-square&logo=JSON-Web-Tokens&logoColor=white)

---

## ✨ 핵심 기능

### 1️⃣ 대학 조직 구조 기반 그룹 계층
- 대학 실정에 맞는 6가지 그룹 유형 제공 (대학, 단과대, 학과, 연구실, 공식, 자율)
- **그룹 독립성 원칙**: 상위 그룹의 간섭 없는 독립적 운영 보장

🔗 [상세 설계 보기: 1. 그룹 계층 구조](docs/portfolio/features.md)

<img width="1014" height="1206" alt="Image" src="https://github.com/user-attachments/assets/1cb585d0-4148-47f9-ba6e-a70fd41d6fdf" />
<img width="1010" height="1078" alt="Image" src="https://github.com/user-attachments/assets/237bd5cd-9220-403e-b2f5-07329dfae5cf" />
### 2️⃣ 워크스페이스 & 채널 시스템
- 그룹 생성 시 자동 워크스페이스 할당
- **Secure by Default**: 권한 기반의 폐쇄형/공개형 채널 관리

🔗 [상세 설계 보기: 2. 워크스페이스 및 채널](docs/portfolio/features.md)

<img width="1275" height="1299" alt="Image" src="https://github.com/user-attachments/assets/212ac18a-f3f8-4e7b-8f8c-f16713a4280d" />
<img width="1150" height="1230" alt="Image" src="https://github.com/user-attachments/assets/146fea38-5c2c-433f-a1ee-11c78b0e6da2" />
### 3️⃣ 2-Layer 권한 시스템 (RBAC+)
- **1계층**: 시스템 역할 (그룹장, 교수, 멤버)
- **2계층**: 채널별 오버라이드 권한 (조회/읽기/쓰기/파일 등 세분화)
- **최적화**: Caffeine Cache를 통한 권한 체크 성능 극대화

🔗 [상세 설계 보기: 3. 2-Layer 권한 시스템](docs/portfolio/features.md)

<img width="1100" height="645" alt="Image" src="https://github.com/user-attachments/assets/7e2c9c77-ec85-4e71-bb7c-0301de5952aa" />
<img width="1271" height="1321" alt="Image" src="https://github.com/user-attachments/assets/bf691844-926b-4f94-bf98-87a5fce1911a" />
<img width="1224" height="899" alt="Image" src="https://github.com/user-attachments/assets/9d4a9717-69db-431d-a88c-088e7259fc15" />
### 4️⃣ 스마트 캘린더 & 예약 시스템
- 개인/그룹/장소예약 캘린더의 3중 레이어 구조
- 실제 대학 환경을 고려한 강의실/동아리방 예약 충돌 방지 로직

🔗 [상세 설계 보기: 4. 게시글 및 댓글](docs/portfolio/features.md)

<img width="1246" height="1000" alt="Image" src="https://github.com/user-attachments/assets/4a177ba2-f749-488d-ba09-ec2bb17917a1" />
<img width="948" height="1083" alt="Image" src="https://github.com/user-attachments/assets/66dec35b-9b83-4527-a430-134278177f15" />
---

## 🏗 아키텍처 & 기술적 도전

### 💎 Clean Architecture 도입
기존 모놀리식 구조의 한계를 극복하기 위해 `backend_new`에서 도메인 기반 Clean Architecture를 설계했습니다.
- **관심사 분리**: Domain -> Data -> Presentation 레이어의 엄격한 분리
- **테스트 용이성**: 비즈니스 로직에 대한 독립적인 단위 테스트 확보

### 🛣 Navigator 2.0 마이그레이션
Flutter의 선언형 네비게이션을 도입하여 복잡한 웹 라우팅과 상태 관리를 정교화했습니다.
- 브라우저 뒤로가기/앞으로가기 완벽 지원
- 권한에 따른 동적 페이지 가드 구현

---

## 🚦 시작 가이드

### 사전 요구사항
- Flutter SDK 3.9+ / Java 17+ / Google OAuth ID

### 실행 방법
```bash
# Backend
cd backend && ./gradlew bootRun

# Frontend
cd frontend
# OAuth Client ID 설정에 필요한 환경 변수는 frontend 설정 문서를 참고
flutter run -d chrome
```

---

## 📊 프로젝트 통계
- **개발 기간**: 2025.09 ~ 2025.12 (4개월)
- **개발 인원**: 1인 (기획, 설계, 프론트엔드, 백엔드)
- **테스트**: 백엔드 155개, 프론트엔드 300+개 (총 455+개)

---

[상세 설계](docs/portfolio/features.md) · [아키텍처](docs/portfolio/architecture.md) · [기술적 도전](docs/portfolio/technical-challenges.md) · [기술 회고](docs/portfolio/decisions.md)

</details>
