import 'dart:async';
import 'dart:io';
import 'package:photo_manager/photo_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';
import 'telegram_service.dart';

class UploadQueue {
  final List<String> _queue = [];
  final Set<String> _uploadedAssets = {};
  bool _isUploading = false;
  Timer? _uploadTimer;
  
  // Callbacks for UI updates
  Function(String message)? onLog;
  Function(int total, int uploaded)? onProgressUpdate;

  /// Initialize queue and load uploaded assets from storage
  Future<void> initialize() async {
    await _loadUploadedAssets();
  }

  /// Load previously uploaded assets from SharedPreferences
  Future<void> _loadUploadedAssets() async {
    final prefs = await SharedPreferences.getInstance();
    final uploaded = prefs.getStringList(AppConfig.uploadedAssetsKey) ?? [];
    _uploadedAssets.addAll(uploaded);
    _log('Loaded ${_uploadedAssets.length} previously uploaded assets');
  }

  /// Save uploaded assets to SharedPreferences
  Future<void> _saveUploadedAssets() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      AppConfig.uploadedAssetsKey,
      _uploadedAssets.toList(),
    );
  }

  /// Add assets to queue (skip already uploaded)
  void addAssets(List<AssetEntity> assets) {
    for (final asset in assets) {
      if (!_uploadedAssets.contains(asset.id) && !_queue.contains(asset.id)) {
        _queue.add(asset.id);
      }
    }
    _log('Added ${assets.length} assets to queue. Queue size: ${_queue.length}');
    _updateProgress();
  }

  /// Get total count (queue + uploaded)
  int get totalCount => _queue.length + _uploadedAssets.length;
  
  /// Get uploaded count
  int get uploadedCount => _uploadedAssets.length;
  
  /// Get remaining count
  int get remainingCount => _queue.length;

  /// Check if currently uploading
  bool get isUploading => _isUploading;

  /// Start upload process
  Future<void> startUpload() async {
    if (_isUploading) {
      _log('Upload already in progress');
      return;
    }

    if (_queue.isEmpty) {
      _log('No files in queue');
      return;
    }

    _isUploading = true;
    _log('Starting upload process...');
    
    // Upload first file immediately
    await _uploadNext();
    
    // Schedule periodic uploads
    _uploadTimer = Timer.periodic(AppConfig.uploadDelay, (timer) async {
      await _uploadNext();
    });
  }

  /// Upload next file in queue
  Future<void> _uploadNext() async {
    if (_queue.isEmpty) {
      _log('Queue is empty. Stopping upload.');
      stopUpload();
      return;
    }

    final assetId = _queue.removeAt(0);
    
    try {
      // Get asset entity
      final asset = await AssetEntity.fromId(assetId);
      if (asset == null) {
        _log('⚠️ Asset not found: $assetId');
        return;
      }

      // Get file
      final file = await asset.file;
      if (file == null) {
        _log('⚠️ Could not get file for asset: $assetId');
        return;
      }

      // Generate filename
      final extension = file.path.split('.').last;
      final filename = '${asset.createDateTime.millisecondsSinceEpoch}.$extension';
      
      _log('Uploading: $filename (${_formatFileSize(file.lengthSync())})');
      
      // Upload to Telegram
      final success = await TelegramService.uploadFile(file, filename);
      
      if (success) {
        _uploadedAssets.add(assetId);
        await _saveUploadedAssets();
        _log('✅ Uploaded: $filename');
      } else {
        _log('❌ Failed: $filename');
        // Re-add to queue for retry
        _queue.add(assetId);
      }
      
      _updateProgress();
    } catch (e) {
      _log('❌ Error uploading $assetId: $e');
      // Re-add to queue for retry
      _queue.add(assetId);
    }
  }

  /// Stop upload process
  void stopUpload() {
    _uploadTimer?.cancel();
    _uploadTimer = null;
    _isUploading = false;
    _log('Upload process stopped');
  }

  /// Clear all uploaded assets (for testing)
  Future<void> clearUploadHistory() async {
    _uploadedAssets.clear();
    await _saveUploadedAssets();
    _log('Upload history cleared');
    _updateProgress();
  }

  /// Log message
  void _log(String message) {
    final timestamp = DateTime.now().toString().substring(11, 19);
    final logMessage = '[$timestamp] $message';
    print(logMessage);
    onLog?.call(logMessage);
  }

  /// Update progress callback
  void _updateProgress() {
    onProgressUpdate?.call(totalCount, uploadedCount);
  }

  /// Format file size to human readable
  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Dispose resources
  void dispose() {
    stopUpload();
  }
}
