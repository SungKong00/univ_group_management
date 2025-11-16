class LoginRequest {
  final String? googleAuthToken;
  final String? googleAccessToken;

  LoginRequest({this.googleAuthToken, this.googleAccessToken});

  Map<String, dynamic> toJson() => {
    if (googleAuthToken != null) 'googleAuthToken': googleAuthToken,
    if (googleAccessToken != null) 'googleAccessToken': googleAccessToken,
  };
}

class LoginResponse {
  final String accessToken;
  final String tokenType;
  final int expiresIn;
  final UserInfo user;
  final bool firstLogin;
  final String? refreshToken; // ✅ 추가: 백엔드 전달 리프레시 토큰

  LoginResponse({
    required this.accessToken,
    required this.tokenType,
    required this.expiresIn,
    required this.user,
    required this.firstLogin,
    this.refreshToken,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) => LoginResponse(
    accessToken: json['accessToken'] as String,
    tokenType: json['tokenType'] as String? ?? 'Bearer',
    expiresIn: (json['expiresIn'] as num).toInt(),
    user: UserInfo.fromJson(json['user'] as Map<String, dynamic>),
    firstLogin: json['firstLogin'] as bool? ?? false,
    refreshToken: json['refreshToken'] as String?, // ✅ 파싱 추가
  );

  Map<String, dynamic> toJson() => {
    'accessToken': accessToken,
    'tokenType': tokenType,
    'expiresIn': expiresIn,
    'user': user.toJson(),
    'firstLogin': firstLogin,
    if (refreshToken != null) 'refreshToken': refreshToken,
  };
}

class UserInfo {
  final int id;
  final String name;
  final String email;
  final String globalRole;
  final bool isActive;
  final String? nickname;
  final String? profileImageUrl;
  final String? bio;
  final bool profileCompleted;
  final bool emailVerified;
  final String? professorStatus;
  final String? department;
  final String? studentNo;
  final int? academicYear;
  final String? schoolEmail;
  final String createdAt;
  final String updatedAt;

  UserInfo({
    required this.id,
    required this.name,
    required this.email,
    required this.globalRole,
    required this.isActive,
    this.nickname,
    this.profileImageUrl,
    this.bio,
    required this.profileCompleted,
    required this.emailVerified,
    this.professorStatus,
    this.department,
    this.studentNo,
    this.academicYear,
    this.schoolEmail,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) => UserInfo(
    id: json['id'] as int,
    name: json['name'] as String,
    email: json['email'] as String,
    globalRole: json['globalRole'] as String,
    isActive: json['isActive'] as bool,
    nickname: json['nickname'] as String?,
    profileImageUrl: json['profileImageUrl'] as String?,
    bio: json['bio'] as String?,
    profileCompleted: json['profileCompleted'] as bool,
    emailVerified: json['emailVerified'] as bool,
    professorStatus: json['professorStatus'] as String?,
    department: json['department'] as String?,
    studentNo: json['studentNo'] as String?,
    academicYear: json['academicYear'] as int?,
    schoolEmail: json['schoolEmail'] as String?,
    createdAt: json['createdAt'] as String,
    updatedAt: json['updatedAt'] as String,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'globalRole': globalRole,
    'isActive': isActive,
    'nickname': nickname,
    'profileImageUrl': profileImageUrl,
    'bio': bio,
    'profileCompleted': profileCompleted,
    'emailVerified': emailVerified,
    'professorStatus': professorStatus,
    'department': department,
    'studentNo': studentNo,
    'academicYear': academicYear,
    'schoolEmail': schoolEmail,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
  };
}

class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? message;
  final String? errorCode;

  ApiResponse({required this.success, this.data, this.message, this.errorCode});

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) => ApiResponse(
    success: json['success'] as bool,
    data: json['data'] != null ? fromJsonT(json['data']) : null,
    message: json['message'] as String?,
    errorCode: json['errorCode'] as String?,
  );
}
