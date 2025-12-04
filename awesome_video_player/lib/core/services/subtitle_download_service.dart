import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:lumeo/data/datasources/subtitle_network_data_source.dart';
import 'package:lumeo/core/services/subtitle_service.dart';

/// Service for downloading subtitles from network
class SubtitleDownloadService {
  final SubtitleNetworkDataSource _networkDataSource = SubtitleNetworkDataSource();
  final SubtitleService _subtitleService = SubtitleService();

  /// Search and download subtitles for a video
  Future<String?> downloadSubtitleForVideo(
    String videoPath,
    String languageCode, {
    String? preferredReleaseName,
  }) async {
    try {
      // Calculate video hash
      final videoHash = await SubtitleNetworkDataSource.calculateVideoHash(videoPath);
      
      // Search by hash first (most accurate)
      List<SubtitleSearchResult> results = [];
      if (videoHash.isNotEmpty) {
        results = await _networkDataSource.searchByHash(videoHash);
      }

      // If no results, try searching by filename
      if (results.isEmpty) {
        final filename = videoPath.split('/').last;
        results = await _networkDataSource.searchByFilename(filename);
      }

      // Filter by language
      results = results.where((r) => r.languageCode == languageCode).toList();

      // Sort by score (relevance)
      results.sort((a, b) => b.score.compareTo(a.score));

      // Try preferred release name if provided
      if (preferredReleaseName != null) {
        final preferred = results.firstWhere(
          (r) => r.releaseName.contains(preferredReleaseName),
          orElse: () => results.first,
        );
        results.insert(0, preferred);
      }

      if (results.isEmpty) {
        debugPrint('No subtitles found for video: $videoPath');
        return null;
      }

      // Download the best match
      final bestMatch = results.first;
      final savePath = await _getSubtitleSavePath(videoPath, languageCode);
      
      final downloadedPath = await _networkDataSource.downloadSubtitle(
        bestMatch.downloadUrl,
        savePath,
      );

      if (downloadedPath != null) {
        // Load the subtitle to verify it's valid
        await _subtitleService.loadFromFile(downloadedPath);
        return downloadedPath;
      }

      return null;
    } catch (e) {
      debugPrint('Error downloading subtitle: $e');
      return null;
    }
  }

  /// Auto-match and download subtitle for video
  Future<String?> autoDownloadSubtitle(String videoPath) async {
    // Try common languages
    final languages = ['en', 'eng', 'english'];
    
    for (final lang in languages) {
      final result = await downloadSubtitleForVideo(videoPath, lang);
      if (result != null) {
        return result;
      }
    }
    
    return null;
  }

  /// Get save path for subtitle file
  Future<String> _getSubtitleSavePath(String videoPath, String languageCode) async {
    final videoFile = File(videoPath);
    final videoName = videoFile.path.split('/').last.split('.').first;
    final directory = videoFile.parent;
    
    return '${directory.path}/$videoName.$languageCode.srt';
  }
}

