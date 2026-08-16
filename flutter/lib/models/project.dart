class Project {
  final String id;
  final String name;
  final String description;
  final String language;
  final String style;
  final DateTime createdAt;
  final DateTime updatedAt;

  Project({
    required this.id,
    required this.name,
    this.description = '',
    this.language = 'en',
    this.style = 'cute_2d_cartoon',
    required this.createdAt,
    required this.updatedAt,
  });

  Project copyWith({
    String? name,
    String? description,
    DateTime? updatedAt,
  }) {
    return Project(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      language: language,
      style: style,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'language': language,
      'style': style,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Project.fromMap(Map<String, dynamic> map) {
    return Project(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String? ?? '',
      language: map['language'] as String? ?? 'en',
      style: map['style'] as String? ?? 'cute_2d_cartoon',
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}
