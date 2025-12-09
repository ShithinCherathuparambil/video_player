import 'package:flutter_test/flutter_test.dart';
import 'package:lumeo/data/repositories/bookmarks_repository.dart';
import 'package:lumeo/domain/entities/bookmark.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late BookmarksRepository repository;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  test('should add and retrieve bookmarks', () async {
    final prefs = await SharedPreferences.getInstance();
    repository = BookmarksRepository(prefs);

    final bookmark = Bookmark(
      id: '1',
      videoPath: '/path/to/video.mp4',
      timestamp: const Duration(seconds: 10),
      label: 'Intro',
      createdAt: DateTime.now(),
    );

    await repository.addBookmark(bookmark);

    final bookmarks = repository.getBookmarks('/path/to/video.mp4');
    expect(bookmarks.length, 1);
    expect(bookmarks.first.id, '1');
    expect(bookmarks.first.label, 'Intro');
  });

  test('should retrieve only bookmarks for specific video', () async {
    final prefs = await SharedPreferences.getInstance();
    repository = BookmarksRepository(prefs);

    final b1 = Bookmark(
      id: '1',
      videoPath: '/path/to/video.mp4',
      timestamp: const Duration(seconds: 10),
      label: 'Intro',
      createdAt: DateTime.now(),
    );

    final b2 = Bookmark(
      id: '2',
      videoPath: '/other/video.mp4',
      timestamp: const Duration(seconds: 20),
      label: 'Other',
      createdAt: DateTime.now(),
    );

    await repository.addBookmark(b1);
    await repository.addBookmark(b2);

    final bookmarks = repository.getBookmarks('/path/to/video.mp4');
    expect(bookmarks.length, 1);
    expect(bookmarks.first.id, '1');
  });

  test('should remove bookmark', () async {
    final prefs = await SharedPreferences.getInstance();
    repository = BookmarksRepository(prefs);

    final bookmark = Bookmark(
      id: '1',
      videoPath: '/path/to/video.mp4',
      timestamp: const Duration(seconds: 10),
      label: 'Intro',
      createdAt: DateTime.now(),
    );

    await repository.addBookmark(bookmark);
    await repository.removeBookmark('1');

    final bookmarks = repository.getBookmarks('/path/to/video.mp4');
    expect(bookmarks.isEmpty, true);
  });
}
