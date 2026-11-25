# 백엔드 HTTP API 인덱스

Univ Group Management · 134edd3 · Spring Controller 기준. 개발 전용 인증 경로 2개는 목록에서 제외했습니다.
총 144개 매핑, 아래 표에는 142개를 수록했습니다. API 존재 여부와 앱에서의 시연 가능 여부를 구분합니다.
## AdminController

| 메서드 | 경로 |
| --- | --- |
| GET | `/api/admin/join-requests` |
| PATCH | `/api/admin/join-requests/{id}` |
| PATCH | `/api/admin/group-requests/{id}` |
| GET | `/api/admin/group-requests` |

## AuthController

| 메서드 | 경로 |
| --- | --- |
| POST | `/api/auth/google` |
| POST | `/api/auth/google/callback` |
| GET | `/api/auth/verify` |
| POST | `/api/auth/refresh` |
| POST | `/api/auth/logout` |

## ChannelReadPositionController

| 메서드 | 경로 |
| --- | --- |
| GET | `/api/channels/{channelId}/read-position` |
| PUT | `/api/channels/{channelId}/read-position` |
| GET | `/api/channels/{channelId}/unread-count` |
| GET | `/api/channels/unread-counts` |

## ContentController

| 메서드 | 경로 |
| --- | --- |
| GET | `/api/groups/{groupId}/workspaces` |
| POST | `/api/groups/{groupId}/workspaces` |
| PUT | `/api/workspaces/{workspaceId}` |
| DELETE | `/api/workspaces/{workspaceId}` |
| GET | `/api/workspaces/{workspaceId}/channels` |
| GET | `/api/groups/{groupId}/channels` |
| GET | `/api/groups/{groupId}/channels/admin` |
| POST | `/api/workspaces/{workspaceId}/channels` |
| POST | `/api/workspaces/{workspaceId}/channels/with-permissions` |
| PUT | `/api/channels/{channelId}` |
| DELETE | `/api/channels/{channelId}` |
| GET | `/api/channels/{channelId}/posts` |
| POST | `/api/channels/{channelId}/posts` |
| GET | `/api/posts/{postId}` |
| PUT | `/api/posts/{postId}` |
| DELETE | `/api/posts/{postId}` |
| GET | `/api/posts/{postId}/comments` |
| POST | `/api/posts/{postId}/comments` |
| PUT | `/api/comments/{commentId}` |
| DELETE | `/api/comments/{commentId}` |
| GET | `/api/channels/{channelId}/permissions/me` |
| GET | `/api/channels/{channelId}/role-bindings` |
| POST | `/api/channels/{channelId}/role-bindings` |
| PUT | `/api/channels/{channelId}/role-bindings/{bindingId}` |
| DELETE | `/api/channels/{channelId}/role-bindings/{bindingId}` |

## EmailVerificationController

| 메서드 | 경로 |
| --- | --- |
| POST | `/api/email/verification/send` |
| POST | `/api/email/verification/verify` |

## GroupController

| 메서드 | 경로 |
| --- | --- |
| POST | `/api/groups` |
| GET | `/api/groups` |
| GET | `/api/groups/all` |
| GET | `/api/groups/explore` |
| GET | `/api/groups/hierarchy` |
| GET | `/api/groups/{groupId}` |
| PUT | `/api/groups/{groupId}` |
| DELETE | `/api/groups/{groupId}` |
| POST | `/api/groups/{groupId}/join` |
| DELETE | `/api/groups/{groupId}/leave` |
| GET | `/api/groups/{groupId}/members` |
| GET | `/api/groups/{groupId}/members/count` |
| GET | `/api/groups/{groupId}/members/preview` |
| GET | `/api/groups/{groupId}/members/me` |
| PUT | `/api/groups/{groupId}/members/{userId}/role` |
| DELETE | `/api/groups/{groupId}/members/{userId}` |
| POST | `/api/groups/{groupId}/roles` |
| GET | `/api/groups/{groupId}/roles` |
| GET | `/api/groups/{groupId}/roles/{roleId}` |
| PUT | `/api/groups/{groupId}/roles/{roleId}` |
| DELETE | `/api/groups/{groupId}/roles/{roleId}` |
| GET | `/api/groups/{groupId}/join-requests` |
| PATCH | `/api/groups/{groupId}/join-requests/{requestId}` |
| POST | `/api/groups/{groupId}/sub-groups/requests` |
| GET | `/api/groups/{groupId}/sub-groups/requests` |
| PATCH | `/api/groups/{groupId}/sub-groups/requests/{requestId}` |
| GET | `/api/groups/{groupId}/sub-groups` |
| POST | `/api/groups/{groupId}/professors/{professorId}` |
| DELETE | `/api/groups/{groupId}/professors/{professorId}` |
| GET | `/api/groups/{groupId}/professors` |
| POST | `/api/groups/{groupId}/transfer-ownership/{newOwnerId}` |
| GET | `/api/groups/{groupId}/workspace` |
| GET | `/api/groups/{groupId}/admin/stats` |
| GET | `/api/groups/{groupId}/membership/check` |
| POST | `/api/groups/membership/check` |
| GET | `/api/groups/{groupId}/permissions` |
| GET | `/api/groups/{groupId}/available-places` |

## GroupEventController

| 메서드 | 경로 |
| --- | --- |
| GET | `/api/groups/{groupId}/events` |
| POST | `/api/groups/{groupId}/events` |
| PUT | `/api/groups/{groupId}/events/{eventId}` |
| DELETE | `/api/groups/{groupId}/events/{eventId}` |

## MeController

| 메서드 | 경로 |
| --- | --- |
| GET | `/api/me` |
| GET | `/api/me/groups` |

## PersonalCalendarController

| 메서드 | 경로 |
| --- | --- |
| GET | `/api/calendar` |
| POST | `/api/calendar` |
| PUT | `/api/calendar/{eventId}` |
| DELETE | `/api/calendar/{eventId}` |

## PersonalTimetableController

| 메서드 | 경로 |
| --- | --- |
| GET | `/api/timetable` |
| POST | `/api/timetable` |
| PUT | `/api/timetable/{scheduleId}` |
| DELETE | `/api/timetable/{scheduleId}` |

## PlaceController

| 메서드 | 경로 |
| --- | --- |
| GET | `/api/places` |
| GET | `/api/groups/{groupId}/reservable-places` |
| GET | `/api/places/{id}` |
| POST | `/api/places` |
| PATCH | `/api/places/{id}` |
| DELETE | `/api/places/{id}` |
| POST | `/api/places/{id}/usage-requests` |
| PATCH | `/api/places/{placeId}/usage-groups/{groupId}` |
| DELETE | `/api/places/{placeId}/usage-groups/{groupId}` |
| GET | `/api/places/{id}/usage-requests/pending` |
| GET | `/api/places/{id}/usage-groups` |
| POST | `/api/places/availability` |
| POST | `/api/places/available-at` |

## PlaceReservationController

| 메서드 | 경로 |
| --- | --- |
| POST | `/api/places/{placeId}/reservations` |
| GET | `/api/places/{placeId}/reservations` |
| PATCH | `/api/reservations/{reservationId}` |
| DELETE | `/api/reservations/{reservationId}` |
| GET | `/api/places/calendar` |

## PlaceTimeManagementController

| 메서드 | 경로 |
| --- | --- |
| GET | `/api/places/{placeId}/operating-hours` |
| PUT | `/api/places/{placeId}/operating-hours` |
| PATCH | `/api/places/{placeId}/operating-hours/{dayOfWeek}` |
| GET | `/api/places/{placeId}/restricted-times` |
| POST | `/api/places/{placeId}/restricted-times` |
| PATCH | `/api/places/{placeId}/restricted-times/{restrictedTimeId}` |
| DELETE | `/api/places/{placeId}/restricted-times/{restrictedTimeId}` |
| GET | `/api/places/{placeId}/closures` |
| POST | `/api/places/{placeId}/closures/full-day` |
| POST | `/api/places/{placeId}/closures/partial` |
| DELETE | `/api/places/{placeId}/closures/{closureId}` |
| GET | `/api/places/{placeId}/available-times` |

## RecruitmentController

| 메서드 | 경로 |
| --- | --- |
| POST | `/api/groups/{groupId}/recruitments` |
| GET | `/api/groups/{groupId}/recruitments` |
| GET | `/api/recruitments/{recruitmentId}` |
| PUT | `/api/recruitments/{recruitmentId}` |
| PATCH | `/api/recruitments/{recruitmentId}/close` |
| DELETE | `/api/recruitments/{recruitmentId}` |
| GET | `/api/groups/{groupId}/recruitments/archive` |
| GET | `/api/recruitments/public` |
| POST | `/api/recruitments/{recruitmentId}/applications` |
| GET | `/api/recruitments/{recruitmentId}/applications` |
| GET | `/api/applications/{applicationId}` |
| PATCH | `/api/applications/{applicationId}/review` |
| DELETE | `/api/applications/{applicationId}` |
| GET | `/api/recruitments/{recruitmentId}/stats` |

## RoleController

| 메서드 | 경로 |
| --- | --- |
| POST | `/api/roles/apply` |

## UserController

| 메서드 | 경로 |
| --- | --- |
| POST | `/api/users` |
| GET | `/api/users/nickname-check` |
| PUT | `/api/users/profile` |
| GET | `/api/users/search` |
| GET | `/api/users/me/join-requests` |
| GET | `/api/users/me/sub-group-requests` |
