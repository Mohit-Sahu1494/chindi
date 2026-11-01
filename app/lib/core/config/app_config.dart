import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;

class AppConfig {
  AppConfig._();

  // Android emulator maps 10.0.2.2 to the host machine's localhost
  // iOS simulator or desktop/web uses localhost (127.0.0.1)
  static String get defaultHost {
    if (kIsWeb) return 'http://localhost:5000';
    try {
      if (Platform.isAndroid) {
        return 'http://10.0.2.2:5000';
      }
    } catch (_) {}
    return 'http://localhost:5000';
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
