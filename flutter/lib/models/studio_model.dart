class StudioModel {
  final String id;
  final String name;
  final String description;
  final String kind;
  final String sizeLabel;
  final String license;
  final String? downloadUrl;
  final bool recommended;

  StudioModel({
    required this.id,
    required this.name,
    required this.description,
    required this.kind,
    required this.sizeLabel,
    required this.license,
    this.downloadUrl,
    this.recommended = false,
  });

  factory StudioModel.fromJson(Map<String, dynamic> j) {
    return StudioModel(
      id: j['id'] as String,
      name: j['name'] as String? ?? j['id'] as String,
      description: j['description'] as String? ?? '',
      kind: j['kind'] as String? ?? 'text_to_video',
      sizeLabel: j['size_label'] as String? ?? '',
      license: j['license'] as String? ?? '',
      downloadUrl: j['download_url'] as String?,
      recommended: j['recommended'] as bool? ?? false,
    );
  }
}
