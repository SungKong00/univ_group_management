/// Pagination information from backend
class PaginationInfo {
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;
  final bool first;
  final bool last;
  final bool hasNext;
  final bool hasPrevious;

  const PaginationInfo({
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
    required this.first,
    required this.last,
    required this.hasNext,
    required this.hasPrevious,
  });

  factory PaginationInfo.fromJson(Map<String, dynamic> json) {
    return PaginationInfo(
      page: json['page'] as int,
      size: json['size'] as int,
      totalElements: json['totalElements'] as int,
      totalPages: json['totalPages'] as int,
      first: json['first'] as bool,
      last: json['last'] as bool,
      hasNext: json['hasNext'] as bool,
      hasPrevious: json['hasPrevious'] as bool,
    );
  }
}

/// Paged data wrapper from backend
class PagedData<T> {
  final List<T> content;
  final PaginationInfo pagination;

  const PagedData({required this.content, required this.pagination});

  factory PagedData.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    return PagedData(
      content: (json['content'] as List<dynamic>)
          .map((item) => fromJsonT(item as Map<String, dynamic>))
          .toList(),
      pagination: PaginationInfo.fromJson(
        json['pagination'] as Map<String, dynamic>,
      ),
    );
  }
}

/// Paged API response from backend
class PagedApiResponse<T> {
  final bool success;
  final PagedData<T> data;
  final String? error;
  final String timestamp;

  const PagedApiResponse({
    required this.success,
    required this.data,
    this.error,
    required this.timestamp,
  });

  factory PagedApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    return PagedApiResponse(
      success: json['success'] as bool,
      data: PagedData.fromJson(json['data'] as Map<String, dynamic>, fromJsonT),
      error: json['error'] as String?,
      timestamp: json['timestamp'] as String,
    );
  }
}
