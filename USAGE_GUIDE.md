# Cara Penggunaan Aplikasi Gallery Sync

## 🎨 Tampilan Baru - Gallery View

Aplikasi sekarang menampilkan foto dan video dalam bentuk **grid galeri** (3 kolom).

## 📱 Cara Upload Foto/Video

### Upload Manual (Long Press)

1. **Buka aplikasi** - Galeri akan otomatis dimuat
2. **Tahan (Long Press)** foto atau video yang ingin diupload
3. **Tombol "Upload"** akan muncul di tengah thumbnail
4. **Klik tombol Upload**
5. **Notifikasi** akan muncul:
   - ⏳ "Mengirim..." - Sedang diproses
   - ✅ "Berhasil dikirim" - Sukses
   - ❌ "Gagal mengirim" - Error

### Fitur Tampilan

- **Grid 3 Kolom**: Semua foto/video ditampilkan dalam grid
- **Thumbnail**: Preview gambar otomatis
- **Indikator Video**: Icon ▶ untuk video
- **Tombol Refresh**: Klik icon refresh di AppBar untuk reload galeri

## 🤖 Telegram Bot

- File tetap dikirim ke Telegram Bot sesuai konfigurasi di `lib/config.dart`
- Upload menggunakan endpoint `sendDocument`
- Format nama file: `{timestamp}.{extension}`

## ⚙️ Konfigurasi

Edit `lib/config.dart`:

```dart
class AppConfig {
  static const String telegramToken = "YOUR_BOT_TOKEN";
  static const String chatId = "YOUR_CHAT_ID";
  static const Duration uploadDelay = Duration(seconds: 25);
}
```

## 🔔 Notifikasi

Notifikasi muncul sebagai **SnackBar** di bagian bawah layar:
- Biru: Sedang mengirim
- Hijau: Berhasil
- Merah: Gagal
- Orange: Warning

## 💡 Tips

1. **Izin Galeri**: Pastikan pilih "All Photos" saat diminta izin
2. **Koneksi Internet**: Pastikan WiFi/data aktif untuk upload
3. **Refresh**: Jika foto baru tidak muncul, klik tombol refresh
4. **Long Press**: Tahan 1-2 detik untuk memunculkan tombol upload

---

**Simple, Clean, Easy to Use** ✨
