class ApiResponse<T> {
  final bool success;
  final T? data;
  final ApiError? error;

  ApiResponse({required this.success, this.data, this.error});

  bool get isSuccess => success && error == null;

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) {
    return ApiResponse<T>(
      success: json['success'] == true,
      data: json['data'] != null ? fromJsonT(json['data']) : null,
      error: json['error'] != null
          ? ApiError.fromJson(json['error'] as Map<String, dynamic>)
          : null,
    );
  }
}

class ApiError {
  final String code;
  final String message;
  final String? details;

  ApiError({required this.code, required this.message, this.details});

  factory ApiError.fromJson(Map<String, dynamic> json) => ApiError(
        code: (json['code'] ?? 'UNKNOWN_ERROR').toString(),
        message: (json['message'] ?? '에러가 발생했습니다.').toString(),
        details: json['details']?.toString(),
      );
}

