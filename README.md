# 🏛️ 대학 그룹 관리 플랫폼 (Univ Group Management)

> **"카카오톡, 구글 폼, 엑셀, 노션... 흩어진 대학 생활을 하나의 워크스페이스로."**  
> 학과, 동아리, 학회를 위한 통합 커뮤니케이션 및 관리 솔루션입니다.

[![Flutter](https://img.shields.io/badge/Flutter-3.9-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Spring Boot](https://img.shields.io/badge/Spring_Boot-3.5-6DB33F?logo=spring-boot&logoColor=white)](https://spring.io/projects/spring-boot)
[![Kotlin](https://img.shields.io/badge/Kotlin-1.9-7F52FF?logo=kotlin&logoColor=white)](https://kotlinlang.org)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-15-4169E1?logo=postgresql&logoColor=white)](https://www.postgresql.org)
[![JUnit5](https://img.shields.io/badge/Tests-450+-success?logo=junit5&logoColor=white)](#-테스트--품질)

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
- [상세 설계 보기](docs/portfolio/features.md#1-그룹-계층-구조)

### 2️⃣ 워크스페이스 & 채널 시스템
- 그룹 생성 시 자동 워크스페이스 할당
- **Secure by Default**: 권한 기반의 폐쇄형/공개형 채널 관리
- [상세 설계 보기](docs/portfolio/features.md#2-워크스페이스--채널)

### 3️⃣ 2-Layer 권한 시스템 (RBAC+)
- **1계층**: 시스템 역할 (그룹장, 교수, 멤버)
- **2계층**: 채널별 오버라이드 권한 (조회/읽기/쓰기/파일 등 세분화)
- **최적화**: Caffeine Cache를 통한 권한 체크 성능 극대화
- [상세 설계 보기](docs/portfolio/features.md#3-2-layer-권한-시스템)

### 4️⃣ 스마트 캘린더 & 예약 시스템
- 개인/그룹/장소예약 캘린더의 3중 레이어 구조
- 실제 대학 환경을 고려한 강의실/동아리방 예약 충돌 방지 로직
- [상세 설계 보기](docs/portfolio/features.md#5-캘린더-3종-개인--그룹--장소예약)

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
cp .env.example .env  # OAuth Client ID 설정
flutter run -d chrome
```

---

## 📊 프로젝트 통계
- **개발 기간**: 2025.09 ~ 2025.12 (4개월)
- **개발 인원**: 1인 (기획, 설계, 프론트엔드, 백엔드)
- **테스트**: 백엔드 155개, 프론트엔드 300+개 (총 455+개)

---

[상세 설계](docs/portfolio/features.md) · [아키텍처](docs/portfolio/architecture.md) · [기술적 도전](docs/portfolio/technical-challenges.md) · [기술 회고](docs/portfolio/decisions.md)
