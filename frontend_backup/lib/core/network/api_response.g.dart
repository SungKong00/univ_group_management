// GENERATED-LIKE FILE (handwritten to unblock build)
// ignore_for_file: non_constant_identifier_names, unnecessary_cast

part of 'api_response.dart';

ApiResponse<T> _$ApiResponseFromJson<T>(
  Map<String, dynamic> json,
  T Function(Object? json) fromJsonT,
) {
  return ApiResponse<T>(
    success: json['success'] as bool,
    data: json['data'] == null ? null : fromJsonT(json['data']),
    message: json['message'] as String?,
    error: json['error'] == null
        ? null
        : ErrorResponse.fromJson(json['error'] as Map<String, dynamic>),
    timestamp: json['timestamp'] as String?,
    path: json['path'] as String?,
  );
}

Map<String, dynamic> _$ApiResponseToJson<T>(
  ApiResponse<T> instance,
  Object Function(T value) toJsonT,
) => <String, dynamic>{
      'success': instance.success,
      'data': instance.data == null ? null : toJsonT(instance.data as T),
      'message': instance.message,
      'error': instance.error?.toJson(),
      'timestamp': instance.timestamp,
      'path': instance.path,
    };

ErrorResponse _$ErrorResponseFromJson(Map<String, dynamic> json) =>
    ErrorResponse(
      code: json['code'] as String,
      message: json['message'] as String,
      details: json['details'] as String?,
    );

Map<String, dynamic> _$ErrorResponseToJson(ErrorResponse instance) =>
    <String, dynamic>{
      'code': instance.code,
      'message': instance.message,
      'details': instance.details,
    };

