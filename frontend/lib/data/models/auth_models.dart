import 'dart:convert';

class UserModel {
  final int id;
  final String name;
  final String email;
  final String role; // STUDENT|PROFESSOR|ADMIN
  final String? professorStatus; // PENDING|APPROVED|REJECTED (optional)
  final String? department; // 사용자의 소속 학과/계열 명칭

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.professorStatus,
    this.department,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: (json['id'] ?? 0) as int,
        name: (json['name'] ?? '').toString(),
        email: (json['email'] ?? '').toString(),
        role: (json['role'] ?? 'STUDENT').toString(),
        professorStatus: json['professorStatus']?.toString(),
        department: (json['department'] ?? json['dept'])?.toString(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role,
        if (professorStatus != null) 'professorStatus': professorStatus,
        if (department != null) 'department': department,
      };

  String toJsonString() => jsonEncode(toJson());
}

class LoginResponse {
  final String accessToken;
  final bool firstLogin;
  final UserModel user;

  LoginResponse({
    required this.accessToken,
    required this.firstLogin,
    required this.user,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) => LoginResponse(
        accessToken: (json['accessToken'] ?? '').toString(),
        firstLogin: json['firstLogin'] == true,
        user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
      );
}

class OnboardingRequest {
  final String name;
  final String nickname;
  final String? college;
  final String? dept;
  final String? studentNo;
  final String schoolEmail;
  final String role; // STUDENT|PROFESSOR

  OnboardingRequest({
    required this.name,
    required this.nickname,
    this.college,
    this.dept,
    this.studentNo,
    required this.schoolEmail,
    required this.role,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'nickname': nickname,
        if (college != null) 'college': college,
        if (dept != null) 'dept': dept,
        if (studentNo != null) 'studentNo': studentNo,
        'schoolEmail': schoolEmail,
        'role': role,
      };
}

class NicknameCheckResult {
  final bool available;
  final List<String> suggestions;

  NicknameCheckResult({required this.available, required this.suggestions});

  factory NicknameCheckResult.fromJson(Map<String, dynamic> json) =>
      NicknameCheckResult(
        available: json['available'] == true,
        suggestions: ((json['suggestions'] as List?) ?? [])
            .map((e) => e.toString())
            .toList(),
      );
}
