enum GroupNodeType {
  university,
  college,
  department,
  other,
}

class GroupHierarchyNode {
  GroupHierarchyNode({
    required this.id,
    required this.name,
    required this.type,
    this.parentId,
  });

  factory GroupHierarchyNode.fromJson(Map<String, dynamic> json) {
    final String typeString = (json['type'] as String? ?? '').toUpperCase();

    return GroupHierarchyNode(
      id: (json['id'] as num).toInt(),
      parentId: (json['parentId'] as num?)?.toInt(),
      name: json['name'] as String? ?? '',
      type: _parseType(typeString),
    );
  }

  final int id;
  final int? parentId;
  final String name;
  final GroupNodeType type;

  static GroupNodeType _parseType(String value) {
    switch (value) {
      case 'UNIVERSITY':
        return GroupNodeType.university;
      case 'COLLEGE':
        return GroupNodeType.college;
      case 'DEPARTMENT':
        return GroupNodeType.department;
      default:
        return GroupNodeType.other;
    }
  }
}
