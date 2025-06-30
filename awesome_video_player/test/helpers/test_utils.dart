import 'dart:io';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:permission_handler_platform_interface/permission_handler_platform_interface.dart';
import 'package:photo_manager/photo_manager.dart';

/// Utility class for setting up test environment and mocking platform services
class TestUtils {
  /// Sets up the test environment with necessary mocks
  static void setupTestEnvironment() {
    TestWidgetsFlutterBinding.ensureInitialized();
    
    // Mock SharedPreferences
    SharedPreferences.setMockInitialValues({});
    
    // Mock path provider
    _mockPathProvider();
    
    // Mock permission handler
    _mockPermissionHandler();
    
    // Mock photo manager
    _mockPhotoManager();
  }

  /// Mocks the path provider platform interface
  static void _mockPathProvider() {
    PathProviderPlatform.instance = MockPathProviderPlatform();
  }

  /// Mocks the permission handler platform interface
  static void _mockPermissionHandler() {
    PermissionHandlerPlatform.instance = MockPermissionHandlerPlatform();
  }

  /// Mocks the photo manager
  static void _mockPhotoManager() {
    // PhotoManager mocking would be done through method channels
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('com.fluttercandies.photo_manager'),
      (MethodCall methodCall) async {
        switch (methodCall.method) {
          case 'requestPermissionExtend':
            return 1; // PermissionState.authorized
          case 'getAssetPathList':
            return [];
          case 'getAssetListPaged':
            return [];
          default:
            return null;
        }
      },
    );
  }

  /// Creates a temporary directory for testing
  static Future<Directory> createTempDirectory() async {
    final tempDir = await Directory.systemTemp.createTemp('test_');
    return tempDir;
  }

  /// Creates a temporary file for testing
  static Future<File> createTempFile(String content, {String? extension}) async {
    final tempDir = await createTempDirectory();
    final fileName = 'test_file${extension ?? '.txt'}';
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsString(content);
    return file;
  }

  /// Creates a temporary video file for testing
  static Future<File> createTempVideoFile() async {
    final tempDir = await createTempDirectory();
    final file = File('${tempDir.path}/test_video.mp4');
    // Create a minimal MP4 file header for testing
    final bytes = [
      0x00, 0x00, 0x00, 0x20, 0x66, 0x74, 0x79, 0x70, // ftyp box
      0x69, 0x73, 0x6F, 0x6D, 0x00, 0x00, 0x02, 0x00, // isom brand
      0x69, 0x73, 0x6F, 0x6D, 0x69, 0x73, 0x6F, 0x32, // compatible brands
      0x61, 0x76, 0x63, 0x31, 0x6D, 0x70, 0x34, 0x31, // more brands
    ];
    await file.writeAsBytes(bytes);
    return file;
  }

  /// Cleans up temporary files and directories
  static Future<void> cleanupTempFiles(List<FileSystemEntity> entities) async {
    for (final entity in entities) {
      if (await entity.exists()) {
        await entity.delete(recursive: true);
      }
    }
  }

  /// Converts a Map to JSON string
  static String mapToJson(Map<String, dynamic> map) {
    return json.encode(map);
  }

  /// Converts JSON string to Map
  static Map<String, dynamic> jsonToMap(String jsonString) {
    return json.decode(jsonString) as Map<String, dynamic>;
  }

  /// Waits for a condition to be true with timeout
  static Future<void> waitForCondition(
    bool Function() condition, {
    Duration timeout = const Duration(seconds: 10),
    Duration interval = const Duration(milliseconds: 100),
  }) async {
    final stopwatch = Stopwatch()..start();
    
    while (!condition() && stopwatch.elapsed < timeout) {
      await Future.delayed(interval);
    }
    
    if (!condition()) {
      throw TimeoutException('Condition not met within timeout', timeout);
    }
  }

  /// Simulates a delay for testing async operations
  static Future<void> simulateDelay({Duration delay = const Duration(milliseconds: 100)}) async {
    await Future.delayed(delay);
  }

  /// Creates a mock method channel response
  static void mockMethodChannel(String channelName, Map<String, dynamic> responses) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      MethodChannel(channelName),
      (MethodCall methodCall) async {
        return responses[methodCall.method];
      },
    );
  }

  /// Resets all method channel mocks
  static void resetMethodChannelMocks() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(null, null);
  }
}

/// Mock implementation of PathProviderPlatform
class MockPathProviderPlatform extends PathProviderPlatform {
  @override
  Future<String?> getTemporaryPath() async {
    return '/tmp';
  }

  @override
  Future<String?> getApplicationSupportPath() async {
    return '/app_support';
  }

  @override
  Future<String?> getLibraryPath() async {
    return '/library';
  }

  @override
  Future<String?> getApplicationDocumentsPath() async {
    return '/documents';
  }

  @override
  Future<String?> getExternalStoragePath() async {
    return '/external';
  }

  @override
  Future<List<String>?> getExternalCachePaths() async {
    return ['/external_cache'];
  }

  @override
  Future<List<String>?> getExternalStoragePaths({StorageDirectory? type}) async {
    return ['/external_storage'];
  }

  @override
  Future<String?> getDownloadsPath() async {
    return '/downloads';
  }
}

/// Mock implementation of PermissionHandlerPlatform
class MockPermissionHandlerPlatform extends PermissionHandlerPlatform {
  @override
  Future<PermissionStatus> checkPermissionStatus(Permission permission) async {
    return PermissionStatus.granted;
  }

  @override
  Future<Map<Permission, PermissionStatus>> requestPermissions(
    List<Permission> permissions,
  ) async {
    return {for (final permission in permissions) permission: PermissionStatus.granted};
  }

  @override
  Future<bool> shouldShowRequestPermissionRationale(Permission permission) async {
    return false;
  }

  @override
  Future<ServiceStatus> checkServiceStatus(Permission permission) async {
    return ServiceStatus.enabled;
  }

  @override
  Future<bool> openAppSettings() async {
    return true;
  }
}

/// Exception for timeout scenarios
class TimeoutException implements Exception {
  final String message;
  final Duration timeout;

  const TimeoutException(this.message, this.timeout);

  @override
  String toString() => 'TimeoutException: $message (timeout: $timeout)';
}
