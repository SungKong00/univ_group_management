import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';

part 'user_model.g.dart';

@JsonSerializable()
class UserModel extends Equatable {
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
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserModel({
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
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  Map<String, dynamic> toJson() => _$UserModelToJson(this);

  UserModel copyWith({
    int? id,
    String? name,
    String? email,
    String? globalRole,
    bool? isActive,
    String? nickname,
    String? profileImageUrl,
    String? bio,
    bool? profileCompleted,
    bool? emailVerified,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      globalRole: globalRole ?? this.globalRole,
      isActive: isActive ?? this.isActive,
      nickname: nickname ?? this.nickname,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      bio: bio ?? this.bio,
      profileCompleted: profileCompleted ?? this.profileCompleted,
      emailVerified: emailVerified ?? this.emailVerified,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        email,
        globalRole,
        isActive,
        nickname,
        profileImageUrl,
        bio,
        profileCompleted,
        emailVerified,
        createdAt,
        updatedAt,
      ];
}

@JsonSerializable()
class LoginRequest extends Equatable {
  final String email;
  final String password;

  const LoginRequest({
    required this.email,
    required this.password,
  });

  factory LoginRequest.fromJson(Map<String, dynamic> json) =>
      _$LoginRequestFromJson(json);

  Map<String, dynamic> toJson() => _$LoginRequestToJson(this);

  @override
  List<Object?> get props => [email, password];
}

@JsonSerializable()
class RegisterRequest extends Equatable {
  final String name;
  final String email;
  final String password;

  const RegisterRequest({
    required this.name,
    required this.email,
    required this.password,
  });

  factory RegisterRequest.fromJson(Map<String, dynamic> json) =>
      _$RegisterRequestFromJson(json);

  Map<String, dynamic> toJson() => _$RegisterRequestToJson(this);

  @override
  List<Object?> get props => [name, email, password];
}

@JsonSerializable()
class LoginResponse extends Equatable {
  final String accessToken;
  final String tokenType;
  final int expiresIn;  // Backend sends Long, but we convert to int
  final UserModel user;

  const LoginResponse({
    required this.accessToken,
    required this.tokenType,
    required this.expiresIn,
    required this.user,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) =>
      _$LoginResponseFromJson(json);

  Map<String, dynamic> toJson() => _$LoginResponseToJson(this);

  @override
  List<Object?> get props => [
        accessToken,
        tokenType,
        expiresIn,
        user,
      ];
}

@JsonSerializable()
class ProfileUpdateRequest extends Equatable {
  final String globalRole;
  final String nickname;
  final String? profileImageUrl;
  final String? bio;

  const ProfileUpdateRequest({
    required this.globalRole,
    required this.nickname,
    this.profileImageUrl,
    this.bio,
  });

  factory ProfileUpdateRequest.fromJson(Map<String, dynamic> json) =>
      _$ProfileUpdateRequestFromJson(json);

  Map<String, dynamic> toJson() => _$ProfileUpdateRequestToJson(this);

  @override
  List<Object?> get props => [globalRole, nickname, profileImageUrl, bio];
}
