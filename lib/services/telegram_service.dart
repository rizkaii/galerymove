import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';
import '../config.dart';

class TelegramService {
  /// Upload file to Telegram using sendDocument endpoint
  static Future<bool> uploadFile(File file, String filename) async {
    try {
      final url = Uri.parse(
        'https://api.telegram.org/bot${AppConfig.telegramToken}/sendDocument',
      );

      // Create multipart request
      final request = http.MultipartRequest('POST', url);
      
      // Add chat_id field
      request.fields['chat_id'] = AppConfig.chatId;
      
      // Detect MIME type
      final mimeType = lookupMimeType(filename) ?? 'application/octet-stream';
      
      // Add file
      request.files.add(
        await http.MultipartFile.fromPath(
          'document',
          file.path,
          filename: filename,
          contentType: _parseMediaType(mimeType),
        ),
      );

      // Send request
      final response = await request.send();
      
      // Check response
      if (response.statusCode == 200) {
        print('✅ Successfully uploaded: $filename');
        return true;
      } else {
        final responseBody = await response.stream.bytesToString();
        print('❌ Failed to upload $filename: ${response.statusCode}');
        print('Response: $responseBody');
        return false;
      }
    } catch (e) {
      print('❌ Error uploading $filename: $e');
      return false;
    }
  }

  /// Parse MIME type string to http.MediaType
  static http.MediaType _parseMediaType(String mimeType) {
    final parts = mimeType.split('/');
    if (parts.length == 2) {
      return http.MediaType(parts[0], parts[1]);
    }
    return http.MediaType('application', 'octet-stream');
  }

  /// Test connection to Telegram API
  static Future<bool> testConnection() async {
    try {
      final url = Uri.parse(
        'https://api.telegram.org/bot${AppConfig.telegramToken}/getMe',
      );
      
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        print('✅ Telegram API connection successful');
        return true;
      } else {
        print('❌ Telegram API connection failed: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ Error testing Telegram API: $e');
      return false;
    }
  }
}
