# Input Context

\n---\n## File: context/feature-specifications.md\n
# Application Feature Specifications

This document is a comprehensive summary of all feature specifications for the project, synthesized from the 8 documents in `docs/설계 문서/기능명세서/`.

---

## 1. Sign-up / Login

- **1.1. Feature Definition:** Users select their role (student or professor) upon signing up, authenticate easily via Google social login, and complete registration by providing additional information and verifying their school email. A manual approval process by an admin is required for professor roles.
- **1.2. Goal:** To allow users to sign up safely and conveniently within 2 minutes, following a clear process tailored to their role.
- **1.3. Scope:** Google social login, role selection, additional info input (name, nickname), school email verification, and admin approval for professors.
- **1.4. User Stories:**
    - (Student) "I want to sign up easily with my Google account and quickly verify my school email."
    - (Professor) "I want a simple sign-up process but need my role to be securely verified. I understand if some features are limited pending approval."
- **1.5. Requirements:**
    - Must use Google OAuth2.
    - Role selection (student/professor) is mandatory.
    - Name, nickname, department, student ID are mandatory.
    - Nicknames must be unique.
    - A 6-digit verification code (valid for 5 minutes) will be sent to the school email.
    - Professor role applications are granted a 'Pending Approval' status, and an alert is sent to the admin.
- **1.6. UX/UI Flow (Toss UI/UX Philosophy):**
    - **One Screen, One Goal:** Each step is a full-page view to maintain focus.
    - **Flow:**
        1.  **Screen 1: Role Selection:** User chooses between [Start as Student] or [Start as Professor].
        2.  **Authentication:** Proceed with Google Account authentication.
        3.  **Screen 2: Profile & School Verification:** A single, scrollable screen for entering name, nickname, department, student ID, and school email. The verification code input field appears on the same screen after requesting the code.
        4.  **Authorization:** Appropriate permissions are granted. For professors, a "Pending Approval" banner is shown throughout the app.
- **1.7. Edge Cases:**
    - **Interruption:** Progress is not saved if the user leaves the sign-up process.
    - **Duplicate Nickname:** An immediate error message "Nickname is already in use" is displayed.
    - **Verification Code Error:** Appropriate error messages for incorrect code or expiration.
    - **Professor Rejection:** The user is notified, and their role is automatically changed to 'Student'.

---

## 2. Group / Workspace Management

- **2.1. Overview:** Allows users to form communities (groups) and operate dedicated collaboration spaces (workspaces).
- **2.2. Roles & Permissions:**
    - **System Admin:** Can create top-level groups and intervene if a group leader is absent.
    - **Group Leader (Student Rep):** Approves/rejects subgroup creations and member joins, **appoints/removes supervising professors**, delegates leadership, and deletes the group.
    - **Supervising Professor (Faculty):** Appointed by the Group Leader, shares all permissions with the Group Leader but cannot manage other leaders/professors.
    - **Group Member:** Standard user within a group.
    - **General User:** Can search for groups and apply to join.
- **2.3. Key Features:**
    - **Group Creation:** Admins create top-level groups; users can apply to create subgroups.
    - **Group Leader Functions:**
        - **Appoint/Remove Professor:** Can designate a 'Professor' role member as a 'Supervising Professor'.
        - **Delegate Leadership:** Must delegate leadership to another member before leaving.
        - **Force Removal:** Can remove members from the group.
        - **Delete Group (UX Change):** Deletion is confirmed via a **Bottom Sheet** that summarizes the data to be deleted (e.g., N members, N posts). The final action requires clicking a red [Delete] button, removing the need to type a confirmation phrase.
- **2.4. Policies:**
    - **Absent Group Leader (Simplified MVP Policy):** If a leader is inactive, the system automatically assigns leadership to the member who joined earliest among the highest-grade students.
    - **Data Deletion:**
        - Deleting a group **permanently and immediately deletes all associated data**.
        - When a user leaves the service, their posts/comments are **anonymized to '(Deleted User)'** but not deleted.
        - In MVP, deleting a parent group **cascades and deletes all its subgroups**.

---

## 3. Permissions / Member Management

- **3.1. System Structure:** Permissions are managed via 'Roles'. A Group Leader creates custom roles, assigns permissions to them, and then assigns roles to members.
- **3.2. Fixed Roles:**
    - **'Group Leader' (Student) & 'Supervising Professor' (Faculty):** Top-level roles with all permissions. They are immutable and cannot remove each other.
    - **'General Member':** The default role for all new members.
- **3.3. MVP Custom Permissions:** Integrated permissions like [Recruitment Management], [Member Management], [Channel Management] can be combined freely into custom roles.
- **3.4. Member Management Screen:**
    - Displays profile info, role, join date.
    - **'Group Leader' (👑) and 'Supervising Professor' (🎖️) are visually distinguished with icons.**
    - Roles can be changed instantly via a dropdown menu.

---

## 4. Promotion / Recruitment

- **4.1. Structure:** A dedicated **'Recruitment' board** lists all active recruitment posts.
- **4.2. Required Post Information:** Title, body, recruitment period (start/end dates via a date picker), number of people (free text like "5", "00", "Always recruiting"), and tags (#dev, #design).
- **4.3. Features by Role:**
    - **Group Leader (Poster):** Can create, edit, delete, and manually close their own recruitment posts.
    - **General User (Applicant):** Can view all active posts (sorted by newest first), search by title or tag, and apply by navigating to the group's page and using the standard 'Join Group' function.
- **4.4. Policies:**
    - A group can only have **one active recruitment post at a time**.
    - An attempt to create a new post while one is active will be blocked with an explanatory message.
    - Posts are automatically set to 'Closed' and hidden from the list when their end date passes.

---

## 5. Posts / Comments

- **5.1. Basic Structure:** A real-time chat format (like Slack) where the newest messages appear at the bottom. The message composer is fixed at the bottom of the screen.
- **5.2. Post (Message) Details:** Consists of author info, timestamp, content, and comment count. CRUD is standard, with the 'Channel Management' role having permission to delete others' messages.
- **5.3. Comment Details & Policy:**
    - Comments are managed as **Threads** attached to a message.
    - **MVP Architecture:** Only **single-level comments (no replies-to-replies)** will be implemented.
    - **DB Design:** The `Comment` table will include a `parent_comment_id` field for future expansion, but it will be `null` in the MVP.
    - **Deletion Policy:** If a parent comment is deleted, **all its child comments (replies) are also permanently deleted.**

---

## 6. Notification System

- **6.1. Architecture:** Notification data is stored in a **structured format** (including source, target, type) to support future features like a personalized home feed.
- **6.2. Data Retention Policy:** Notifications are **automatically deleted after 90 days**.
- **6.3. UX/UI:**
    - A bell (🔔) icon in the header displays a **red badge** for unread notifications.
    - Clicking the icon opens a **dropdown list** of recent notifications.
    - Opening the dropdown automatically marks all visible notifications as **'read'**, and the badge disappears.
    - Clicking a notification navigates the user to the relevant page (e.g., the post where a comment was made).
- **6.4. MVP Notification Triggers:**
    - When my group join request is **approved or rejected**.
    - When a **new join request** is submitted to a group I lead.
    - When my **role is changed**.

---

## 7. Admin Page

- **7.1. Access & UI Concept:** A 'Management' button is visible only to users with at least one admin permission. The admin home uses **icon-based cards/lists** instead of plain text, providing context like a `Pending N` badge next to the `Member Management` menu. Only menus for which the user has permission are shown.
- **7.2. MVP Feature List:** Member Management, Role Management, Channel Management, Supervising Professor Management, Edit Group Info, Delete Group.
- **7.3. Key Flows (Toss UI/UX Philosophy):**
    - **Role & Channel Management:** Uses a **'single-screen settings'** approach. For example, creating a role shows the name input and all permission toggles on one page for immediate configuration and saving.
    - **Group Deletion:** Uses a **Bottom Sheet** to clearly display what will be deleted and requires a final click on a red [Delete] button for confirmation.

---

## 8. User Profile & Account Management

- **8.1. 'My Info' Screen:** Accessed via the 'My Page' icon. Contains menus for My Groups, Application Status, Login Info, Logout, and Leave Service.
- **8.2. Key Flows:**
    - **Profile Editing:** Modify profile picture, nickname, and bio.
    - **Leave Service (UX Change):**
        - Clicking 'Leave Service' brings up a **Bottom Sheet**.
        - The sheet explains the consequences (e.g., "Your posts will be anonymized").
        - Final confirmation requires clicking a red [Leave] button at the bottom. The "type to confirm" step is removed.
- **8.3. Policies:**
    - **Nickname:** Must be unique.
    - **Profile Visibility:** Public to everyone in the MVP.
    - **Account Deletion:** User-generated content (posts, comments) is **anonymized to '(Unknown)' or '(Deleted User)'** but not deleted.

\n---\n## File: context/CHANGELOG.md\n
# Context Changelog

## 2025-09-11
### Refactor
- **CONTEXT**: Performed a major refactoring of the knowledge base. Consolidated scattered design documents from `docs/` into five comprehensive, agent-optimized files within the `context/` directory:
  - `architecture-overview.md`
  - `database-design.md`
  - `feature-specifications.md`
  - `process-conventions.md`
  - `project-plan.md`
- This change streamlines context synthesis for the AI workflow and improves the maintainability of the project's core knowledge.

---

- 초기화: 컨텍스트 디렉토리 생성 및 워크플로우 도입
- 2025-09-10T11:18:48Z archived task: tasks/archive/2025-09-10-api
- 2025-09-10T11:32:59Z archived task: tasks/archive/2025-09-10-api-2
- 2025-09-10T19:10:29Z archived task: tasks/archive/2025-09-11-flutter-api
\n---\n## File: context/project-plan.md\n
# Project Plan: MVP and Post-MVP Roadmap

This document outlines the project's scope, starting with the Minimum Viable Product (MVP) and followed by the development roadmap. It is synthesized from `MVP.md` and `MVP 이후 개발 로드맵.md`.

---

## 1. MVP (Minimum Viable Product) Scope

**Core Goal:** To enable new users to discover attractive groups through the **[Explore]** and **[Recruitment]** tabs, join them, and experience systematic announcements and detailed permission management within their groups.

### MVP Feature List:

1.  **Group Discovery & Recruitment:**
    - **[Explore] Tab:** A space for users to browse all groups. Each group has a profile page showcasing its identity and activity archive. Searchable by tags.
    - **[Recruitment] Tab:** A feed showing only groups that are actively recruiting. Posts contain key information like recruitment period, qualifications, etc.

2.  **Group Navigation:**
    - A hierarchical navigator (University -> College -> Department) to understand the overall group structure.

3.  **Announcements & Communication:**
    - Ability to create and view text-based announcements within a group.
    - **Threaded comments** are supported for organized discussions on announcements.

4.  **Permission Management:**
    - A detailed permission system from the start.
    - Group leaders can create custom roles (e.g., 'Accounting Team') and assign specific permissions (e.g., create announcements, invite members) to each role.
    - Group leaders can appoint a **'Supervising Professor'** who shares the same authority.

5.  **Notifications:**
    - Minimal, interaction-based notifications are sent only when:
        - A user's join request is **approved or rejected**.
        - A **new join request** is submitted to a group led by the user.
        - A user's **role is changed**.

6.  **Admin Page:**
    - A minimal set of tools for group management:
        - Member management (approve/reject, kick).
        - Role management (create/edit/delete).
        - Edit group information.

7.  **User Profile:**
    - Basic functionality for users to manage their own profile:
        - Edit profile picture, nickname, bio.
        - View a list of their groups.
        - Logout and leave the service.

---

## 2. Post-MVP Roadmap

**Development Goal:** To sequentially expand features so that users acquired through the MVP can settle in successfully and handle all core group activities within the app.

### 2.1. Major Feature Roadmap (In Order of Priority)

1.  **🙋‍♂️ Personalized Home (My Activities):** A personalized To-Do list to reduce information fatigue and encourage daily visits by showing tasks needing attention (e.g., new announcements, RSVPs).
2.  **📅 Calendar:** A central hub to view all group schedules in a monthly/weekly format.
3.  **⏰ Schedule Coordination (Admin-led):** A 'Smart Scheduling Board' for admins to view participants' availability and set optimal event times.
4.  **🧑‍🏫 Professor/Operator Dashboard:** Anonymized statistical data (attendance rates, activity frequency) to support administrative tasks and enhance the app's official credibility.
5.  **✨ Functional Posts (Super Posts):** Ability to create posts with embedded functions like polls and RSVPs.
6.  **✅ QR Code Attendance:** A system to manage attendance for offline events registered in the calendar.
7.  **💬 Real-time Chat Channels:** Separate channels for casual, real-time conversations to prevent users from leaving for external messengers like KakaoTalk.
8.  **Later Stages:** Kanban boards, accounting, gamification (badges), file management, dark mode, etc.

### 2.2. Detailed Feature Enhancements

- **Group & Permissions:**
    - Change group deletion from immediate to a **30-day retention period**.
    - Change subgroup deletion policy to **re-parenting** instead of cascading deletion.
    - Add **private/public** settings for groups.
    - Allow **individual permission adjustments** for specific members, overriding their role.

- **Member Management:**
    - **Bulk Actions** (e.g., change roles for multiple members at once).
    - Display additional info like **'Last Seen'** in the member list.

- **Recruitment & Promotion:**
    - Feature recruitment posts on the **main home screen**.
    - Allow **image attachments** in posts.
    - Add **sorting and filtering** (by deadline, popularity) to the recruitment board.
    - Add a **Q&A (comment) section** to recruitment posts.

\n---\n## File: context/architecture-overview.md\n
# System Architecture Overview

This document provides a comprehensive overview of the project's architecture, synthesized from the 9 documents in `docs/설계 문서/아키텍처 설계 /`. It covers general deployment, backend (Spring Boot), frontend (Flutter), and detailed API specifications.

---

## 1. General Architecture & Deployment

- **Tech Stack**:
    - **Frontend**: Flutter (targeting Web as the primary platform).
    - **Backend**: Spring Boot with Kotlin.
    - **Database**: RDBMS (planned for AWS RDS).

- **Deployment Architecture (AWS)**:
    - A minimal setup using **EC2 (Server) + RDS (DB) + S3 (Build Storage)**.
    - **Unified Deployment**: The Flutter web build output (HTML, JS) is included in the Spring Boot project's `src/main/resources/static` directory. The entire application is deployed as a single JAR file, with Spring Boot handling both API serving and web hosting.

- **CI/CD (GitHub Actions)**:
    - **Trigger**: Merging code from the `develop` branch into the `main` branch triggers an automatic deployment to production.
    - **Pipeline**: 
        1. Build and test the project.
        2. Upload the executable JAR to AWS S3.
        3. Connect to AWS EC2, pull the new JAR from S3, and run the server.
    - **Secrets Management**: All sensitive information (DB passwords, JWT keys) is stored in GitHub Actions Secrets and used to dynamically generate `application-prod.yml` during the CI/CD process.

---

## 2. Backend Architecture (Spring Boot)

### 2.1. Code-Level 3-Layer Architecture

The backend follows a strict, single-direction data flow (`Controller` → `Service` → `Repository`).

- **`Controller`**: Handles HTTP requests/responses and performs first-pass syntactic validation on DTOs (`@Valid`). It knows nothing about Entities.
- **`Service`**: Contains all business logic, manages transactions (`@Transactional`), and is solely responsible for converting between DTOs and Entities. It performs second-pass semantic validation (business rules).
- **`Repository`**: Manages data persistence (CRUD) by communicating directly with the database. It knows nothing about DTOs.

### 2.2. API Design Principles

- **Standard Response Format**: All API responses are wrapped in a standard JSON envelope:
  ```json
  {
      "success": boolean,
      "data": { ... } | [ ... ] | null,
      "error": { "code": "...", "message": "..." } | null
  }
  ```
- **HTTP Status Codes**: Standard codes are used (`200 OK`, `201 Created`, `204 No Content`, `400 Bad Request`, `401 Unauthorized`, `403 Forbidden`, `404 Not Found`, `500 Internal Server Error`).

### 2.3. Authentication & Authorization

- **Authentication Flow**: 
    1. Frontend gets a **Google Auth Token** via Google Sign-In.
    2. This token is sent to the backend (`POST /api/auth/google`).
    3. Backend validates the token with Google, finds or creates a user in the DB.
    4. Backend generates and returns a service-specific **JWT Access Token**.
    5. Frontend sends this JWT in the `Authorization: Bearer <JWT>` header for all subsequent requests.
- **Authorization Strategy**: 
    - **Method Security**: Authorization is handled declaratively at the method level using Spring Security's `@PreAuthorize` annotation.
    - **Custom Evaluator**: A custom permission evaluator (e.g., `@groupPermissionEvaluator`) is used within `@PreAuthorize` to check complex, domain-specific permissions (e.g., `hasPermission(#groupId, 'MEMBER_KICK')`).

### 2.4. Exception Handling & Logging

- **Global Exception Handling**: A central `@RestControllerAdvice` class catches all exceptions. Custom `BusinessException` (containing an `ErrorCode` enum) is used for predictable errors, which are translated into the standard error JSON format.
- **Logging Strategy (SLF4J + Logback)**:
    - **Levels**: `DEBUG` for local/dev, `INFO` for production.
    - **Content**: `INFO` for key events (server start), `WARN` for potential issues, `ERROR` for all exceptions (with stack trace for 500 errors).
    - **Rotation**: Logs are rotated daily and kept for a maximum of 30 days.

### 2.5. Testing Strategy

- **Pyramid Focus**: The strategy prioritizes **Integration Tests** over Unit Tests. E2E tests are out of scope for MVP.
- **Environment**: Tests run against an **H2 in-memory database** for speed and isolation.
- **Structure**: 
    - An `IntegrationTest` base class provides common setup (`@SpringBootTest`).
    - A `DatabaseCleanup` component ensures each test runs on a clean DB (`@AfterEach`).
    - An `AcceptanceTest` helper class abstracts away `MockMvc` complexity, allowing tests to be written in a business-readable format (e.g., `acceptanceTest.createGroup(...)`).

---

## 3. Frontend Architecture (Flutter)

- **State Management**: **Riverpod** is used for its compile-time safety, flexibility, and scalability.
- **Project Structure**: A **Layered Architecture** is used to separate concerns:
    - `lib/data/`: Models and Repositories (server communication).
    - `lib/providers/`: State management logic (Riverpod providers).
    - `lib/presentation/`: UI (Screens and Widgets).
    - `lib/core/`: Shared utilities (routing, constants).
- **API Client**: **dio** is used, primarily for its **Interceptor** feature, which allows for the automatic injection of the JWT `Authorization` header into all API requests.
- **Routing**: **go_router** is used for its URL-based routing, which is ideal for the web target and supports deep linking.
- **UI Design System**: A centralized `ThemeData` object in `MaterialApp` defines all colors, fonts, and styles. Reusable widgets (e.g., `PrimaryButton`) are created to ensure UI consistency.

---

## 4. API Endpoint Specifications

### 4.1. Auth API
| Feature | Endpoint | Auth | Request Body | Success Response (data) |
| --- | --- | --- | --- | --- |
| **Sign-up** | `POST /auth/signup` | None | `{ "email", "name", "nickname", ... }` | `{ "userId", "nickname" }` |
| **Google Login/Sign-up** | `POST /auth/google` | None | `{ "googleAuthToken": "..." }` | `{ "accessToken": "..." }` |
| **Get My Info** | `GET /users/me` | **Required** | (None) | `{ "userId", "email", ... }` |

### 4.2. Group API
| Feature | Endpoint | Auth | Request Body | Success Response (data) | Permission |
| --- | --- | --- | --- | --- | --- |
| **Create Group** | `POST /groups` | **Required** | `{ "parentId", "name", "description" }` | `{ "groupId", "name", ... }` | Logged-in User |
| **List All Groups** | `GET /groups` | None | (None) | `[ { "groupId", "name", ... } ]` | Anyone |
| **Get Group Details** | `GET /groups/{groupId}` | None | (None) | `{ "groupId", "name", ... }` | Anyone |
| **Update Group** | `PUT /groups/{groupId}` | **Required** | `{ "name", "description" }` | `{ "groupId", "name", ... }` | Leader/Professor |
| **Delete Group** | `DELETE /groups/{groupId}` | **Required** | (None) | `null` | Leader/Professor |

### 4.3. Member & Join API
| Feature | Endpoint | Auth | Request Body | Success Response (data) | Permission |
| --- | --- | --- | --- | --- | --- |
| **Apply to Join** | `POST /groups/{groupId}/join` | **Required** | (None) | `{ "joinRequestId", "status" }` | Logged-in User |
| **List Join Requests** | `GET /groups/{groupId}/join-requests` | **Required** | (None) | `[ { "requestId", "user": { ... } } ]` | Leader/Professor |
| **Process Join Request** | `PATCH /groups/{groupId}/join-requests/{requestId}` | **Required** | `{ "status": "APPROVED" | "REJECTED" }` | `null` | Leader/Professor |
| **List Group Members** | `GET /groups/{groupId}/members` | **Required** | (None) | `[ { "userId", "nickname", ... } ]` | Group Member |
| **Kick Member** | `DELETE /groups/{groupId}/members/{userId}` | **Required** | (None) | `null` | Leader/Professor |

### 4.4. Role API
| Feature | Endpoint | Auth | Request Body | Success Response (data) | Permission |
| --- | --- | --- | --- | --- | --- |
| **Create Custom Role** | `POST /groups/{groupId}/roles` | **Required** | `{ "name", "permissions": [...] }` | `{ "roleId", "name", ... }` | Leader/Professor |
| **List Group Roles** | `GET /groups/{groupId}/roles` | **Required** | (None) | `[ { "roleId", "name" } ]` | Group Member |
| **Change Member Role** | `PUT /groups/{groupId}/members/{userId}/role` | **Required** | `{ "roleId": ... }` | `null` | Leader/Professor |

### 4.5. Recruitment API
| Feature | Endpoint | Auth | Request Body | Success Response (data) | Permission |
| --- | --- | --- | --- | --- | --- |
| **Create Post** | `POST /recruitments` | **Required** | `{ "groupId", "title", ... }` | `{ "postId", "title", ... }` | Group Leader |
| **List Posts** | `GET /recruitments` | None | `?tag=...` | `[ { "postId", "title", ... } ]` | Anyone |
| **Get Post Details** | `GET /recruitments/{postId}` | None | (None) | `{ "postId", "title", ... }` | Anyone |
| **Update Post** | `PUT /recruitments/{postId}` | **Required** | `{ "title", "content", ... }` | `{ "postId", "title", ... }` | Group Leader |
| **Delete Post** | `DELETE /recruitments/{postId}` | **Required** | (None) | `null` | Group Leader |

### 4.6. Post & Comment API
| Feature | Endpoint | Auth | Request Body | Success Response (data) | Permission |
| --- | --- | --- | --- | --- | --- |
| **Create Post** | `POST /channels/{channelId}/posts` | **Required** | `{ "title", "content" }` | `{ "postId", "title", ... }` | Channel Write Perms |
| **List Channel Posts** | `GET /channels/{channelId}/posts` | **Required** | (None) | `[ { "postId", "title", ... } ]` | Channel Read Perms |
| **Create Comment** | `POST /posts/{postId}/comments` | **Required** | `{ "content", "parentCommentId"? }` | `{ "commentId", "content", ... }` | Post Read Perms |
| **List Post Comments** | `GET /posts/{postId}/comments` | **Required** | (None) | `[ { "commentId", "content", ... } ]` | Post Read Perms |
| **Delete Comment** | `DELETE /comments/{commentId}` | **Required** | (None) | `null` | Author or Admin |

\n---\n## File: context/process-conventions.md\n
# Development Process and Conventions

This document summarizes the AI agent-based development workflow, roles, and conventions for this project. It is synthesized from `ai-agent-workflow.md`, `gemini-integration.md`, and `tasks-conventions.md`.

## 1. Core Principles

- **Task-Centric**: All development work is managed within isolated task packages located at `tasks/<date>-<slug>/`.
- **Single Source of Truth**: `TASK.MD` within each package is the central hub for all instructions, logs, and decisions related to a task.
- **Knowledge Separation**:
    - **Static Knowledge**: Long-term knowledge like architecture, standards, and conventions are stored in the `context/` directory.
    - **Dynamic Context**: Task-specific, synthesized context is generated into `SYNTHESIZED_CONTEXT.MD` for one-time use.
- **AI Agent Collaboration**: The workflow relies on a team of specialized AI agents orchestrated by the developer.

## 2. AI Agent Roles

- **Developer**: Oversees the entire process, defines tasks, provides instructions, and gives final approval.
- **Gemini CLI (Orchestrator)**: Manages the task lifecycle and synthesizes context. Its primary role is to create `SYNTHESIZED_CONTEXT.MD` based on `TASK.MD` and the `context/` knowledge base.
- **Claude Code (Implementer)**: Executes development and refactoring tasks as instructed in `TASK.MD`.
- **Codex (Debugger)**: Analyzes errors and suggests solutions when Claude is blocked.

## 3. Development Workflow Lifecycle

The development process follows a four-step lifecycle managed by the `gemini` helper script.

### Step 1: Task Creation
- **Command**: `gemini task new "<descriptive-task-title>"`
- **Action**: Creates a new directory `tasks/<date>-<slug>/` and initializes it with a `TASK.MD` file from the template.

### Step 2: Context Synthesis
- **Command**: `gemini task run-context` (executed within the task directory)
- **Action**: Gemini CLI analyzes the `TASK.MD`, gathers relevant static knowledge from `context/` (guided by `.gemini/metadata.json`), and generates a tailored `SYNTHESIZED_CONTEXT.MD` file for the current task.

### Step 3: Development Cycle
1.  The **Developer** provides specific instructions to Claude Code in the "개발 지시" (Development Instruction) section of `TASK.MD`.
2.  **Claude Code** executes the instructions, logging all activities, progress, and issues in the "작업 로그" (Work Log).
3.  If errors occur, **Codex** is invoked to analyze the problem and provide a solution, which is also logged.

### Step 4: Task Completion & Knowledge Assetization
1.  Once the goal is achieved, the **Developer** fills out the "변경 사항 요약" (Summary of Changes) and "컨텍스트 업데이트 요청" (Context Update Request) sections in `TASK.MD`.
2.  **Command**: `gemini task complete`
3.  **Action**: The task package is moved to `tasks/archive/`, and a record is appended to `context/CHANGELOG.md`. Any requested updates to the static knowledge base (`context/` files) are then performed based on the "컨텍스트 업데이트 요청".

## 4. Key Artifact: TASK.MD Structure

The `TASK.MD` file is the operational center of every task and contains the following sections:
- **작업 목표 (Task Goal)**: A clear, measurable objective.
- **컨텍스트 요청 (Context Request)**: Specifies the required static and dynamic context.
- **개발 지시 (Development Instruction)**: Concrete instructions for Claude Code.
- **작업 로그 (Work Log)**: A complete record of all actions, results, and errors.
- **변경 사항 요약 (Summary of Changes)**: A detailed summary of code modifications upon completion.
- **컨텍스트 업데이트 요청 (Context Update Request)**: Specifies what new knowledge should be integrated into the `context/` base.
- **최종 검토 (Final Review)**: Developer's final approval and feedback.

\n---\n## File: context/database-design.md\n
# Database Design (Entity Relationship Diagram)

This document outlines the database schema for the project, based on `docs/설계 문서/DB 설계/엔티티 설계.md`.

## High-Level Summary

The schema is divided into three main domains:
1.  **Users & Permissions**: Manages users, roles, permissions, and group memberships.
2.  **Groups & Content**: Manages groups (workspaces), channels, posts, and comments.
3.  **Recruitment & System**: Manages recruitment posts, tags, and user notifications.

---

## 1. Users & Permissions

### User (사용자)
| 컬럼명 | 데이터 타입 | 제약 조건 | 설명 |
| --- | --- | --- | --- |
| `id` | BIGINT | **PK**, Auto Increment | 사용자 고유 번호 |
| `email` | VARCHAR(255) | Not Null, **Unique** | 이메일 주소 (로그인 ID) |
| `nickname` | VARCHAR(50) | Not Null, **Unique** | 닉네임 |
| `name` | VARCHAR(50) | Not Null | 실명 |
| `user_role` | VARCHAR(20) | Not Null | 사용자 역할 ('STUDENT', 'PROFESSOR') |
| `status` | VARCHAR(20) | Not Null | 계정 상태 ('ACTIVE', 'PENDING_APPROVAL') |
| `profile_image_url` | VARCHAR(2048) | | 프로필 이미지 주소 |
| `bio` | VARCHAR(100) | | 한 줄 소개 |
| `created_at` | DATETIME | Not Null | 생성 일시 |

### Member (멤버)
| 컬럼명 | 데이터 타입 | 제약 조건 | 설명 |
| --- | --- | --- | --- |
| `id` | BIGINT | **PK**, Auto Increment | 멤버 관계 고유 번호 |
| `user_id` | BIGINT | Not Null, **FK** (User.id) | 사용자 ID |
| `group_id` | BIGINT | Not Null, **FK** (Group.id) | 그룹 ID |
| `role_id` | BIGINT | Not Null, **FK** (Role.id) | 그룹 내 역할 ID |
| `joined_at` | DATETIME | Not Null | 가입 일시 |

### Role (역할)
| 컬럼명 | 데이터 타입 | 제약 조건 | 설명 |
| --- | --- | --- | --- |
| `id` | BIGINT | **PK**, Auto Increment | 역할 고유 번호 |
| `group_id` | BIGINT | **FK** (Group.id) | 이 역할이 속한 그룹 ID (null이면 시스템 기본 역할) |
| `name` | VARCHAR(50) | Not Null | 역할 이름 (예: 그룹장, 일반 멤버) |

### Permission (권한)
| 컬럼명 | 데이터 타입 | 제약 조건 | 설명 |
| --- | --- | --- | --- |
| `id` | BIGINT | **PK**, Auto Increment | 권한 고유 번호 |
| `name` | VARCHAR(100) | Not Null, **Unique** | 권한 이름 (예: `ANNOUNCEMENT_CREATE`) |

### RolePermission (역할-권한 매핑)
| 컬럼명 | 데이터 타입 | 제약 조건 | 설명 |
| --- | --- | --- | --- |
| `role_id` | BIGINT | **PK**, **FK** (Role.id) | 역할 ID |
| `permission_id` | BIGINT | **PK**, **FK** (Permission.id) | 권한 ID |

### JoinRequest (가입 신청)
| 컬럼명 | 데이터 타입 | 제약 조건 | 설명 |
| --- | --- | --- | --- |
| `id` | BIGINT | **PK**, Auto Increment | 가입 신청 고유 번호 |
| `user_id` | BIGINT | Not Null, **FK** (User.id) | 신청한 사용자 ID |
| `group_id` | BIGINT | Not Null, **FK** (Group.id) | 신청한 그룹 ID |
| `status` | VARCHAR(20) | Not Null | 상태 ('PENDING', 'APPROVED', 'REJECTED') |
| `created_at` | DATETIME | Not Null | 신청 일시 |

---

## 2. Groups & Content

### Group (그룹)
| 컬럼명 | 데이터 타입 | 제약 조건 | 설명 |
| --- | --- | --- | --- |
| `id` | BIGINT | **PK**, Auto Increment | 그룹 고유 번호 |
| `parent_id` | BIGINT | **FK** (self-reference) | 상위 그룹 ID (계층 구조) |
| `name` | VARCHAR(100) | Not Null | 그룹 이름 |
| `description` | TEXT | | 그룹 소개 |
| `created_at` | DATETIME | Not Null | 생성 일시 |

### Channel (채널)
| 컬럼명 | 데이터 타입 | 제약 조건 | 설명 |
| --- | --- | --- | --- |
| `id` | BIGINT | **PK**, Auto Increment | 채널 고유 번호 |
| `group_id` | BIGINT | Not Null, **FK** (Group.id) | 채널이 속한 그룹 ID |
| `name` | VARCHAR(100) | Not Null | 채널 이름 (예: 공지사항) |

### Post (게시글)
| 컬럼명 | 데이터 타입 | 제약 조건 | 설명 |
| --- | --- | --- | --- |
| `id` | BIGINT | **PK**, Auto Increment | 게시글 고유 번호 |
| `channel_id` | BIGINT | Not Null, **FK** (Channel.id) | 게시글이 등록된 채널 ID |
| `author_id` | BIGINT | Not Null, **FK** (User.id) | 작성자 ID |
| `title` | VARCHAR(255) | Not Null | 제목 |
| `content` | TEXT | Not Null | 내용 |
| `created_at` | DATETIME | Not Null | 생성 일시 |

### Comment (댓글)
| 컬럼명 | 데이터 타입 | 제약 조건 | 설명 |
| --- | --- | --- | --- |
| `id` | BIGINT | **PK**, Auto Increment | 댓글 고유 번호 |
| `post_id` | BIGINT | Not Null, **FK** (Post.id) | 부모 게시글 ID |
| `author_id` | BIGINT | Not Null, **FK** (User.id) | 작성자 ID |
| `parent_comment_id` | BIGINT | **FK** (self-reference) | 부모 댓글 ID (대댓글 구조) |
| `content` | TEXT | Not Null | 내용 |
| `created_at` | DATETIME | Not Null | 생성 일시 |

---

## 3. Recruitment & System

### RecruitmentPost (모집 공고)
| 컬럼명 | 데이터 타입 | 제약 조건 | 설명 |
| --- | --- | --- | --- |
| `id` | BIGINT | **PK**, Auto Increment | 모집 공고 고유 번호 |
| `group_id` | BIGINT | Not Null, **FK** (Group.id) | 공고를 게시한 그룹 ID |
| `title` | VARCHAR(255) | Not Null | 제목 |
| `content` | TEXT | Not Null | 본문 |
| `start_date` | DATE | Not Null | 모집 시작일 |
| `end_date` | DATE | Not Null | 모집 종료일 |
| `status` | VARCHAR(20) | Not Null | 상태 ('ACTIVE', 'CLOSED') |

### Tag (태그)
| 컬럼명 | 데이터 타입 | 제약 조건 | 설명 |
| --- | --- | --- | --- |
| `id` | BIGINT | **PK**, Auto Increment | 태그 고유 번호 |
| `name` | VARCHAR(50) | Not Null, **Unique** | 태그 이름 (예: #스터디) |

### PostTag (공고-태그 매핑)
| 컬럼명 | 데이터 타입 | 제약 조건 | 설명 |
| --- | --- | --- | --- |
| `post_id` | BIGINT | **PK**, **FK** (RecruitmentPost.id) | 모집 공고 ID |
| `tag_id` | BIGINT | **PK**, **FK** (Tag.id) | 태그 ID |

### Notification (알림)
| 컬럼명 | 데이터 타입 | 제약 조건 | 설명 |
| --- | --- | --- | --- |
| `id` | BIGINT | **PK**, Auto Increment | 알림 고유 번호 |
| `recipient_id` | BIGINT | Not Null, **FK** (User.id) | 알림을 받는 사용자 ID |
| `type` | VARCHAR(50) | Not Null | 알림 종류 (예: `JOIN_APPROVED`) |
| `content` | VARCHAR(255) | Not Null | 알림 내용 |
| `is_read` | BOOLEAN | Not Null | 읽음 여부 |
| `created_at` | DATETIME | Not Null | 생성 일시 |

