import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:lumeo/core/services/video_cache_service.dart';

/// Optimized lazy-loading thumbnail widget with caching
class LazyThumbnail extends StatefulWidget {
  final String? thumbnailPath;
  final Uint8List? thumbnailBytes;
  final String videoPath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;

  const LazyThumbnail({
    super.key,
    this.thumbnailPath,
    this.thumbnailBytes,
    required this.videoPath,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
  });

  @override
  State<LazyThumbnail> createState() => _LazyThumbnailState();
}

class _LazyThumbnailState extends State<LazyThumbnail> {
  Uint8List? _cachedBytes;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadThumbnail();
  }

  @override
  void didUpdateWidget(LazyThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoPath != widget.videoPath ||
        oldWidget.thumbnailPath != widget.thumbnailPath ||
        oldWidget.thumbnailBytes != widget.thumbnailBytes) {
      _loadThumbnail();
    }
  }

  Future<void> _loadThumbnail() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      // Check cache first
      final cachedBytes = await VideoCacheService.instance
          .getThumbnail(widget.videoPath);
      
      if (cachedBytes != null) {
        if (mounted) {
          setState(() {
            _cachedBytes = cachedBytes;
            _isLoading = false;
          });
        }
        return;
      }

      // Use provided thumbnail bytes
      if (widget.thumbnailBytes != null) {
        // Save to cache
        await VideoCacheService.instance.saveThumbnail(
          widget.videoPath,
          widget.thumbnailBytes!,
        );
        if (mounted) {
          setState(() {
            _cachedBytes = widget.thumbnailBytes;
            _isLoading = false;
          });
        }
        return;
      }

      // Load from file path
      if (widget.thumbnailPath != null) {
        final file = File(widget.thumbnailPath!);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          // Save to cache
          await VideoCacheService.instance.saveThumbnail(
            widget.videoPath,
            bytes,
          );
          if (mounted) {
            setState(() {
              _cachedBytes = bytes;
              _isLoading = false;
            });
          }
          return;
        }
      }

      // No thumbnail available
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return widget.placeholder ??
          Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
          );
    }

    if (_hasError || _cachedBytes == null) {
      return widget.errorWidget ??
          Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.play_circle_outline,
              size: (widget.width ?? widget.height ?? 40) * 0.5,
              color: Theme.of(context).colorScheme.primary,
            ),
          );
    }

    return Image.memory(
      _cachedBytes!,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      cacheWidth: widget.width != null && widget.width!.isFinite ? widget.width!.toInt() : null,
      cacheHeight: widget.height != null && widget.height!.isFinite ? widget.height!.toInt() : null,
      errorBuilder: (context, error, stackTrace) {
        return widget.errorWidget ??
            Container(
              width: widget.width,
              height: widget.height,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.broken_image,
                size: (widget.width ?? widget.height ?? 40) * 0.5,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            );
      },
    );
  }
}

