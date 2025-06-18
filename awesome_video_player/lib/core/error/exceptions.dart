class CacheException implements Exception {
  final String message;
  CacheException([this.message = 'Cache error occurred']);
}

class PermissionException implements Exception {
  final String message;
  PermissionException([this.message = 'Permission denied']);
}

class FileSystemException implements Exception {
  final String message;
  FileSystemException([this.message = 'File system error occurred']);
}
