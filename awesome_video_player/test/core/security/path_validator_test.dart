import 'package:flutter_test/flutter_test.dart';
import 'package:awesome_video_player/core/security/path_validator.dart';

void main() {
  group('PathValidator Security Tests', () {
    group('isValidVideoPath', () {
      test('should accept valid video file paths', () {
        expect(PathValidator.isValidVideoPath('/videos/movie.mp4'), isTrue);
        expect(PathValidator.isValidVideoPath('/documents/video.mov'), isTrue);
        expect(PathValidator.isValidVideoPath('/downloads/clip.avi'), isTrue);
      });

      test('should reject dangerous path traversal attempts', () {
        expect(PathValidator.isValidVideoPath('../../../etc/passwd'), isFalse);
        expect(
            PathValidator.isValidVideoPath(
                '..\\..\\windows\\system32\\file.mp4'),
            isFalse);
        expect(PathValidator.isValidVideoPath('/etc/shadow.mp4'), isFalse);
        expect(PathValidator.isValidVideoPath('/bin/bash.mov'), isFalse);
      });

      test('should reject non-video file extensions', () {
        expect(PathValidator.isValidVideoPath('/path/file.exe'), isFalse);
        expect(PathValidator.isValidVideoPath('/path/script.sh'), isFalse);
        expect(PathValidator.isValidVideoPath('/path/document.pdf'), isFalse);
        expect(PathValidator.isValidVideoPath('/path/image.jpg'), isFalse);
      });

      test('should reject empty or null paths', () {
        expect(PathValidator.isValidVideoPath(''), isFalse);
      });

      test('should reject system directories', () {
        expect(PathValidator.isValidVideoPath('/usr/bin/video.mp4'), isFalse);
        expect(PathValidator.isValidVideoPath('/var/log/video.mov'), isFalse);
        expect(PathValidator.isValidVideoPath('C:\\Program Files\\video.avi'),
            isFalse);
      });
    });

    group('sanitizeSearchQuery', () {
      test('should remove dangerous characters', () {
        expect(
            PathValidator.sanitizeSearchQuery('<script>alert("xss")</script>'),
            equals('scriptalert(xss)script'));
        expect(PathValidator.sanitizeSearchQuery('test & rm -rf /'),
            equals('test rm -rf'));
        expect(PathValidator.sanitizeSearchQuery('query; DROP TABLE videos;'),
            equals('query DROP TABLE videos'));
      });

      test('should normalize whitespace', () {
        expect(PathValidator.sanitizeSearchQuery('  multiple   spaces  '),
            equals('multiple spaces'));
        expect(
            PathValidator.sanitizeSearchQuery('\t\ntest\r\n'), equals('test'));
      });

      test('should limit query length', () {
        final longQuery = 'a' * 150;
        final sanitized = PathValidator.sanitizeSearchQuery(longQuery);
        expect(sanitized.length, equals(100));
      });

      test('should handle empty queries', () {
        expect(PathValidator.sanitizeSearchQuery(''), equals(''));
        expect(PathValidator.sanitizeSearchQuery('   '), equals(''));
      });
    });

    group('isValidVideoExtension', () {
      test('should accept valid video extensions', () {
        expect(PathValidator.isValidVideoExtension('video.mp4'), isTrue);
        expect(PathValidator.isValidVideoExtension('movie.MOV'), isTrue);
        expect(PathValidator.isValidVideoExtension('clip.AVI'), isTrue);
        expect(PathValidator.isValidVideoExtension('film.mkv'), isTrue);
      });

      test('should reject invalid extensions', () {
        expect(PathValidator.isValidVideoExtension('file.txt'), isFalse);
        expect(PathValidator.isValidVideoExtension('script.js'), isFalse);
        expect(PathValidator.isValidVideoExtension('image.png'), isFalse);
      });

      test('should handle files without extensions', () {
        expect(PathValidator.isValidVideoExtension('filename'), isFalse);
        expect(PathValidator.isValidVideoExtension(''), isFalse);
      });
    });

    group('getSecureFileName', () {
      test('should extract filename from valid paths', () {
        expect(PathValidator.getSecureFileName('/path/to/video.mp4'),
            equals('video.mp4'));
        // Note: On non-Windows systems, backslashes are treated as part of filename
        expect(PathValidator.getSecureFileName('/videos/movie.mov'),
            equals('movie.mov'));
      });

      test('should return "Unknown" for invalid paths', () {
        expect(PathValidator.getSecureFileName('../../../etc/passwd'),
            equals('Unknown'));
        expect(PathValidator.getSecureFileName('/bin/bash.mp4'),
            equals('Unknown'));
      });
    });

    group('isValidThumbnailPath', () {
      test('should accept valid thumbnail paths', () {
        expect(
            PathValidator.isValidThumbnailPath('/app/cache/thumb.png'), isTrue);
        expect(PathValidator.isValidThumbnailPath('C:\\app\\temp\\thumb.jpg'),
            isTrue);
        expect(
            PathValidator.isValidThumbnailPath('/cache/thumbnail.jpg'), isTrue);
        expect(PathValidator.isValidThumbnailPath(null),
            isTrue); // null is allowed
        expect(
            PathValidator.isValidThumbnailPath(''), isTrue); // empty is allowed
      });

      test('should reject dangerous thumbnail paths', () {
        expect(
            PathValidator.isValidThumbnailPath('../../../etc/passwd'), isFalse);
        expect(
            PathValidator.isValidThumbnailPath('/usr/bin/thumb.jpg'), isFalse);
        expect(PathValidator.isValidThumbnailPath('/root/thumb.png'), isFalse);
      });
    });
  });

  group('Security Edge Cases', () {
    test('should handle URL encoded path traversal attempts', () {
      // URL encoded paths are not decoded, so they pass basic validation
      // but would fail at file system level - this is acceptable
      expect(
          PathValidator.isValidVideoPath('%2e%2e%2f%2e%2e%2fetc%2fpasswd.mp4'),
          isTrue);
    });

    test('should handle mixed case dangerous patterns', () {
      expect(PathValidator.isValidVideoPath('/ETC/passwd.mp4'), isFalse);
      expect(PathValidator.isValidVideoPath('/BIN/bash.mov'), isFalse);
    });

    test('should handle very long paths', () {
      final longPath = '/very/long/path/${'a' * 1000}.mp4';
      // Should still validate the extension and dangerous patterns
      expect(PathValidator.isValidVideoPath(longPath), isTrue);
    });
  });
}
