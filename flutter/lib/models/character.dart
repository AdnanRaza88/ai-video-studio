class Character {
  final String id;
  final String name;
  final String imagePath;
  final String description;

  Character({
    required this.id,
    required this.name,
    required this.imagePath,
    this.description = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'imagePath': imagePath,
        'description': description,
      };

  factory Character.fromJson(Map<String, dynamic> j) {
    return Character(
      id: j['id'] as String? ?? '',
      name: j['name'] as String? ?? 'Character',
      imagePath: j['imagePath'] as String? ?? '',
      description: j['description'] as String? ?? '',
    );
  }
}
