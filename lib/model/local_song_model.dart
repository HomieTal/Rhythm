class LocalSongModel {
  final int id;
  final String title;
  final String artist;
  final String uri;
  final String albumArt;
  final int duration;

  LocalSongModel({
    required this.id,
    required this.title,
    required this.artist,
    required this.uri,
    required this.albumArt,
    required this.duration,
  });

  // Convert LocalSongModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'uri': uri,
      'albumArt': albumArt,
      'duration': duration,
    };
  }

  // Create LocalSongModel from JSON
  factory LocalSongModel.fromJson(Map<String, dynamic> json) {
    int parsedId;
    if (json['id'] is int) {
      parsedId = json['id'] as int;
    } else if (json['id'] is String) {
      parsedId = int.tryParse(json['id']) ?? 0;
    } else {
      parsedId = 0;
    }
    return LocalSongModel(
      id: parsedId,
      title: json['title'] ?? 'Unknown',
      artist: json['artist'] ?? 'Unknown Artist',
      uri: json['uri'] ?? '',
      albumArt: json['albumArt'] ?? '',
      duration: json['duration'] ?? 0,
    );
  }
}

