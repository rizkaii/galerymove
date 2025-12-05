# Gallery Sync App - iOS Upload to Telegram

Aplikasi Flutter untuk iOS yang secara otomatis mengupload foto dan video dari galeri iPhone ke Telegram Bot.

## 🎯 Fitur Utama

1. **Batch Slow Upload** - Upload foto/video lama secara bertahap (1 file setiap 25 detik)
2. **Auto-detect New Media** - Deteksi dan upload foto/video baru saat app dibuka
3. **Persistent Queue** - Queue upload tersimpan dan berlanjut saat app dibuka kembali
4. **Background Support** - Upload berjalan saat app di foreground (iOS limitation)
5. **Upload Tracking** - Melacak file yang sudah diupload menggunakan SharedPreferences

## 📋 Persyaratan

- Flutter SDK 3.0.0 atau lebih baru
- iOS 12.0 atau lebih baru (compatible dengan iPhone 8)
- Telegram Bot Token dan Chat ID

## 🚀 Setup & Instalasi

### 1. Clone atau Setup Project

```bash
cd c:\flutterproject\galeryup\gallery_sync_app
flutter pub get
```

### 2. Konfigurasi Telegram Bot

Edit file `lib/config.dart`:

```dart
class AppConfig {
  static const String telegramToken = "YOUR_BOT_TOKEN_HERE";
  static const String chatId = "YOUR_CHAT_ID_HERE";
  static const Duration uploadDelay = Duration(seconds: 25);
}
```

**Cara mendapatkan Bot Token:**
1. Buka Telegram dan cari @BotFather
2. Ketik `/newbot` dan ikuti instruksi
3. Copy token yang diberikan

**Cara mendapatkan Chat ID:**
1. Kirim pesan ke bot Anda
2. Buka: `https://api.telegram.org/bot<YOUR_TOKEN>/getUpdates`
3. Cari nilai `"chat":{"id":123456789}`

### 3. Setup iOS Permissions

Permissions sudah dikonfigurasi di `ios/Runner/Info.plist`:
- `NSPhotoLibraryUsageDescription` - Akses baca galeri
- `NSPhotoLibraryAddUsageDescription` - Akses tulis galeri

### 4. Install iOS Dependencies

```bash
cd ios
pod install
cd ..
```

### 5. Build & Run

```bash
# Untuk simulator iOS
flutter run

# Untuk device fisik
flutter run -d <device_id>
```

## 📁 Struktur Project

```
lib/
├── main.dart                      # UI utama & app lifecycle
├── config.dart                    # Konfigurasi Telegram & settings
└── services/
    ├── gallery_service.dart       # Scanning galeri & deteksi file baru
    ├── telegram_service.dart      # Upload ke Telegram Bot API
    └── upload_queue.dart          # Queue management & persistence
```

## 🎮 Cara Penggunaan

1. **Pertama kali buka app:**
   - App akan meminta izin akses galeri
   - App akan scan semua foto/video di galeri
   - Semua file ditambahkan ke queue

2. **Mulai Upload:**
   - Tap tombol "Start Upload"
   - Upload berjalan 1 file setiap 25 detik
   - Progress ditampilkan di UI

3. **App di background:**
   - iOS akan otomatis stop upload setelah beberapa detik
   - Upload akan berlanjut saat app dibuka kembali

4. **Deteksi file baru:**
   - Saat app dibuka lagi, otomatis cek file baru
   - File baru ditambahkan ke queue

## 🔧 iOS Limitations & Best Practices

**iOS Background Task Limitations:**
- iOS secara default membatasi background task
- Upload akan berhenti saat app di background setelah ~30 detik
- App akan melanjutkan upload saat dibuka kembali

**Tips untuk Maximum Upload:**
- Biarkan app tetap terbuka (jangan lock screen)
- Colokkan ke charger untuk mencegah battery-saving mode
- Pastikan WiFi stabil untuk upload

## 📊 Upload Statistics

UI menampilkan:
- **Total Files** - Jumlah total file di queue + yang sudah diupload
- **Uploaded** - Jumlah file yang berhasil diupload
- **Remaining** - Jumlah file yang masih dalam antrian
- **Progress Bar** - Visualisasi progres upload
- **Upload Log** - Log real-time setiap aktivitas

## 🐛 Troubleshooting

**Permission Denied:**
- Buka Settings → Privacy & Security → Photos
- Pastikan app memiliki akses "All Photos"

**Upload Failed:**
- Cek Telegram Bot Token & Chat ID di `config.dart`
- Test koneksi dengan: `TelegramService.testConnection()`
- Pastikan internet stabil

**Files Not Detected:**
- Pastikan permission "All Photos" granted
- Force close dan buka ulang app
- Tap tombol "Scan" untuk manual scan

## 🔐 Privacy & Security

- Telegram Bot Token disimpan di local config (tidak di commit ke git)
- File upload menggunakan HTTPS (Telegram API)
- Tidak ada data user yang dikumpulkan
- Upload history tersimpan di SharedPreferences (local device)

## 📝 Catatan Penting

1. **Upload Delay** dapat diubah di `config.dart` (default 25 detik)
2. **File yang sudah diupload** tidak akan diupload ulang
3. **Clear Upload History** dapat dilakukan dari code (untuk testing)
4. **iOS 12 Compatible** - Tested untuk iPhone 8 dan lebih baru

## 🔮 Future Improvements

- [ ] Background upload using BGTaskScheduler (iOS 13+)
- [ ] Compress video sebelum upload
- [ ] Multiple Telegram destinations
- [ ] Upload statistics & analytics
- [ ] Retry failed uploads otomatis

## 📄 License

MIT License - Free to use and modify

## 👨‍💻 Developer Notes

**Key Dependencies:**
- `photo_manager: ^3.0.0` - Gallery access
- `http: ^1.1.0` - HTTP client for Telegram API
- `shared_preferences: ^2.2.2` - Persistent storage
- `mime: ^1.0.4` - MIME type detection

**Upload Queue Mechanism:**
- Uses Timer.periodic untuk interval upload
- SharedPreferences untuk track uploaded files
- Auto-retry untuk failed uploads
- Lifecycle observer untuk handle app state changes

---

**Made with ❤️ using Flutter**
