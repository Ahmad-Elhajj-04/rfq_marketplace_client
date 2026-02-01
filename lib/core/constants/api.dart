import 'package:flutter/foundation.dart';

class Api {
  static String get baseUrl {
    if (kIsWeb) return "http://127.0.0.1:8080";
    // Android emulator to reach PC localhost
    return "http://10.0.2.2:8080";
  }

  static String get wsUrl {
    if (kIsWeb) return "ws://127.0.0.1:8000/connection/websocket";
    // Android emulator to reach PC localhost
    return "ws://10.0.2.2:8000/connection/websocket";
  }
}