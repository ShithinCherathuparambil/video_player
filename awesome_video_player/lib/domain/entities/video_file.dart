import 'package:flutter/material.dart';
import 'dart:typed_data';

enum VideoStatus {
  new_,
  watched,
  watching,
  lastWatched,
}

// Basic entity representing a video file
// This might be expanded with more metadata later (e.g., duration, thumbnail path, resolution)
class VideoFile {
  final String path;
  final String name; // Extracted from path or provided separately
  final String? thumbnailPath;
  final Uint8List? thumbnailBytes;
  final Duration? duration;
  final int? fileSize;
  final DateTime? dateAdded;
  final Duration? lastPlayedPosition;
  final DateTime? lastPlayedAt;
  final VideoStatus status;
  final bool isFavorite;

  VideoFile({
    required this.path,
    required this.name,
    this.thumbnailPath,
    this.thumbnailBytes,
    this.duration,
    this.fileSize,
    this.dateAdded,
    this.lastPlayedPosition,
    this.lastPlayedAt,
    this.status = VideoStatus.new_,
    this.isFavorite = false,
  });

  // Optional: Implement Equatable for easier comparison if needed in lists or sets
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VideoFile &&
          runtimeType == other.runtimeType &&
          path == other.path &&
          name == other.name &&
          status == other.status &&
          isFavorite == other.isFavorite &&
          lastPlayedPosition == other.lastPlayedPosition &&
          lastPlayedAt == other.lastPlayedAt;

  @override
  int get hashCode =>
      path.hashCode ^
      name.hashCode ^
      status.hashCode ^
      isFavorite.hashCode ^
      (lastPlayedPosition?.hashCode ?? 0) ^
      (lastPlayedAt?.hashCode ?? 0);

  VideoFile copyWith({
    String? path,
    String? name,
    String? thumbnailPath,
    Uint8List? thumbnailBytes,
    Duration? duration,
    int? fileSize,
    DateTime? dateAdded,
    Duration? lastPlayedPosition,
    DateTime? lastPlayedAt,
    VideoStatus? status,
    bool? isFavorite,
  }) {
    return VideoFile(
      path: path ?? this.path,
      name: name ?? this.name,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      thumbnailBytes: thumbnailBytes ?? this.thumbnailBytes,
      duration: duration ?? this.duration,
      fileSize: fileSize ?? this.fileSize,
      dateAdded: dateAdded ?? this.dateAdded,
      lastPlayedPosition: lastPlayedPosition ?? this.lastPlayedPosition,
      lastPlayedAt: lastPlayedAt ?? this.lastPlayedAt,
      status: status ?? this.status,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  // Serialization methods for local storage
  Map<String, dynamic> toJson() {
    return {
      'path': path,
      'name': name,
      'thumbnailPath': thumbnailPath,
      'duration': duration?.inMilliseconds,
      'fileSize': fileSize,
      'dateAdded': dateAdded?.millisecondsSinceEpoch,
      'lastPlayedPosition': lastPlayedPosition?.inMilliseconds,
      'lastPlayedAt': lastPlayedAt?.millisecondsSinceEpoch,
      'status': status.index,
      'isFavorite': isFavorite,
    };
  }

  factory VideoFile.fromJson(Map<String, dynamic> json) {
    return VideoFile(
      path: json['path'] as String,
      name: json['name'] as String,
      thumbnailPath: json['thumbnailPath'] as String?,
      duration: json['duration'] != null
          ? Duration(milliseconds: json['duration'] as int)
          : null,
      fileSize: json['fileSize'] as int?,
      dateAdded: json['dateAdded'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['dateAdded'] as int)
          : null,
      lastPlayedPosition: json['lastPlayedPosition'] != null
          ? Duration(milliseconds: json['lastPlayedPosition'] as int)
          : null,
      lastPlayedAt: json['lastPlayedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['lastPlayedAt'] as int)
          : null,
      status: VideoStatus.values[json['status'] as int? ?? 0],
      isFavorite: json['isFavorite'] as bool? ?? false,
    );
  }
}
