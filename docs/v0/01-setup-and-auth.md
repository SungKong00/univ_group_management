# React V0 개발 프롬프트: 1단계 - 프로젝트 기반 설정 및 인증

## 1. 목표
React와 TypeScript를 사용하여 새로운 프론트엔드 애플리케이션의 기본 구조를 설정하고, 사용자가 회원가입하고 로그인할 수 있는 인증 기능을 구현합니다.

## 2. 기술 스택
-   **프레임워크:** React
-   **언어:** TypeScript
-   **빌드 도구:** Vite
-   **UI 라이브러리:** Material-UI (MUI)
-   **라우팅:** React Router
-   **상태 관리:** Zustand
-   **HTTP 클라이언트:** Axios

## 3. 상세 구현 단계

### 3.1. 프로젝트 생성 및 초기 설정
1.  다음 명령어를 사용하여 `frontend-react`라는 이름의 React + TypeScript 프로젝트를 생성합니다.
    ```bash
    npm create vite@latest frontend-react -- --template react-ts
    ```
2.  생성된 프로젝트 디렉토리로 이동합니다.
    ```bash
    cd frontend-react
    ```

### 3.2. 필수 라이브러리 설치
다음 명령어를 실행하여 프로젝트에 필요한 주요 라이브러리를 설치합니다.
```bash
npm install @mui/material @emotion/react @emotion/styled @mui/icons-material react-router-dom zustand axios
```

### 3.3. 폴더 구조 생성
`src` 디렉토리 내에 다음과 같은 폴더 구조를 생성하여 코드를 체계적으로 관리합니다.

```
src/
├── api/         # Axios 인스턴스 및 API 호출 함수
├── assets/      # 이미지, 폰트 등 정적 에셋
├── components/  # 재사용 가능한 공통 컴포넌트 (Button, Input 등)
├── hooks/       # 커스텀 훅
├── layouts/     # 페이지 레이아웃 컴포넌트 (e.g., MainLayout, AuthLayout)
├── pages/       # 라우팅될 페이지 컴포넌트 (Login, Signup 등)
├── routes/      # 라우팅 설정
├── store/       # Zustand 상태 저장소
├── styles/      # 전역 스타일 및 MUI 테마 설정
└── utils/       # 유틸리티 함수
```

### 3.4. 라우팅 및 레이아웃 설정
1.  `src/layouts/`에 인증 페이지용 `AuthLayout.tsx`와 메인 페이지용 `MainLayout.tsx`를 생성합니다.
2.  `src/routes/AppRouter.tsx` 파일을 생성하고, `react-router-dom`을 사용하여 다음과 같이 라우트를 설정합니다.
    -   `/login` -> `LoginPage` (AuthLayout 사용)
    -   `/signup` -> `SignupPage` (AuthLayout 사용)
    -   `/` -> `HomePage` (MainLayout 사용, 인증된 사용자만 접근 가능)

### 3.5. 인증 페이지 UI 및 로직 구현
**참고 명세:** `기능명세서/1 회원가입 로그인.md`, `UI:UX 명세서/1. 온보딩_가입_ui_ux_명세서v_0`

1.  **로그인 페이지 (`src/pages/auth/LoginPage.tsx`)**
    -   MUI 컴포넌트를 사용하여 이메일, 비밀번호 입력 필드와 로그인 버튼을 구현합니다.
    -   '회원가입', '비밀번호 찾기' 링크를 추가합니다.
    -   로그인 버튼 클릭 시 `axios`를 사용해 백엔드 로그인 API를 호출합니다.
    -   성공 시, 서버로부터 받은 JWT를 `Zustand` 스토어와 `localStorage`에 저장하고, 홈페이지(`/`)로 리디렉션합니다.
    -   실패 시, 사용자에게 에러 메시지를 표시합니다.

2.  **회원가입 페이지 (`src/pages/auth/SignupPage.tsx`)**
    -   MUI를 사용하여 이메일, 비밀번호, 비밀번호 확인, 닉네임 입력 필드와 회원가입 버튼을 구현합니다.
    -   회원가입 버튼 클릭 시 백엔드 API를 호출합니다.
    -   성공 시, 로그인 페이지로 리디렉션하며 "회원가입이 완료되었습니다"와 같은 메시지를 표시합니다.

### 3.6. API 클라이언트 및 상태 관리 설정
1.  **API 클라이언트 (`src/api/axiosInstance.ts`)**
    -   `axios.create`를 사용하여 기본 `baseURL`을 설정한 인스턴스를 생성합니다.
    -   Request Interceptor를 추가하여, `localStorage`에 JWT가 존재할 경우 모든 요청의 `Authorization` 헤더에 `Bearer <token>`을 자동으로 추가합니다.

2.  **인증 스토어 (`src/store/authStore.ts`)**
    -   `Zustand`를 사용하여 사용자 정보(user)와 토큰(token)을 저장하는 스토어를 생성합니다.
    -   `login`, `logout` 액션을 정의하여 인증 상태를 관리합니다.

## 4. 완료 조건
-   `http://localhost:5173/login` 접속 시 로그인 페이지가 렌더링된다.
-   `http://localhost:5173/signup` 접속 시 회원가입 페이지가 렌더링된다.
-   회원가입 및 로그인이 API와 연동하여 정상적으로 동작하고, 토큰이 저장된다.
-   로그인하지 않은 상태에서 메인 페이지(`/`) 접근 시 로그인 페이지로 리디렉션된다.
