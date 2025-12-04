package com.example.awesome_video_player_fresh

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.provider.OpenableColumns
import android.webkit.MimeTypeMap
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream
import java.io.InputStream
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

class MainActivity: FlutterFragmentActivity() {
    private val CHANNEL = "com.example.awesome_video_player_fresh/video_intent"
    private var pendingVideoPath: String? = null
    private val executor: ExecutorService = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent?) {
        if (intent == null) return
        
        val action = intent.action
        val type = intent.type
        
        if (Intent.ACTION_VIEW == action && type != null && type.startsWith("video/")) {
            val uri: Uri? = intent.data
            if (uri != null) {
                // Pass content:// URI directly to Flutter
                // BetterPlayer will try to use it directly first
                // If it fails, Flutter can request a cached copy via copyContentUriToCache
                pendingVideoPath = uri.toString()
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getInitialVideoPath" -> {
                    val path = pendingVideoPath
                    pendingVideoPath = null // Clear after reading
                    result.success(path)
                }
                "copyContentUriToCache" -> {
                    android.util.Log.d("MainActivity", "copyContentUriToCache called")
                    val uriString = call.argument<String>("uri")
                    android.util.Log.d("MainActivity", "URI string: $uriString")
                    if (uriString != null) {
                        try {
                            val uri = Uri.parse(uriString)
                            android.util.Log.d("MainActivity", "Parsed URI: $uri, starting async copy...")
                            // Copy asynchronously to avoid blocking
                            executor.execute {
                                try {
                                    android.util.Log.d("MainActivity", "Executing copy in background thread...")
                                    val cachedPath = copyContentUriToCacheFile(uri)
                                    android.util.Log.d("MainActivity", "Copy completed: $cachedPath")
                                    mainHandler.post {
                                        result.success(cachedPath)
                                    }
                                } catch (e: Exception) {
                                    android.util.Log.e("MainActivity", "Error copying URI: ${e.message}", e)
                                    mainHandler.post {
                                        result.error("COPY_ERROR", "Failed to copy content URI: ${e.message}", null)
                                    }
                                }
                            }
                        } catch (e: Exception) {
                            android.util.Log.e("MainActivity", "Error parsing URI: ${e.message}", e)
                            result.error("INVALID_URI", "Invalid URI: ${e.message}", null)
                        }
                    } else {
                        android.util.Log.e("MainActivity", "URI argument is null")
                        result.error("INVALID_ARGUMENT", "URI argument is null", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    /**
     * Copy a content:// URI to a temporary file in the app's cache directory.
     * This is used as a fallback when BetterPlayer can't handle content:// URIs directly.
     */
    private fun copyContentUriToCacheFile(uri: Uri): String {
        // Try to determine a sensible file name
        val fileName = queryFileName(uri) ?: "shared_video_${System.currentTimeMillis()}"
        val extension = getExtensionFromUri(uri) ?: "mp4"
        val safeName = if (fileName.contains(".")) {
            fileName
        } else {
            "$fileName.$extension"
        }

        val destFile = File(cacheDir, safeName)

        contentResolver.openInputStream(uri)?.use { inputStream ->
            FileOutputStream(destFile).use { outputStream ->
                val buffer = ByteArray(8 * 1024)
                var bytesRead: Int
                while (true) {
                    bytesRead = inputStream.read(buffer)
                    if (bytesRead == -1) break
                    outputStream.write(buffer, 0, bytesRead)
                }
                outputStream.flush()
            }
        } ?: throw IllegalStateException("Unable to open InputStream for URI: $uri")

        return destFile.absolutePath
    }

    private fun queryFileName(uri: Uri): String? {
        return try {
            val cursor = contentResolver.query(uri, null, null, null, null)
            cursor?.use {
                val nameIndex = it.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                if (nameIndex != -1 && it.moveToFirst()) {
                    it.getString(nameIndex)
                } else {
                    null
                }
            }
        } catch (e: Exception) {
            null
        }
    }

    private fun getExtensionFromUri(uri: Uri): String? {
        return try {
            // First try from MIME type
            val mimeType = contentResolver.getType(uri)
            if (mimeType != null) {
                MimeTypeMap.getSingleton().getExtensionFromMimeType(mimeType)
            } else {
                // Fallback to path-based extension
                val path = uri.path ?: return null
                val dotIndex = path.lastIndexOf('.')
                if (dotIndex != -1 && dotIndex < path.length - 1) {
                    path.substring(dotIndex + 1)
                } else {
                    null
                }
            }
        } catch (e: Exception) {
            null
        }
    }
}
