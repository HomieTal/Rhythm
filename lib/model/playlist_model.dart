class PlaylistModel {
  final String name;
  final DateTime createdAt;
  final List<String> songIds;

  PlaylistModel({
    required this.name,
    required this.createdAt,
    required this.songIds,
  });

  factory PlaylistModel.fromJson(Map<String, dynamic> json) {
    return PlaylistModel(
      name: json['name'] ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      songIds: List<String>.from(json['songIds'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'createdAt': createdAt.toIso8601String(),
      'songIds': songIds,
    };
  }
}
