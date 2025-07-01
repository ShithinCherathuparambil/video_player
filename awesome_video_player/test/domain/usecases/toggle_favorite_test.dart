import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:lumeo/domain/repositories/video_repository.dart';
import 'package:lumeo/domain/usecases/toggle_favorite.dart';
import '../../helpers/mock_factories.dart';
import '../../helpers/test_constants.dart';

void main() {
  group('ToggleFavorite Use Case Tests', () {
    late ToggleFavorite usecase;
    late MockVideoRepository mockVideoRepository;

    setUp(() {
      mockVideoRepository = MockFactories.createMockVideoRepository();
      usecase = ToggleFavorite(mockVideoRepository);
    });

    group('Successful Execution Tests', () {
      test('should toggle favorite status through repository', () async {
        // arrange
        when(mockVideoRepository.toggleFavorite(TestConstants.testVideoPath))
            .thenAnswer((_) async {});

        // act
        await usecase.call(TestConstants.testVideoPath);

        // assert
        verify(mockVideoRepository.toggleFavorite(TestConstants.testVideoPath))
            .called(1);
        verifyNoMoreInteractions(mockVideoRepository);
      });

      test('should handle different video paths', () async {
        // arrange
        const videoPaths = [
          '/path/to/video1.mp4',
          '/another/path/video2.avi',
          '/different/location/video3.mkv',
        ];
        for (final path in videoPaths) {
          when(mockVideoRepository.toggleFavorite(path))
              .thenAnswer((_) async {});
        }

        // act
        for (final path in videoPaths) {
          await usecase.call(path);
        }

        // assert
        for (final path in videoPaths) {
          verify(mockVideoRepository.toggleFavorite(path)).called(1);
        }
      });

      test('should handle paths with special characters', () async {
        // arrange
        const specialPaths = [
          '/path with spaces/video.mp4',
          '/path-with-dashes/video.mp4',
          '/path_with_underscores/video.mp4',
          '/path.with.dots/video.mp4',
          '/path(with)parentheses/video.mp4',
        ];
        for (final path in specialPaths) {
          when(mockVideoRepository.toggleFavorite(path))
              .thenAnswer((_) async {});
        }

        // act
        for (final path in specialPaths) {
          await usecase.call(path);
        }

        // assert
        for (final path in specialPaths) {
          verify(mockVideoRepository.toggleFavorite(path)).called(1);
        }
      });
    });

    group('Error Handling Tests', () {
      test('should propagate repository exceptions', () async {
        // arrange
        final exception = Exception('Toggle failed');
        when(mockVideoRepository.toggleFavorite(TestConstants.testVideoPath))
            .thenThrow(exception);

        // act & assert
        expect(() => usecase.call(TestConstants.testVideoPath),
            throwsA(exception));
        verify(mockVideoRepository.toggleFavorite(TestConstants.testVideoPath))
            .called(1);
      });

      test('should propagate file not found exceptions', () async {
        // arrange
        final fileNotFoundException = Exception('File not found');
        when(mockVideoRepository.toggleFavorite(TestConstants.testVideoPath))
            .thenThrow(fileNotFoundException);

        // act & assert
        expect(() => usecase.call(TestConstants.testVideoPath),
            throwsA(fileNotFoundException));
        verify(mockVideoRepository.toggleFavorite(TestConstants.testVideoPath))
            .called(1);
      });

      test('should propagate storage exceptions', () async {
        // arrange
        final storageException = Exception('Storage error');
        when(mockVideoRepository.toggleFavorite(TestConstants.testVideoPath))
            .thenThrow(storageException);

        // act & assert
        expect(() => usecase.call(TestConstants.testVideoPath),
            throwsA(storageException));
        verify(mockVideoRepository.toggleFavorite(TestConstants.testVideoPath))
            .called(1);
      });

      test('should propagate permission exceptions', () async {
        // arrange
        final permissionException = Exception('Permission denied');
        when(mockVideoRepository.toggleFavorite(TestConstants.testVideoPath))
            .thenThrow(permissionException);

        // act & assert
        expect(() => usecase.call(TestConstants.testVideoPath),
            throwsA(permissionException));
        verify(mockVideoRepository.toggleFavorite(TestConstants.testVideoPath))
            .called(1);
      });
    });

    group('Input Validation Tests', () {
      test('should handle empty path', () async {
        // arrange
        when(mockVideoRepository.toggleFavorite('')).thenAnswer((_) async {});

        // act
        await usecase.call('');

        // assert
        verify(mockVideoRepository.toggleFavorite('')).called(1);
      });

      test('should handle very long paths', () async {
        // arrange
        final longPath =
            '/very/long/path/' + 'subdirectory/' * 50 + 'video.mp4';
        when(mockVideoRepository.toggleFavorite(longPath))
            .thenAnswer((_) async {});

        // act
        await usecase.call(longPath);

        // assert
        verify(mockVideoRepository.toggleFavorite(longPath)).called(1);
      });

      test('should handle paths with unicode characters', () async {
        // arrange
        const unicodePaths = [
          '/path/with/émojis/🎬video.mp4',
          '/path/with/中文/video.mp4',
          '/path/with/العربية/video.mp4',
          '/path/with/русский/video.mp4',
        ];
        for (final path in unicodePaths) {
          when(mockVideoRepository.toggleFavorite(path))
              .thenAnswer((_) async {});
        }

        // act
        for (final path in unicodePaths) {
          await usecase.call(path);
        }

        // assert
        for (final path in unicodePaths) {
          verify(mockVideoRepository.toggleFavorite(path)).called(1);
        }
      });
    });

    group('Performance Tests', () {
      test('should handle multiple concurrent toggle operations', () async {
        // arrange
        final videoPaths = List.generate(10, (index) => '/video$index.mp4');
        for (final path in videoPaths) {
          when(mockVideoRepository.toggleFavorite(path))
              .thenAnswer((_) async {});
        }

        // act
        final futures = videoPaths.map((path) => usecase.call(path));
        await Future.wait(futures);

        // assert
        for (final path in videoPaths) {
          verify(mockVideoRepository.toggleFavorite(path)).called(1);
        }
      });

      test('should handle rapid successive toggles on same video', () async {
        // arrange
        when(mockVideoRepository.toggleFavorite(any)).thenAnswer((_) async {});

        // act - simulate rapid toggling
        for (int i = 0; i < 5; i++) {
          await usecase.call(TestConstants.testVideoPath);
        }

        // assert
        verify(mockVideoRepository.toggleFavorite(TestConstants.testVideoPath))
            .called(5);
      });
    });

    group('Business Logic Tests', () {
      test('should maintain path integrity during toggle', () async {
        // arrange
        when(mockVideoRepository.toggleFavorite(any)).thenAnswer((_) async {});

        // act
        await usecase.call(TestConstants.testVideoPath);

        // assert
        final captured = verify(mockVideoRepository.toggleFavorite(captureAny))
            .captured
            .single as String;
        expect(captured, TestConstants.testVideoPath);
      });

      test('should handle case-sensitive paths correctly', () async {
        // arrange
        const lowerCasePath = '/path/to/video.mp4';
        const upperCasePath = '/PATH/TO/VIDEO.MP4';
        const mixedCasePath = '/Path/To/Video.mp4';

        when(mockVideoRepository.toggleFavorite(any<String>()))
            .thenAnswer((_) async {});

        // act
        await usecase.call(lowerCasePath);
        await usecase.call(upperCasePath);
        await usecase.call(mixedCasePath);

        // assert
        verify(mockVideoRepository.toggleFavorite(lowerCasePath)).called(1);
        verify(mockVideoRepository.toggleFavorite(upperCasePath)).called(1);
        verify(mockVideoRepository.toggleFavorite(mixedCasePath)).called(1);
      });

      test('should handle different file extensions', () async {
        // arrange
        const videoExtensions = [
          '/video.mp4',
          '/video.avi',
          '/video.mkv',
          '/video.mov',
          '/video.wmv',
          '/video.flv',
          '/video.webm',
        ];
        when(mockVideoRepository.toggleFavorite(any<String>()))
            .thenAnswer((_) async {});

        // act
        for (final path in videoExtensions) {
          await usecase.call(path);
        }

        // assert
        for (final path in videoExtensions) {
          verify(mockVideoRepository.toggleFavorite(path)).called(1);
        }
      });
    });

    group('Integration Tests', () {
      test('should work with repository implementation', () async {
        // arrange
        when(mockVideoRepository.toggleFavorite(any<String>()))
            .thenAnswer((_) async {});

        // act
        await usecase.call(TestConstants.testVideoPath);

        // assert
        verify(mockVideoRepository.toggleFavorite(TestConstants.testVideoPath))
            .called(1);
        verifyNoMoreInteractions(mockVideoRepository);
      });
    });
  });
}
