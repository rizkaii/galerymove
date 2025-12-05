import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'services/gallery_service.dart';
import 'services/upload_queue.dart';
import 'services/telegram_service.dart';
import 'config.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gallery Sync',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const GalleryPage(),
    );
  }
}

class GalleryPage extends StatefulWidget {
  const GalleryPage({super.key});

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> with WidgetsBindingObserver {
  final UploadQueue _uploadQueue = UploadQueue();
  List<AssetEntity> _assets = [];
  bool _isLoading = true;
  String? _selectedAssetId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeApp();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _uploadQueue.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadAssets();
    }
  }

  Future<void> _initializeApp() async {
    await _uploadQueue.initialize();

    // Request gallery permission
    final hasPermission = await GalleryService.requestPermission();
    
    if (!hasPermission) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Izin akses galeri ditolak'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    await _loadAssets();
  }

  Future<void> _loadAssets() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final assets = await GalleryService.scanAllAssets();
      setState(() {
        _assets = assets;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error memuat galeri: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _uploadAsset(AssetEntity asset) async {
    try {
      // Get file from asset
      final file = await asset.file;
      if (file == null) {
        _showNotification('⚠️ Tidak dapat mengakses file', Colors.orange);
        return;
      }

      // Generate filename
      final extension = file.path.split('.').last;
      final filename = '${asset.createDateTime.millisecondsSinceEpoch}.$extension';
      
      // Show uploading notification
      _showNotification('⏳ Mengirim...', Colors.blue);

      // Upload to Telegram
      final success = await TelegramService.uploadFile(file, filename);
      
      if (success) {
        _showNotification('✅ Berhasil dikirim', Colors.green);
      } else {
        _showNotification('❌ Gagal mengirim', Colors.red);
      }
    } catch (e) {
      _showNotification('❌ Error: $e', Colors.red);
    }
  }

  void _showNotification(String message, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Galeri'),
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAssets,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _assets.isEmpty
              ? const Center(
                  child: Text(
                    'Tidak ada foto atau video',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(4),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 4,
                  ),
                  itemCount: _assets.length,
                  itemBuilder: (context, index) {
                    final asset = _assets[index];
                    return GestureDetector(
                      onLongPressStart: (_) {
                        setState(() {
                          _selectedAssetId = asset.id;
                        });
                      },
                      onLongPressEnd: (_) {
                        // Keep selection visible for a moment
                        Future.delayed(const Duration(milliseconds: 300), () {
                          if (mounted && _selectedAssetId == asset.id) {
                            setState(() {
                              _selectedAssetId = null;
                            });
                          }
                        });
                      },
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Thumbnail
                          AssetThumbnail(asset: asset),
                          
                          // Video indicator
                          if (asset.type == AssetType.video)
                            const Positioned(
                              bottom: 4,
                              right: 4,
                              child: Icon(
                                Icons.play_circle_filled,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          
                          // Upload button (shown on long press)
                          if (_selectedAssetId == asset.id)
                            Positioned.fill(
                              child: Container(
                                color: Colors.black54,
                                child: Center(
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      setState(() {
                                        _selectedAssetId = null;
                                      });
                                      _uploadAsset(asset);
                                    },
                                    icon: const Icon(Icons.upload),
                                    label: const Text('Upload'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}

class AssetThumbnail extends StatelessWidget {
  final AssetEntity asset;

  const AssetThumbnail({super.key, required this.asset});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _buildThumbnail(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done && snapshot.data != null) {
          return snapshot.data!;
        }
        return Container(
          color: Colors.grey[300],
          child: const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      },
    );
  }

  Future<Widget> _buildThumbnail() async {
    final thumbnail = await asset.thumbnailDataWithSize(
      const ThumbnailSize(200, 200),
    );
    
    if (thumbnail != null) {
      return Image.memory(
        thumbnail,
        fit: BoxFit.cover,
      );
    }
    
    return Container(
      color: Colors.grey[300],
      child: const Icon(Icons.broken_image, color: Colors.grey),
    );
  }
}
