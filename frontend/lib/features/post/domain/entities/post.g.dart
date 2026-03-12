// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'post.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PostImpl _$$PostImplFromJson(Map<String, dynamic> json) => _$PostImpl(
  id: (json['id'] as num).toInt(),
  content: json['content'] as String,
  author: Author.fromJson(json['author'] as Map<String, dynamic>),
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
  commentCount: (json['commentCount'] as num?)?.toInt() ?? 0,
  lastCommentedAt: json['lastCommentedAt'] == null
      ? null
      : DateTime.parse(json['lastCommentedAt'] as String),
);

Map<String, dynamic> _$$PostImplToJson(_$PostImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'content': instance.content,
      'author': instance.author,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
      'commentCount': instance.commentCount,
      'lastCommentedAt': instance.lastCommentedAt?.toIso8601String(),
    };
