import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lumeo/domain/entities/video_file.dart';
import 'package:lumeo/core/utils/video_utils.dart';
import 'package:lumeo/presentation/widgets/glassmorphism/glass_container.dart';

/// Continue watching card widget
class ContinueWatchingCard extends StatelessWidget {
  final VideoFile video;
  final Duration? position;
  final Duration? duration;
  final VoidCallback onTap;
  final VoidCallback? onRemove;

  const ContinueWatchingCard({
    super.key,
    required this.video,
    this.position,
    this.duration,
    required this.onTap,
    this.onRemove,
  });

  double get _progress {
    if (position == null || duration == null || duration!.inMilliseconds == 0) {
      return 0.0;
    }
    return (position!.inMilliseconds / duration!.inMilliseconds).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 220.h,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail + progress
              Expanded(
                flex: 3,
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8.r),
                      child: Container(
                        width: double.infinity,
                        height: double.infinity,
                        decoration: BoxDecoration(
                          image: video.thumbnailBytes != null
                              ? DecorationImage(
                                  image: MemoryImage(video.thumbnailBytes!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                          color: video.thumbnailBytes == null
                              ? Colors.grey[800]
                              : null,
                        ),
                        child: video.thumbnailBytes == null
                            ? const Center(
                                child: Icon(
                                  Icons.video_library,
                                  size: 48,
                                  color: Colors.white70,
                                ),
                              )
                            : null,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: LinearProgressIndicator(
                        value: _progress,
                        backgroundColor: Colors.white.withOpacity(0.3),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    if (onRemove != null)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: onRemove,
                        ),
                      ),
                  ],
                ),
              ),
              // Text area
              Expanded(
                flex: 2,
                child: Padding(
                  padding: EdgeInsets.all(12.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          video.name,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Row(
                        children: [
                          if (position != null && duration != null) ...[
                            Text(
                              VideoUtils.formatDuration(position!),
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 11.sp,
                              ),
                            ),
                            Text(
                              ' / ',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 11.sp,
                              ),
                            ),
                            Text(
                              VideoUtils.formatDuration(duration!),
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 11.sp,
                              ),
                            ),
                          ] else if (duration != null) ...[
                            Text(
                              VideoUtils.formatDuration(duration!),
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 11.sp,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

