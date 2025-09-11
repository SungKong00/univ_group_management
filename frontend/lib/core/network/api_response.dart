import 'package:json_annotation/json_annotation.dart';

part 'api_response.g.dart';

@JsonSerializable(genericArgumentFactories: true)
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? message;
  final ErrorResponse? error;
  final String? timestamp;
  final String? path;

  const ApiResponse({
    required this.success,
    this.data,
    this.message,
    this.error,
    this.timestamp,
    this.path,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) =>
      _$ApiResponseFromJson(json, fromJsonT);

  Map<String, dynamic> toJson(Object Function(T value) toJsonT) =>
      _$ApiResponseToJson(this, toJsonT);

  // 성공 응답 생성자
  factory ApiResponse.success({
    required T data,
    String? message,
    String? timestamp,
  }) {
    return ApiResponse<T>(
      success: true,
      data: data,
      message: message,
      timestamp: timestamp,
    );
  }

  // 에러 응답 생성자
  factory ApiResponse.failure({
    required ErrorResponse error,
    String? timestamp,
    String? path,
  }) {
    return ApiResponse<T>(
      success: false,
      error: error,
      timestamp: timestamp,
      path: path,
    );
  }

  bool get isSuccess => success && error == null;
  bool get isFailure => !success || error != null;
}

@JsonSerializable()
class ErrorResponse {
  final String code;
  final String message;
  final String? details;

  const ErrorResponse({
    required this.code,
    required this.message,
    this.details,
  });

  factory ErrorResponse.fromJson(Map<String, dynamic> json) =>
      _$ErrorResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ErrorResponseToJson(this);
}