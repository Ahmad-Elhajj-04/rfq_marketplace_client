import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

class WsService {
  WsService._();
  static final WsService instance = WsService._();

  WebSocketChannel? _channel;
  int _id = 1;
  bool _connected = false;

  // Centrifugo WS endpoint (Flutter Web runs on same PC)
  final String wsUrl = "ws://localhost:8000/connection/websocket";

  void connect() {
    if (_channel != null) return;

    _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

    _channel!.stream.listen(
          (raw) {
        _handleMessage(raw);
      },
      onError: (_) {
        _connected = false;
      },
      onDone: () {
        _connected = false;
        _channel = null;
      },
    );

    // Connect command
    _send({
      "id": _id++,
      "method": "connect",
      "params": {}
    });
  }

  void subscribe(String channel) {
    if (_channel == null) return;

    // If connect response hasn’t arrived yet, Centrifugo will still accept
    _send({
      "id": _id++,
      "method": "subscribe",
      "params": {"channel": channel}
    });
  }

  void disconnect() {
    _channel?.sink.close();
    _channel = null;
    _connected = false;
  }

  void _send(Map<String, dynamic> data) {
    _channel?.sink.add(jsonEncode(data));
  }

  // You can hook this from outside
  void Function(String title, String body)? onBanner;

  void _handleMessage(dynamic raw) {
    final str = raw.toString();
    Map<String, dynamic>? msg;
    try {
      msg = jsonDecode(str) as Map<String, dynamic>;
    } catch (_) {
      return;
    }

    // Mark connected when connect result arrives
    if (msg.containsKey("id") && msg["id"] == 1 && msg["result"] != null) {
      _connected = true;
      return;
    }

    // Centrifugo publications arrive as push messages.
    // Try to find publication data in common shapes.
    final push = msg["push"];
    if (push is Map<String, dynamic>) {
      final pub = push["pub"];
      if (pub is Map<String, dynamic>) {
        final data = pub["data"];
        _emitBannerFromData(data);
        return;
      }
    }

    // Sometimes messages may come as { "result": { "publications": ... } }
    final result = msg["result"];
    if (result is Map<String, dynamic>) {
      final pub = result["pub"];
      if (pub is Map<String, dynamic>) {
        _emitBannerFromData(pub["data"]);
      }
    }
  }

  void _emitBannerFromData(dynamic data) {
    if (data == null) return;

    // Data should be JSON object (map) because backend publishes JSON.
    if (data is Map<String, dynamic>) {
      final title = (data["title"] ?? "Notification").toString();
      final body = (data["body"] ?? "").toString();
      if (onBanner != null) onBanner!(title, body);
    } else if (data is String) {
      // If backend sends string JSON, try decode
      try {
        final decoded = jsonDecode(data);
        if (decoded is Map<String, dynamic>) {
          final title = (decoded["title"] ?? "Notification").toString();
          final body = (decoded["body"] ?? "").toString();
          if (onBanner != null) onBanner!(title, body);
        }
      } catch (_) {}
    }
  }
}