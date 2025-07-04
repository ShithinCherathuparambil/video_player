import 'package:flutter/foundation.dart';
import 'package:photo_manager/photo_manager.dart';

/// Service to handle storage permissions for video operations
class PermissionService {
  static PermissionService? _instance;
  
  PermissionService._();
  
  static PermissionService get instance {
    _instance ??= PermissionService._();
    return _instance!;
  }

  /// Request storage permissions with comprehensive retry logic
  Future<bool> requestStoragePermissions({bool showDialog = true}) async {
    try {
      debugPrint('PermissionService: Requesting storage permissions...');
      
      // First attempt - basic permission request
      final permissionState = await PhotoManager.requestPermissionExtend();
      debugPrint('PermissionService: Initial permission state: ${permissionState.name}');
      
      if (permissionState.isAuth) {
        debugPrint('PermissionService: Permissions granted successfully');
        return true;
      }
      
      // Second attempt - with specific options
      debugPrint('PermissionService: Retrying with specific options...');
      final retryPermission = await PhotoManager.requestPermissionExtend(
        requestOption: const PermissionRequestOption(
          androidPermission: AndroidPermission(
            type: RequestType.video,
            mediaLocation: true,
          ),
        ),
      );
      debugPrint('PermissionService: Retry permission state: ${retryPermission.name}');
      
      if (retryPermission.isAuth) {
        debugPrint('PermissionService: Permissions granted on retry');
        return true;
      }
      
      // Third attempt - request all media types
      debugPrint('PermissionService: Final attempt with all media types...');
      final finalPermission = await PhotoManager.requestPermissionExtend(
        requestOption: const PermissionRequestOption(
          androidPermission: AndroidPermission(
            type: RequestType.all,
            mediaLocation: true,
          ),
        ),
      );
      debugPrint('PermissionService: Final permission state: ${finalPermission.name}');
      
      return finalPermission.isAuth;
    } catch (e) {
      debugPrint('PermissionService: Error requesting permissions: $e');
      return false;
    }
  }

  /// Check if storage permissions are currently granted
  Future<bool> hasStoragePermissions() async {
    try {
      final permissionState = await PhotoManager.requestPermissionExtend();
      return permissionState.isAuth;
    } catch (e) {
      debugPrint('PermissionService: Error checking permissions: $e');
      return false;
    }
  }

  /// Get current permission state
  Future<PermissionState> getPermissionState() async {
    try {
      return await PhotoManager.requestPermissionExtend();
    } catch (e) {
      debugPrint('PermissionService: Error getting permission state: $e');
      return PermissionState.denied;
    }
  }

  /// Open app settings for manual permission grant
  Future<void> openAppSettings() async {
    try {
      await PhotoManager.openSetting();
    } catch (e) {
      debugPrint('PermissionService: Error opening app settings: $e');
    }
  }

  /// Get user-friendly permission status message
  String getPermissionStatusMessage(PermissionState state) {
    switch (state) {
      case PermissionState.authorized:
        return 'Storage access granted';
      case PermissionState.denied:
        return 'Storage access denied. Please grant permission to delete videos.';
      case PermissionState.restricted:
        return 'Storage access restricted by device policy.';
      case PermissionState.limited:
        return 'Limited storage access granted. Some features may not work.';
      case PermissionState.notDetermined:
        return 'Storage permission not determined. Please grant access.';
    }
  }
}
