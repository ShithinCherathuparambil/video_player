// Basic entity representing a video file
// This might be expanded with more metadata later (e.g., duration, thumbnail path, resolution)
class VideoFile {
  final String path;
  final String name; // Extracted from path or provided separately
  // final Duration? duration; // Example of future extension
  // final String? thumbnailPath; // Example of future extension

  VideoFile({
    required this.path,
    required this.name,
    // this.duration,
    // this.thumbnailPath,
  });

  // Optional: Implement Equatable for easier comparison if needed in lists or sets
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VideoFile &&
          runtimeType == other.runtimeType &&
          path == other.path &&
          name == other.name;

  @override
  int get hashCode => path.hashCode ^ name.hashCode;
}
