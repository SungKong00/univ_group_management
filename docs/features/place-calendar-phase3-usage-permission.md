# 장소 캘린더 Phase 3: 예약 권한 신청 시스템

> **상태**: 계획 수립 완료, 구현 대기
> **예상 시간**: 6-8시간
> **우선순위**: P0 (필수)
> **의존성**: Phase 2 프론트엔드 기본 구현 (대기)
> **관련 문서**: [장소 캘린더 명세](place-calendar-specification.md) | [통합 로드맵](calendar-integration-roadmap.md)

---

## 📋 개요

장소 사용 권한 신청 및 승인 시스템을 구현합니다. PlaceUsageGroup 엔티티를 활용하여 예약 권한 관리 플로우를 완성합니다.

### 목표
- 예약 권한 신청 UI 구현
- 그룹 관리 페이지에 승인/거절 기능 추가
- 권한 취소 기능 구현 (경고 포함)
- 백엔드 API 개선 (rejectionReason 필드 추가)

---

## 📐 설계 요약

### 예약 권한 신청 플로우
```
사용자 (CALENDAR_MANAGE) → [예약 권한 신청] 버튼 클릭
  ↓
장소 선택 (드롭다운) + 신청 사유 입력 (선택)
  ↓
PlaceUsageGroup 생성 (status: PENDING, reason: null)
  ↓
관리 그룹의 CALENDAR_MANAGE 보유자가 그룹 관리 페이지에서 확인
  ↓
[승인] → status: APPROVED
[거절] → status: REJECTED, rejectionReason: "..."
```

---

## 🎯 작업 항목

### 1. 백엔드 API 개선 (2-3h)

#### 1.1. PlaceUsageGroup 엔티티 수정
```kotlin
// src/main/kotlin/com/univ/domain/place/entity/PlaceUsageGroup.kt

@Entity
@Table(
    name = "place_usage_groups",
    uniqueConstraints = [
        UniqueConstraint(columnNames = ["place_id", "group_id"])
    ]
)
class PlaceUsageGroup(
    @Id
    @GeneratedValue(generator = "uuid2")
    val id: UUID = UUID.randomUUID(),

    @Column(name = "place_id", nullable = false)
    val placeId: UUID,

    @Column(name = "group_id", nullable = false)
    val groupId: UUID,

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    var status: UsageStatus = UsageStatus.PENDING,

    @Column(name = "rejection_reason", length = 500)
    var rejectionReason: String? = null,  // 신규 필드

    @Column(name = "created_at", nullable = false)
    val createdAt: LocalDateTime = LocalDateTime.now(),

    @Column(name = "updated_at", nullable = false)
    var updatedAt: LocalDateTime = LocalDateTime.now()
) {
    enum class UsageStatus {
        PENDING,   // 대기 중
        APPROVED,  // 승인됨
        REJECTED   // 거절됨
    }

    fun approve() {
        status = UsageStatus.APPROVED
        rejectionReason = null
        updatedAt = LocalDateTime.now()
    }

    fun reject(reason: String?) {
        status = UsageStatus.REJECTED
        rejectionReason = reason
        updatedAt = LocalDateTime.now()
    }
}
```

#### 1.2. DTO 클래스 추가
```kotlin
// src/main/kotlin/com/univ/presentation/dto/place/PlaceUsageGroupDto.kt

// 사용 신청 요청
data class CreateUsageRequestDto(
    @field:Size(max = 500, message = "사유는 500자 이내로 입력하세요")
    val reason: String? = null
)

// 승인/거절 요청
data class UpdateUsageStatusDto(
    @field:NotNull(message = "상태는 필수입니다")
    val status: PlaceUsageGroup.UsageStatus,

    @field:Size(max = 500, message = "거절 사유는 500자 이내로 입력하세요")
    val rejectionReason: String? = null
)

// 사용 그룹 응답
data class PlaceUsageGroupResponse(
    val id: UUID,
    val placeId: UUID,
    val groupId: UUID,
    val groupName: String,
    val status: PlaceUsageGroup.UsageStatus,
    val rejectionReason: String?,
    val createdAt: LocalDateTime,
    val updatedAt: LocalDateTime
) {
    companion object {
        fun from(usageGroup: PlaceUsageGroup, groupName: String) = PlaceUsageGroupResponse(
            id = usageGroup.id,
            placeId = usageGroup.placeId,
            groupId = usageGroup.groupId,
            groupName = groupName,
            status = usageGroup.status,
            rejectionReason = usageGroup.rejectionReason,
            createdAt = usageGroup.createdAt,
            updatedAt = usageGroup.updatedAt
        )
    }
}
```

#### 1.3. PlaceUsageGroupService 개선
```kotlin
// src/main/kotlin/com/univ/domain/place/service/PlaceUsageGroupService.kt

@Service
@Transactional(readOnly = true)
class PlaceUsageGroupService(
    private val placeUsageGroupRepository: PlaceUsageGroupRepository,
    private val placeRepository: PlaceRepository,
    private val groupRepository: GroupRepository,
    private val placeReservationRepository: PlaceReservationRepository,
    private val permissionService: PermissionService
) {
    // 사용 신청 생성
    @Transactional
    fun createUsageRequest(
        placeId: UUID,
        groupId: UUID,
        requesterId: UUID,
        reason: String?
    ): PlaceUsageGroup {
        // 권한 체크: CALENDAR_MANAGE 필요
        if (!permissionService.hasPermission(requesterId, groupId, GroupPermission.CALENDAR_MANAGE)) {
            throw ForbiddenException("장소 사용 신청 권한이 없습니다")
        }

        // 장소 존재 확인
        val place = placeRepository.findByIdAndDeletedAtIsNull(placeId)
            ?: throw NotFoundException("장소를 찾을 수 없습니다")

        // 중복 신청 체크
        placeUsageGroupRepository.findByPlaceIdAndGroupId(placeId, groupId)?.let {
            when (it.status) {
                UsageStatus.PENDING -> throw ConflictException("이미 신청 중입니다")
                UsageStatus.APPROVED -> throw ConflictException("이미 승인된 장소입니다")
                UsageStatus.REJECTED -> {
                    // 거절된 경우 재신청 가능 (기존 레코드 업데이트)
                    it.status = UsageStatus.PENDING
                    it.rejectionReason = null
                    it.updatedAt = LocalDateTime.now()
                    return placeUsageGroupRepository.save(it)
                }
            }
        }

        // 새로운 신청 생성
        val usageGroup = PlaceUsageGroup(
            placeId = placeId,
            groupId = groupId,
            status = UsageStatus.PENDING,
            rejectionReason = null
        )
        return placeUsageGroupRepository.save(usageGroup)
    }

    // 승인/거절 처리
    @Transactional
    fun updateUsageStatus(
        placeId: UUID,
        targetGroupId: UUID,
        adminId: UUID,
        adminGroupId: UUID,
        status: UsageStatus,
        rejectionReason: String?
    ): PlaceUsageGroup {
        // 관리 주체 확인
        val place = placeRepository.findByIdAndDeletedAtIsNull(placeId)
            ?: throw NotFoundException("장소를 찾을 수 없습니다")

        if (place.managingGroupId != adminGroupId) {
            throw ForbiddenException("관리 주체만 승인/거절할 수 있습니다")
        }

        // 권한 체크: CALENDAR_MANAGE 필요
        if (!permissionService.hasPermission(adminId, adminGroupId, GroupPermission.CALENDAR_MANAGE)) {
            throw ForbiddenException("권한이 없습니다")
        }

        // UsageGroup 조회
        val usageGroup = placeUsageGroupRepository.findByPlaceIdAndGroupId(placeId, targetGroupId)
            ?: throw NotFoundException("사용 신청을 찾을 수 없습니다")

        if (usageGroup.status != UsageStatus.PENDING) {
            throw ConflictException("이미 처리된 신청입니다")
        }

        // 상태 업데이트
        when (status) {
            UsageStatus.APPROVED -> usageGroup.approve()
            UsageStatus.REJECTED -> usageGroup.reject(rejectionReason)
            UsageStatus.PENDING -> throw IllegalArgumentException("PENDING 상태로 변경할 수 없습니다")
        }

        return placeUsageGroupRepository.save(usageGroup)
    }

    // 권한 취소
    @Transactional
    fun revokeUsagePermission(
        placeId: UUID,
        targetGroupId: UUID,
        adminId: UUID,
        adminGroupId: UUID
    ): Int {
        // 관리 주체 확인 및 권한 체크
        val place = placeRepository.findByIdAndDeletedAtIsNull(placeId)
            ?: throw NotFoundException("장소를 찾을 수 없습니다")

        if (place.managingGroupId != adminGroupId) {
            throw ForbiddenException("관리 주체만 권한을 취소할 수 있습니다")
        }

        if (!permissionService.hasPermission(adminId, adminGroupId, GroupPermission.CALENDAR_MANAGE)) {
            throw ForbiddenException("권한이 없습니다")
        }

        // UsageGroup 삭제
        placeUsageGroupRepository.deleteByPlaceIdAndGroupId(placeId, targetGroupId)

        // 미래 예약 삭제 및 개수 반환
        val deletedCount = placeReservationRepository.deleteFutureReservationsByPlaceAndGroup(
            placeId = placeId,
            groupId = targetGroupId,
            now = LocalDateTime.now()
        )

        return deletedCount
    }

    // 대기 중인 신청 목록 조회 (관리 주체용)
    fun getPendingRequests(
        placeId: UUID,
        adminId: UUID,
        adminGroupId: UUID
    ): List<PlaceUsageGroupResponse> {
        val place = placeRepository.findByIdAndDeletedAtIsNull(placeId)
            ?: throw NotFoundException("장소를 찾을 수 없습니다")

        if (place.managingGroupId != adminGroupId) {
            throw ForbiddenException("관리 주체만 조회할 수 있습니다")
        }

        if (!permissionService.hasPermission(adminId, adminGroupId, GroupPermission.CALENDAR_MANAGE)) {
            throw ForbiddenException("권한이 없습니다")
        }

        return placeUsageGroupRepository.findByPlaceIdAndStatus(placeId, UsageStatus.PENDING)
            .map { usageGroup ->
                val group = groupRepository.findById(usageGroup.groupId).orElseThrow()
                PlaceUsageGroupResponse.from(usageGroup, group.name)
            }
    }

    // 승인된 사용 그룹 목록 조회
    fun getApprovedGroups(placeId: UUID): List<PlaceUsageGroupResponse> {
        return placeUsageGroupRepository.findByPlaceIdAndStatus(placeId, UsageStatus.APPROVED)
            .map { usageGroup ->
                val group = groupRepository.findById(usageGroup.groupId).orElseThrow()
                PlaceUsageGroupResponse.from(usageGroup, group.name)
            }
    }
}
```

#### 1.4. PlaceController API 추가
```kotlin
// src/main/kotlin/com/univ/presentation/controller/PlaceController.kt

@RestController
@RequestMapping("/api/places")
class PlaceController(
    private val placeService: PlaceService,
    private val placeUsageGroupService: PlaceUsageGroupService
) {
    // 사용 신청
    @PostMapping("/{placeId}/usage-requests")
    fun createUsageRequest(
        @PathVariable placeId: UUID,
        @RequestBody @Valid request: CreateUsageRequestDto,
        @AuthenticationPrincipal principal: AuthenticatedUser
    ): ResponseEntity<PlaceUsageGroupResponse> {
        val usageGroup = placeUsageGroupService.createUsageRequest(
            placeId = placeId,
            groupId = principal.currentGroupId,
            requesterId = principal.userId,
            reason = request.reason
        )
        val group = groupRepository.findById(usageGroup.groupId).orElseThrow()
        return ResponseEntity.ok(PlaceUsageGroupResponse.from(usageGroup, group.name))
    }

    // 승인/거절
    @PatchMapping("/{placeId}/usage-groups/{groupId}")
    fun updateUsageStatus(
        @PathVariable placeId: UUID,
        @PathVariable groupId: UUID,
        @RequestBody @Valid request: UpdateUsageStatusDto,
        @AuthenticationPrincipal principal: AuthenticatedUser
    ): ResponseEntity<PlaceUsageGroupResponse> {
        val usageGroup = placeUsageGroupService.updateUsageStatus(
            placeId = placeId,
            targetGroupId = groupId,
            adminId = principal.userId,
            adminGroupId = principal.currentGroupId,
            status = request.status,
            rejectionReason = request.rejectionReason
        )
        val group = groupRepository.findById(usageGroup.groupId).orElseThrow()
        return ResponseEntity.ok(PlaceUsageGroupResponse.from(usageGroup, group.name))
    }

    // 권한 취소
    @DeleteMapping("/{placeId}/usage-groups/{groupId}")
    fun revokeUsagePermission(
        @PathVariable placeId: UUID,
        @PathVariable groupId: UUID,
        @AuthenticationPrincipal principal: AuthenticatedUser
    ): ResponseEntity<Map<String, Any>> {
        val deletedCount = placeUsageGroupService.revokeUsagePermission(
            placeId = placeId,
            targetGroupId = groupId,
            adminId = principal.userId,
            adminGroupId = principal.currentGroupId
        )
        return ResponseEntity.ok(mapOf(
            "message" to "권한이 취소되었습니다",
            "deletedReservations" to deletedCount
        ))
    }

    // 대기 중인 신청 목록 조회
    @GetMapping("/{placeId}/usage-requests/pending")
    fun getPendingRequests(
        @PathVariable placeId: UUID,
        @AuthenticationPrincipal principal: AuthenticatedUser
    ): ResponseEntity<List<PlaceUsageGroupResponse>> {
        val requests = placeUsageGroupService.getPendingRequests(
            placeId = placeId,
            adminId = principal.userId,
            adminGroupId = principal.currentGroupId
        )
        return ResponseEntity.ok(requests)
    }

    // 승인된 사용 그룹 목록 조회
    @GetMapping("/{placeId}/usage-groups")
    fun getApprovedGroups(
        @PathVariable placeId: UUID
    ): ResponseEntity<List<PlaceUsageGroupResponse>> {
        val groups = placeUsageGroupService.getApprovedGroups(placeId)
        return ResponseEntity.ok(groups)
    }
}
```

#### 1.5. PlaceReservationRepository 메서드 추가
```kotlin
interface PlaceReservationRepository : JpaRepository<PlaceReservation, UUID> {
    @Modifying
    @Query("""
        DELETE FROM PlaceReservation pr
        WHERE pr.placeId = :placeId
          AND pr.groupId = :groupId
          AND pr.startDatetime > :now
    """)
    fun deleteFutureReservationsByPlaceAndGroup(
        placeId: UUID,
        groupId: UUID,
        now: LocalDateTime
    ): Int
}
```

---

### 2. 예약 권한 신청 UI (2h)

#### 파일 위치
```
lib/presentation/pages/workspace/place/
  └─ dialogs/
      └─ place_usage_request_dialog.dart
```

#### UI 컴포넌트
```dart
class PlaceUsageRequestDialog extends ConsumerStatefulWidget {
  final String groupId;

  @override
  _PlaceUsageRequestDialogState createState() => _PlaceUsageRequestDialogState();
}

class _PlaceUsageRequestDialogState extends ConsumerState<PlaceUsageRequestDialog> {
  String? selectedPlaceId;
  String? reason;

  @override
  Widget build(BuildContext context) {
    final places = ref.watch(placesProvider(widget.groupId));

    return AlertDialog(
      title: Text('장소 예약 권한 신청'),
      content: places.when(
        loading: () => Center(child: CircularProgressIndicator()),
        error: (e, s) => Text('에러: $e'),
        data: (placeList) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 장소 선택 드롭다운
            DropdownButtonFormField<String>(
              decoration: InputDecoration(labelText: '장소 선택'),
              value: selectedPlaceId,
              items: placeList
                .where((p) => p.managingGroupId != widget.groupId)  // 자신의 장소는 제외
                .map((p) => DropdownMenuItem(
                  value: p.id,
                  child: Text(p.displayName),
                ))
                .toList(),
              onChanged: (value) => setState(() => selectedPlaceId = value),
            ),
            SizedBox(height: 16),
            // 신청 사유 입력 (선택)
            TextField(
              decoration: InputDecoration(
                labelText: '신청 사유 (선택)',
                hintText: '예: 정기 회의를 위해 사용하고자 합니다',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              maxLength: 500,
              onChanged: (value) => reason = value,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('취소'),
        ),
        ElevatedButton(
          onPressed: selectedPlaceId != null ? _handleSubmit : null,
          child: Text('신청'),
        ),
      ],
    );
  }

  Future<void> _handleSubmit() async {
    try {
      await ref.read(placeServiceProvider).createUsageRequest(
        placeId: selectedPlaceId!,
        groupId: widget.groupId,
        reason: reason,
      );

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('권한 신청이 완료되었습니다')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('신청 실패: $e')),
      );
    }
  }
}
```

---

### 3. 그룹 관리 페이지 - 예약 권한 승인 UI (2-3h)

#### 파일 위치
```
lib/presentation/pages/workspace/group_admin/
  └─ tabs/
      └─ place_usage_management_tab.dart
```

#### UI 컴포넌트
```dart
class PlaceUsageManagementTab extends ConsumerWidget {
  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 자신의 그룹이 관리하는 장소 목록
    final managedPlaces = ref.watch(managedPlacesProvider(groupId));

    return managedPlaces.when(
      loading: () => Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('에러: $e')),
      data: (places) => places.isEmpty
        ? Center(child: Text('관리하는 장소가 없습니다'))
        : ListView.builder(
            itemCount: places.length,
            itemBuilder: (context, index) {
              final place = places[index];
              return _buildPlaceSection(context, ref, place);
            },
          ),
    );
  }

  Widget _buildPlaceSection(BuildContext context, WidgetRef ref, Place place) {
    final pendingRequests = ref.watch(pendingUsageRequestsProvider(place.id));

    return ExpansionTile(
      title: Text(place.displayName),
      subtitle: Text('${place.building} ${place.roomNumber}'),
      children: [
        pendingRequests.when(
          loading: () => ListTile(
            title: Text('로딩 중...'),
            leading: CircularProgressIndicator(),
          ),
          error: (e, s) => ListTile(
            title: Text('에러: $e'),
            leading: Icon(Icons.error, color: Colors.red),
          ),
          data: (requests) => requests.isEmpty
            ? ListTile(
                title: Text('대기 중인 신청이 없습니다'),
                leading: Icon(Icons.check_circle, color: Colors.green),
              )
            : Column(
                children: requests.map((request) => _buildRequestCard(
                  context,
                  ref,
                  place.id,
                  request,
                )).toList(),
              ),
        ),
      ],
    );
  }

  Widget _buildRequestCard(
    BuildContext context,
    WidgetRef ref,
    String placeId,
    PlaceUsageGroupResponse request,
  ) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        title: Text(request.groupName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('신청 일시: ${_formatDateTime(request.createdAt)}'),
            if (request.rejectionReason != null)
              Text(
                '거절 사유: ${request.rejectionReason}',
                style: TextStyle(color: Colors.red),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.check, color: Colors.green),
              onPressed: () => _showApproveDialog(context, ref, placeId, request),
              tooltip: '승인',
            ),
            IconButton(
              icon: Icon(Icons.close, color: Colors.red),
              onPressed: () => _showRejectDialog(context, ref, placeId, request),
              tooltip: '거절',
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showApproveDialog(
    BuildContext context,
    WidgetRef ref,
    String placeId,
    PlaceUsageGroupResponse request,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('승인 확인'),
        content: Text('${request.groupName}의 예약 권한을 승인하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('승인'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(placeServiceProvider).updateUsageStatus(
          placeId: placeId,
          groupId: request.groupId,
          status: UsageStatus.approved,
          rejectionReason: null,
        );

        ref.invalidate(pendingUsageRequestsProvider(placeId));

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('승인되었습니다')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('승인 실패: $e')),
        );
      }
    }
  }

  Future<void> _showRejectDialog(
    BuildContext context,
    WidgetRef ref,
    String placeId,
    PlaceUsageGroupResponse request,
  ) async {
    String? rejectionReason;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('거절 확인'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${request.groupName}의 예약 권한을 거절하시겠습니까?'),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: '거절 사유 (선택)',
                hintText: '예: 현재 장소 사용이 제한됩니다',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              maxLength: 500,
              onChanged: (value) => rejectionReason = value,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('거절'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(placeServiceProvider).updateUsageStatus(
          placeId: placeId,
          groupId: request.groupId,
          status: UsageStatus.rejected,
          rejectionReason: rejectionReason,
        );

        ref.invalidate(pendingUsageRequestsProvider(placeId));

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('거절되었습니다')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('거절 실패: $e')),
        );
      }
    }
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
           '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
```

---

### 4. 권한 취소 기능 (1h)

#### UI 컴포넌트 추가 (승인된 사용 그룹 목록)
```dart
class ApprovedUsageGroupsList extends ConsumerWidget {
  final String placeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final approvedGroups = ref.watch(approvedUsageGroupsProvider(placeId));

    return approvedGroups.when(
      loading: () => Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('에러: $e')),
      data: (groups) => groups.isEmpty
        ? Center(child: Text('승인된 사용 그룹이 없습니다'))
        : ListView.builder(
            itemCount: groups.length,
            itemBuilder: (context, index) {
              final group = groups[index];
              return ListTile(
                title: Text(group.groupName),
                subtitle: Text('승인 일시: ${_formatDateTime(group.updatedAt)}'),
                trailing: IconButton(
                  icon: Icon(Icons.remove_circle, color: Colors.red),
                  onPressed: () => _showRevokeDialog(context, ref, placeId, group),
                  tooltip: '권한 취소',
                ),
              );
            },
          ),
    );
  }

  Future<void> _showRevokeDialog(
    BuildContext context,
    WidgetRef ref,
    String placeId,
    PlaceUsageGroupResponse group,
  ) async {
    // 미래 예약 개수 조회 (추가 API 필요)
    final futureReservationsCount = await ref.read(placeServiceProvider)
      .getFutureReservationsCount(placeId, group.groupId);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('권한 취소 확인'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${group.groupName}의 예약 권한을 취소하시겠습니까?'),
            SizedBox(height: 16),
            if (futureReservationsCount > 0)
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.red),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '$futureReservationsCount개의 예약이 취소됩니다',
                        style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('권한 취소'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(placeServiceProvider).revokeUsagePermission(
          placeId: placeId,
          groupId: group.groupId,
        );

        ref.invalidate(approvedUsageGroupsProvider(placeId));

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('권한이 취소되었습니다')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('권한 취소 실패: $e')),
        );
      }
    }
  }
}
```

---

## ✅ 완료 조건

- [ ] PlaceUsageGroup 엔티티에 rejectionReason 필드 추가
- [ ] 백엔드 API 구현 (신청, 승인, 거절, 취소)
- [ ] 예약 권한 신청 UI 구현 및 테스트
- [ ] 그룹 관리 페이지에 승인/거절 탭 추가
- [ ] 권한 취소 기능 구현 (경고 다이얼로그 포함)
- [ ] 통합 테스트 (전체 플로우)
- [ ] 에러 핸들링 (권한 부족, 중복 신청 등)

---

## 🔗 관련 문서

- [장소 캘린더 명세](place-calendar-specification.md)
- [통합 로드맵](calendar-integration-roadmap.md)
- [그룹 관리 페이지 명세](../ui-ux/pages/group-admin-page.md)
- [권한 시스템](../concepts/permission-system.md)

---

**다음 단계**: Phase 4 - 예약 시스템 구현 (그룹 일정 통합)
