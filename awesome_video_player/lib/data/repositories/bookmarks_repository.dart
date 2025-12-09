import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/bookmark.dart';

class BookmarksRepository {
  static const String _storageKey = 'lumeo_bookmarks';
  final SharedPreferences _prefs;

  BookmarksRepository(this._prefs);

  static Future<BookmarksRepository> create() async {
    final prefs = await SharedPreferences.getInstance();
    return BookmarksRepository(prefs);
  }

  List<Bookmark> getBookmarks(String videoPath) {
    final allBookmarks = _getAllBookmarks();
    return allBookmarks.where((b) => b.videoPath == videoPath).toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  Future<void> addBookmark(Bookmark bookmark) async {
    final allBookmarks = _getAllBookmarks();
    allBookmarks.add(bookmark);
    await _saveBookmarks(allBookmarks);
  }

  Future<void> removeBookmark(String id) async {
    final allBookmarks = _getAllBookmarks();
    allBookmarks.removeWhere((b) => b.id == id);
    await _saveBookmarks(allBookmarks);
  }

  List<Bookmark> _getAllBookmarks() {
    final jsonString = _prefs.getString(_storageKey);
    if (jsonString == null) return [];

    try {
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((json) => Bookmark.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> _saveBookmarks(List<Bookmark> bookmarks) async {
    final jsonList = bookmarks.map((b) => b.toJson()).toList();
    await _prefs.setString(_storageKey, json.encode(jsonList));
  }
}
