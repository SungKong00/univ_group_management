import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/place_time_models.dart';
import '../repositories/place_time_repository.dart';

/// Repository Provider
final placeTimeRepositoryProvider = Provider<PlaceTimeRepository>((ref) {
  return ApiPlaceTimeRepository();
});

// ========================================
// 운영시간 Providers
// ========================================

/// 운영시간 조회 Provider
final operatingHoursProvider = FutureProvider.autoDispose
    .family<List<OperatingHoursResponse>, int>((ref, placeId) async {
      final repository = ref.read(placeTimeRepositoryProvider);
      return await repository.getOperatingHours(placeId);
    });

/// 운영시간 설정 Provider (Mutation)
class SetOperatingHoursParams {
  final int placeId;
  final SetOperatingHoursRequest request;

  const SetOperatingHoursParams({required this.placeId, required this.request});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is SetOperatingHoursParams &&
        other.placeId == placeId &&
        other.request == request;
  }

  @override
  int get hashCode => placeId.hashCode ^ request.hashCode;
}

final setOperatingHoursProvider = FutureProvider.autoDispose
    .family<List<OperatingHoursResponse>, SetOperatingHoursParams>((
      ref,
      params,
    ) async {
      final repository = ref.read(placeTimeRepositoryProvider);
      final result = await repository.setOperatingHours(
        params.placeId,
        params.request,
      );

      // 성공 후 목록 새로고침
      ref.invalidate(operatingHoursProvider(params.placeId));

      return result;
    });

// ========================================
// 금지시간 Providers
// ========================================

/// 금지시간 조회 Provider
final restrictedTimesProvider = FutureProvider.autoDispose
    .family<List<RestrictedTimeResponse>, int>((ref, placeId) async {
      final repository = ref.read(placeTimeRepositoryProvider);
      return await repository.getRestrictedTimes(placeId);
    });

/// 금지시간 추가 Provider (Mutation)
class AddRestrictedTimeParams {
  final int placeId;
  final AddRestrictedTimeRequest request;

  const AddRestrictedTimeParams({required this.placeId, required this.request});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is AddRestrictedTimeParams &&
        other.placeId == placeId &&
        other.request == request;
  }

  @override
  int get hashCode => placeId.hashCode ^ request.hashCode;
}

final addRestrictedTimeProvider = FutureProvider.autoDispose
    .family<RestrictedTimeResponse, AddRestrictedTimeParams>((
      ref,
      params,
    ) async {
      final repository = ref.read(placeTimeRepositoryProvider);
      final result = await repository.addRestrictedTime(
        params.placeId,
        params.request,
      );

      // 성공 후 목록 새로고침
      ref.invalidate(restrictedTimesProvider(params.placeId));

      return result;
    });

/// 금지시간 수정 Provider (Mutation)
class UpdateRestrictedTimeParams {
  final int placeId;
  final int restrictedTimeId;
  final AddRestrictedTimeRequest request;

  const UpdateRestrictedTimeParams({
    required this.placeId,
    required this.restrictedTimeId,
    required this.request,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is UpdateRestrictedTimeParams &&
        other.placeId == placeId &&
        other.restrictedTimeId == restrictedTimeId &&
        other.request == request;
  }

  @override
  int get hashCode =>
      placeId.hashCode ^ restrictedTimeId.hashCode ^ request.hashCode;
}

final updateRestrictedTimeProvider = FutureProvider.autoDispose
    .family<RestrictedTimeResponse, UpdateRestrictedTimeParams>((
      ref,
      params,
    ) async {
      final repository = ref.read(placeTimeRepositoryProvider);
      final result = await repository.updateRestrictedTime(
        params.placeId,
        params.restrictedTimeId,
        params.request,
      );

      // 성공 후 목록 새로고침
      ref.invalidate(restrictedTimesProvider(params.placeId));

      return result;
    });

/// 금지시간 삭제 Provider (Mutation)
class DeleteRestrictedTimeParams {
  final int placeId;
  final int restrictedTimeId;

  const DeleteRestrictedTimeParams({
    required this.placeId,
    required this.restrictedTimeId,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is DeleteRestrictedTimeParams &&
        other.placeId == placeId &&
        other.restrictedTimeId == restrictedTimeId;
  }

  @override
  int get hashCode => placeId.hashCode ^ restrictedTimeId.hashCode;
}

final deleteRestrictedTimeProvider = FutureProvider.autoDispose
    .family<void, DeleteRestrictedTimeParams>((ref, params) async {
      final repository = ref.read(placeTimeRepositoryProvider);
      await repository.deleteRestrictedTime(
        params.placeId,
        params.restrictedTimeId,
      );

      // 성공 후 목록 새로고침
      ref.invalidate(restrictedTimesProvider(params.placeId));
    });

// ========================================
// 임시 휴무 Providers
// ========================================

/// 임시 휴무 조회 Provider
class GetClosuresParams {
  final int placeId;
  final String from;
  final String to;

  const GetClosuresParams({
    required this.placeId,
    required this.from,
    required this.to,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is GetClosuresParams &&
        other.placeId == placeId &&
        other.from == from &&
        other.to == to;
  }

  @override
  int get hashCode => placeId.hashCode ^ from.hashCode ^ to.hashCode;
}

final closuresProvider = FutureProvider.autoDispose
    .family<List<PlaceClosureResponse>, GetClosuresParams>((ref, params) async {
      final repository = ref.read(placeTimeRepositoryProvider);
      return await repository.getClosures(
        params.placeId,
        params.from,
        params.to,
      );
    });

/// 전일 휴무 추가 Provider (Mutation)
class AddFullDayClosureParams {
  final int placeId;
  final AddFullDayClosureRequest request;

  const AddFullDayClosureParams({required this.placeId, required this.request});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is AddFullDayClosureParams &&
        other.placeId == placeId &&
        other.request == request;
  }

  @override
  int get hashCode => placeId.hashCode ^ request.hashCode;
}

final addFullDayClosureProvider = FutureProvider.autoDispose
    .family<PlaceClosureResponse, AddFullDayClosureParams>((ref, params) async {
      final repository = ref.read(placeTimeRepositoryProvider);
      return await repository.addFullDayClosure(params.placeId, params.request);
      // Note: 목록 새로고침은 호출하는 쪽에서 날짜 범위에 따라 처리
    });

/// 부분 시간 휴무 추가 Provider (Mutation)
class AddPartialClosureParams {
  final int placeId;
  final AddPartialClosureRequest request;

  const AddPartialClosureParams({required this.placeId, required this.request});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is AddPartialClosureParams &&
        other.placeId == placeId &&
        other.request == request;
  }

  @override
  int get hashCode => placeId.hashCode ^ request.hashCode;
}

final addPartialClosureProvider = FutureProvider.autoDispose
    .family<PlaceClosureResponse, AddPartialClosureParams>((ref, params) async {
      final repository = ref.read(placeTimeRepositoryProvider);
      return await repository.addPartialClosure(params.placeId, params.request);
      // Note: 목록 새로고침은 호출하는 쪽에서 날짜 범위에 따라 처리
    });

/// 임시 휴무 삭제 Provider (Mutation)
class DeleteClosureParams {
  final int placeId;
  final int closureId;

  const DeleteClosureParams({required this.placeId, required this.closureId});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is DeleteClosureParams &&
        other.placeId == placeId &&
        other.closureId == closureId;
  }

  @override
  int get hashCode => placeId.hashCode ^ closureId.hashCode;
}

final deleteClosureProvider = FutureProvider.autoDispose
    .family<void, DeleteClosureParams>((ref, params) async {
      final repository = ref.read(placeTimeRepositoryProvider);
      await repository.deleteClosure(params.placeId, params.closureId);
      // Note: 목록 새로고침은 호출하는 쪽에서 날짜 범위에 따라 처리
    });

// ========================================
// 예약 가능 시간 Provider
// ========================================

class GetAvailableTimesParams {
  final int placeId;
  final String date; // YYYY-MM-DD

  const GetAvailableTimesParams({required this.placeId, required this.date});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is GetAvailableTimesParams &&
        other.placeId == placeId &&
        other.date == date;
  }

  @override
  int get hashCode => placeId.hashCode ^ date.hashCode;
}

final availableTimesProvider = FutureProvider.autoDispose
    .family<AvailableTimesResponse, GetAvailableTimesParams>((
      ref,
      params,
    ) async {
      final repository = ref.read(placeTimeRepositoryProvider);
      return await repository.getAvailableTimes(params.placeId, params.date);
    });
