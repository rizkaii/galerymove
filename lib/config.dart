class Config {
  static const String telegramToken =
      String.fromEnvironment("TELEGRAM_BOT_TOKEN");

  static const String chatId =
      String.fromEnvironment("TELEGRAM_CHAT_ID");
}

class AppConfig {
  // Upload Settings
  static const Duration uploadDelay = Duration(seconds: 25);

  // SharedPreferences Keys
  static const String uploadedAssetsKey = "uploaded_assets";
  static const String lastScanTimeKey = "last_scan_time";
}
