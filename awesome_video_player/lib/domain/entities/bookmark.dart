import 'package:equatable/equatable.dart';

class Bookmark extends Equatable {
  final String id;
  final String videoPath;
  final Duration timestamp;
  final String label;
  final DateTime createdAt;

  const Bookmark({
    required this.id,
    required this.videoPath,
    required this.timestamp,
    required this.label,
    required this.createdAt,
  });

  Bookmark copyWith({
    String? id,
    String? videoPath,
    Duration? timestamp,
    String? label,
    DateTime? createdAt,
  }) {
    return Bookmark(
      id: id ?? this.id,
      videoPath: videoPath ?? this.videoPath,
      timestamp: timestamp ?? this.timestamp,
      label: label ?? this.label,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'videoPath': videoPath,
      'timestamp': timestamp.inMilliseconds,
      'label': label,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Bookmark.fromJson(Map<String, dynamic> json) {
    return Bookmark(
      id: json['id'],
      videoPath: json['videoPath'],
      timestamp: Duration(milliseconds: json['timestamp']),
      label: json['label'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  @override
  List<Object?> get props => [id, videoPath, timestamp, label, createdAt];
}
