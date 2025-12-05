import 'package:photo_manager/photo_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';

class GalleryService {
  /// Request permission to access gallery
  static Future<bool> requestPermission() async {
    final PermissionState ps = await PhotoManager.requestPermissionExtend();
    
    if (ps == PermissionState.authorized || ps == PermissionState.limited) {
      return true;
    } else {
      return false;
    }
  }

  /// Scan all local assets (photos & videos)
  static Future<List<AssetEntity>> scanAllAssets() async {
    final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList(
      type: RequestType.common, // Both images and videos
      hasAll: true,
    );

    if (paths.isEmpty) {
      return [];
    }

    // Get all assets from the first path (usually "Recent" or "All Photos")
    final AssetPathEntity recentPath = paths.first;
    final List<AssetEntity> assets = await recentPath.getAssetListRange(
      start: 0,
      end: await recentPath.assetCountAsync,
    );

    return assets;
  }

  /// Get new assets since last scan
  static Future<List<AssetEntity>> getNewAssets() async {
    final prefs = await SharedPreferences.getInstance();
    final lastScanMillis = prefs.getInt(AppConfig.lastScanTimeKey) ?? 0;
    final lastScanTime = DateTime.fromMillisecondsSinceEpoch(lastScanMillis);

    final allAssets = await scanAllAssets();
    
    // Filter assets created after last scan
    final newAssets = allAssets.where((asset) {
      return asset.createDateTime.isAfter(lastScanTime);
    }).toList();

    return newAssets;
  }

  /// Update last scan time
  static Future<void> updateLastScanTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      AppConfig.lastScanTimeKey,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Get file from asset entity
  static Future<AssetEntity?> getAssetById(String id) async {
    try {
      final asset = await AssetEntity.fromId(id);
      return asset;
    } catch (e) {
      return null;
    }
  }
}
