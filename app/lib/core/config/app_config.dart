import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;

class AppConfig {
  AppConfig._();

  // Android emulator maps 10.0.2.2 to the host machine's localhost
  // iOS simulator or desktop/web uses localhost (127.0.0.1)
  static String get defaultHost {
    if (kIsWeb) return 'https://chindi-dmbqepcgf9f3e2h3.centralindia-01.azurewebsites.net';
    try {
      if (Platform.isAndroid) {
        return 'https://chindi-dmbqepcgf9f3e2h3.centralindia-01.azurewebsites.net';
      }
    } catch (_) {}
    return 'https://chindi-dmbqepcgf9f3e2h3.centralindia-01.azurewebsites.net';
  }

  // Base API URL
  static const String _envApiUrl = String.fromEnvironment('API_URL');
  static String get apiBaseUrl {
    if (_envApiUrl.isNotEmpty) return _envApiUrl;
    return '$defaultHost/api';
  }

  // Base Socket URL
  static const String _envSocketUrl = String.fromEnvironment('SOCKET_URL');
  static String get socketBaseUrl {
    if (_envSocketUrl.isNotEmpty) return _envSocketUrl;
    return defaultHost;
  }
}
