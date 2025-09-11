# Project Plan: MVP and Post-MVP Roadmap

**⚠️ 현재 구현 상태**: Flutter Frontend와 Spring Boot Backend 기초 구조가 완성되었으며, Google OAuth 인증 시스템이 완전 연동되었습니다.

This document outlines the project's scope, starting with the Minimum Viable Product (MVP) and followed by the development roadmap. It is synthesized from `MVP.md` and `MVP 이후 개발 로드맵.md`.

---

## 1. MVP (Minimum Viable Product) Scope

**Core Goal:** To enable new users to discover attractive groups through the **[Explore]** and **[Recruitment]** tabs, join them, and experience systematic announcements and detailed permission management within their groups.

### 현재 구현 상태 요약:
- **✅ 완료**: 인증 시스템 (Google OAuth + JWT)
- **✅ 완료**: Flutter Frontend 기초 구조
- **✅ 완료**: Spring Boot Backend 기초 구조
- **❌ 미구현**: 그룹 관리, 미버십, 권한 시스템
- **❌ 미구현**: 모집 게시판, 게시글/댓글 시스템
- **❌ 미구현**: 알림, 관리자 페이지, 사용자 프로필

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
