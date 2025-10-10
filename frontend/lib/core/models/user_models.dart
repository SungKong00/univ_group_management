class NicknameCheckResult {
  NicknameCheckResult({required this.available, this.suggestions = const []});

  factory NicknameCheckResult.fromJson(Map<String, dynamic> json) {
    return NicknameCheckResult(
      available: json['available'] as bool? ?? false,
      suggestions:
          (json['suggestions'] as List<dynamic>?)
              ?.map((dynamic item) => item.toString())
              .toList() ??
          const [],
    );
  }

  final bool available;
  final List<String> suggestions;
}

enum SignupRole {
  student('STUDENT'),
  professor('PROFESSOR');

  const SignupRole(this.apiValue);

  final String apiValue;
}

class SignupProfileRequest {
  SignupProfileRequest({
    required this.name,
    required this.nickname,
    required this.role,
    required this.schoolEmail,
    this.college,
    this.department,
    required this.studentNo,
    required this.academicYear,
  });

  final String name;
  final String nickname;
  final SignupRole role;
  final String schoolEmail;
  final String? college;
  final String? department;
  final String studentNo;
  final int academicYear;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'name': name,
      'nickname': nickname,
      'role': role.apiValue,
      'schoolEmail': schoolEmail,
      'college': college,
      'dept': department,
      'studentNo': studentNo,
      'academicYear': academicYear,
    };
  }
}

class EmailSendRequest {
  EmailSendRequest({required this.email});

  final String email;

  Map<String, dynamic> toJson() => <String, dynamic>{'email': email};
}

class EmailVerifyRequest {
  EmailVerifyRequest({required this.email, required this.code});

  final String email;
  final String code;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'email': email,
    'code': code,
  };
}

class UserSummaryResponse {
  UserSummaryResponse({
    required this.id,
    required this.name,
    required this.email,
    this.profileImageUrl,
    this.studentNo,
    this.academicYear,
  });

  factory UserSummaryResponse.fromJson(Map<String, dynamic> json) {
    return UserSummaryResponse(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      email: json['email'] as String,
      profileImageUrl: json['profileImageUrl'] as String?,
      studentNo: json['studentNo'] as String?,
      academicYear: (json['academicYear'] as num?)?.toInt(),
    );
  }

  final int id;
  final String name;
  final String email;
  final String? profileImageUrl;
  final String? studentNo;
  final int? academicYear;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'email': email,
      'profileImageUrl': profileImageUrl,
      'studentNo': studentNo,
      'academicYear': academicYear,
    };
  }
}
