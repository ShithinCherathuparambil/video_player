import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Comprehensive error handling utilities with user-friendly messages and retry mechanisms
class ErrorHandler {
  /// Get user-friendly error message from exception
  static String getUserFriendlyMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();

    // Network errors
    if (errorString.contains('network') || errorString.contains('connection')) {
      return 'Network connection failed. Please check your internet connection and try again.';
    }

    // Permission errors
    if (errorString.contains('permission') || errorString.contains('denied')) {
      return 'Permission denied. Please grant the required permissions in settings.';
    }

    // Storage errors
    if (errorString.contains('storage') || errorString.contains('disk')) {
      return 'Storage error. Please check available storage space.';
    }

    // File not found
    if (errorString.contains('not found') || errorString.contains('file')) {
      return 'File not found. The video may have been moved or deleted.';
    }

    // Format/codec errors
    if (errorString.contains('format') || errorString.contains('codec')) {
      return 'Unsupported video format. Please try a different video file.';
    }

    // Decoder errors
    if (errorString.contains('decoder') || errorString.contains('decode')) {
      return 'Video decoding failed. Try switching to software decoder.';
    }

    // Generic error
    return 'An error occurred. Please try again.';
  }

  /// Show error snackbar with retry option
  static void showErrorSnackBar(
    BuildContext context,
    String message, {
    VoidCallback? onRetry,
    Duration duration = const Duration(seconds: 4),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(width: 8),
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  onRetry();
                },
                child: const Text(
                  'RETRY',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        backgroundColor: Colors.red.shade700,
        duration: duration,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Show error dialog with retry option
  static Future<bool?> showErrorDialog(
    BuildContext context,
    String title,
    String message, {
    String? retryText,
    String? cancelText,
    VoidCallback? onRetry,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error),
            const SizedBox(width: 8),
            Expanded(child: Text(title)),
          ],
        ),
        content: Text(message),
        actions: [
          if (cancelText != null)
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(cancelText),
            ),
          if (onRetry != null)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
                onRetry();
              },
              child: Text(retryText ?? 'Retry'),
            ),
        ],
      ),
    );
  }

  /// Handle error with automatic retry mechanism
  static Future<T?> handleWithRetry<T>({
    required Future<T> Function() operation,
    required BuildContext context,
    int maxRetries = 3,
    Duration retryDelay = const Duration(seconds: 2),
    String? customErrorMessage,
    bool showError = true,
  }) async {
    int attempts = 0;

    while (attempts < maxRetries) {
      try {
        return await operation();
      } catch (e) {
        attempts++;

        if (attempts < maxRetries) {
          // Wait before retrying
          await Future.delayed(retryDelay);
          continue;
        } else {
          // Max retries reached
          if (showError && context.mounted) {
            final message = customErrorMessage ?? getUserFriendlyMessage(e);
            showErrorSnackBar(
              context,
              message,
              onRetry: () {
                handleWithRetry(
                  operation: operation,
                  context: context,
                  maxRetries: maxRetries,
                  retryDelay: retryDelay,
                  customErrorMessage: customErrorMessage,
                );
              },
            );
          }
          return null;
        }
      }
    }

    return null;
  }

  /// Log error for debugging
  static void logError(dynamic error, {StackTrace? stackTrace, String? context}) {
    debugPrint('=== ERROR LOG ===');
    if (context != null) {
      debugPrint('Context: $context');
    }
    debugPrint('Error: $error');
    if (stackTrace != null) {
      debugPrint('Stack trace: $stackTrace');
    }
    debugPrint('=================');
  }

  /// Show loading indicator during async operation with error handling
  static Future<T?> showLoadingWithErrorHandling<T>({
    required BuildContext context,
    required Future<T> Function() operation,
    String? loadingMessage,
    String? errorMessage,
    bool dismissOnError = true,
  }) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              if (loadingMessage != null) ...[
                const SizedBox(height: 16),
                Text(loadingMessage),
              ],
            ],
          ),
        ),
      ),
    );

    try {
      final result = await operation();
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
      }
      return result;
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        if (dismissOnError) {
          showErrorSnackBar(
            context,
            errorMessage ?? getUserFriendlyMessage(e),
          );
        } else {
          showErrorDialog(
            context,
            'Error',
            errorMessage ?? getUserFriendlyMessage(e),
            retryText: 'OK',
          );
        }
      }
      return null;
    }
  }
}

/// Error types for better error categorization
enum ErrorType {
  network,
  permission,
  storage,
  fileNotFound,
  format,
  decoder,
  unknown,
}

/// Extension to categorize errors
extension ErrorTypeExtension on dynamic {
  ErrorType get errorType {
    final errorString = toString().toLowerCase();
    if (errorString.contains('network') || errorString.contains('connection')) {
      return ErrorType.network;
    }
    if (errorString.contains('permission') || errorString.contains('denied')) {
      return ErrorType.permission;
    }
    if (errorString.contains('storage') || errorString.contains('disk')) {
      return ErrorType.storage;
    }
    if (errorString.contains('not found') || errorString.contains('file')) {
      return ErrorType.fileNotFound;
    }
    if (errorString.contains('format') || errorString.contains('codec')) {
      return ErrorType.format;
    }
    if (errorString.contains('decoder') || errorString.contains('decode')) {
      return ErrorType.decoder;
    }
    return ErrorType.unknown;
  }
}

