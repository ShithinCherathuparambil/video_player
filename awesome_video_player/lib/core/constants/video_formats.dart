/// Video format constants and utilities
class VideoFormats {
  /// Common video file extensions
  static const List<String> extensions = [
    'mp4',
    'm4v',
    'm4p',
    'mov',
    'qt',
    'mkv',
    'webm',
    'mxf',
    'mpg',
    'mpeg',
    'mpe',
    'mpv',
    'mp2',
    'mpeg1',
    'mpeg2',
    'mpeg4',
    'avi',
    'wmv',
    'asf',
    'flv',
    'f4v',
    'f4p',
    'f4a',
    'f4b',
    'swf',
    'rm',
    '3gp',
    '3g2',
    'svi',
    'amv',
    'ogv',
    'ogg',
    'vob',
    'ogm',
    'mng',
    'gifv',
    'dv',
    'yuv',
    'roq',
    'nsv',
    'mod',
    'ts',
    'rmvb',
    'divx',
    'xvid',
  ];

  /// Network streaming formats
  static const List<String> streamingFormats = [
    'm3u8', // HLS
    'mpd', // DASH
    'rtsp',
    'rtmp',
  ];

  /// Check if format supports hardware decoding
  static bool supportsHardwareDecoding(String format) {
    const hardwareSupported = ['mp4', 'mkv', 'mov', 'm4v', '3gp'];
    return hardwareSupported.contains(format.toLowerCase());
  }

  /// Get format display name
  static String getDisplayName(String format) {
    final formatMap = {
      'mp4': 'MP4',
      'mkv': 'Matroska',
      'avi': 'AVI',
      'flv': 'Flash Video',
      'ts': 'Transport Stream',
      'mov': 'QuickTime',
      'webm': 'WebM',
      'm4v': 'M4V',
      '3gp': '3GP',
      'wmv': 'Windows Media',
      'mpg': 'MPEG',
      'mpeg': 'MPEG',
      'm3u8': 'HLS',
      'mpd': 'DASH',
      'rtsp': 'RTSP',
      'rtmp': 'RTMP',
    };
    return formatMap[format.toLowerCase()] ?? format.toUpperCase();
  }
}
