# WebSockets

## Overview

Complete guide for implementing WebSocket connections in Flutter using the `web_socket_channel` package.

## Dependencies

Add to `pubspec.yaml`:

```yaml
dependencies:
  web_socket_channel: ^3.0.3
```

## Basic Connection

### Connecting to WebSocket

```dart
import 'package:web_socket_channel/web_socket_channel.dart';

final _channel = WebSocketChannel.connect(
  Uri.parse('wss://echo.websocket.events'),
);
```

### Sending Messages

```dart
void _sendMessage(String message) {
  if (message.isNotEmpty) {
    _channel.sink.add(message);
  }
}
```

### Receiving Messages with StreamBuilder

```dart
StreamBuilder(
  stream: _channel.stream,
  builder: (context, snapshot) {
    return Text(snapshot.hasData ? '${snapshot.data}' : '');
  },
)
```

### Closing Connection

```dart
@override
void dispose() {
  _channel.sink.close();
  super.dispose();
}
```

## Complete Example

```dart
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketDemo extends StatefulWidget {
  const WebSocketDemo({super.key});

  @override
  State<WebSocketDemo> createState() => _WebSocketDemoState();
}

class _WebSocketDemoState extends State<WebSocketDemo> {
  final TextEditingController _controller = TextEditingController();
  final _channel = WebSocketChannel.connect(
    Uri.parse('wss://echo.websocket.events'),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('WebSocket Demo')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Form(
              child: TextFormField(
                controller: _controller,
                decoration: const InputDecoration(labelText: 'Send a message'),
              ),
            ),
            const SizedBox(height: 24),
            StreamBuilder(
              stream: _channel.stream,
              builder: (context, snapshot) {
                return Text(snapshot.hasData ? '${snapshot.data}' : '');
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _sendMessage(_controller.text),
        tooltip: 'Send message',
        child: const Icon(Icons.send),
      ),
    );
  }

  void _sendMessage(String message) {
    if (message.isNotEmpty) {
      _channel.sink.add(message);
    }
  }

  @override
  void dispose() {
    _channel.sink.close();
    _controller.dispose();
    super.dispose();
  }
}
```

## Connection States

### Handling Connection States

```dart
import 'dart:async';

enum SocketConnectionStatus { connecting, connected, disconnected, error }

class _WebSocketDemoState extends State<WebSocketDemo> {
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  SocketConnectionStatus _connectionStatus = SocketConnectionStatus.connecting;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _connect();
  }

  void _connect() {
    try {
      final channel = WebSocketChannel.connect(Uri.parse('wss://example.com/ws'));

      _subscription = channel.stream.listen(
        (data) {
          if (!mounted) return;
          setState(() {
            _connectionStatus = SocketConnectionStatus.connected;
          });
        },
        onError: (error) {
          if (!mounted) return;
          setState(() {
            _connectionStatus = SocketConnectionStatus.error;
            _errorMessage = error.toString();
          });
        },
        onDone: () {
          if (!mounted) return;
          setState(() {
            _connectionStatus = SocketConnectionStatus.disconnected;
          });
        },
      );

      _channel = channel;
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _connectionStatus = SocketConnectionStatus.error;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _channel?.sink.close();
    super.dispose();
  }
}
```

## Reconnection Logic

### Automatic Reconnection

```dart
class _WebSocketDemoState extends State<WebSocketDemo> {
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;

  void _connect() {
    try {
      _channel = WebSocketChannel.connect(Uri.parse('wss://example.com/ws'));

      _subscription?.cancel();
      _subscription = _channel!.stream.listen(
        (data) {
          _reconnectAttempts = 0;
        },
        onError: (error) {
          _scheduleReconnect();
        },
        onDone: () {
          _scheduleReconnect();
        },
      );
    } catch (e) {
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    if (!mounted) return;
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      return;
    }

    _reconnectAttempts++;
    final delay = Duration(seconds: _reconnectAttempts * 2);

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () {
      if (!mounted) return;
      _connect();
    });
  }

  @override
  void dispose() {
    _reconnectTimer?.cancel();
    _subscription?.cancel();
    _channel?.sink.close();
    super.dispose();
  }
}
```

## JSON Messages

### Sending JSON Data

```dart
import 'dart:convert';

void _sendJsonMessage(Map<String, dynamic> data) {
  _channel.sink.add(jsonEncode(data));
}

// Usage
_sendJsonMessage({
  'type': 'chat',
  'message': 'Hello, world!',
  'userId': 123,
});
```

### Receiving JSON Data

```dart
StreamBuilder(
  stream: _channel.stream,
  builder: (context, snapshot) {
    if (!snapshot.hasData) {
      return const CircularProgressIndicator();
    }

    try {
      final data = jsonDecode(snapshot.data as String) as Map<String, dynamic>;
      return Text('Message: ${data['message']}');
    } catch (e) {
      return Text('Error parsing JSON: $e');
    }
  },
)
```

### Type-Safe Message Handling

```dart
abstract class WebSocketMessage {
  factory WebSocketMessage.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;
    switch (type) {
      case 'chat':
        return ChatMessage.fromJson(json);
      case 'notification':
        return NotificationMessage.fromJson(json);
      default:
        throw FormatException('Unknown message type: $type');
    }
  }
}

class ChatMessage extends WebSocketMessage {
  final String message;
  final int userId;

  ChatMessage({required this.message, required this.userId});

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      message: json['message'] as String,
      userId: json['userId'] as int,
    );
  }
}

StreamBuilder(
  stream: _channel.stream,
  builder: (context, snapshot) {
    if (!snapshot.hasData) return const SizedBox();

    try {
      final message = WebSocketMessage.fromJson(
        jsonDecode(snapshot.data as String) as Map<String, dynamic>,
      );

      if (message is ChatMessage) {
        return ChatBubble(message: message.message);
      }
    } catch (e) {
      return Text('Error: $e');
    }

    return const SizedBox();
  },
)
```

## Authentication

### Connecting with Auth Token

```dart
void _connectWithToken(String token) {
  final uri = Uri.parse('wss://example.com/ws').replace(
    queryParameters: {'token': token},
  );

  _channel = WebSocketChannel.connect(uri);
}
```

### Sending Auth Header

`IOWebSocketChannel` works on IO platforms only. For Flutter web, use query
parameters, cookies, or an application-level auth message after connecting,
depending on the backend contract.

```dart
import 'package:web_socket_channel/io.dart';

void _connectWithHeaders(String token) {
  final channel = IOWebSocketChannel.connect(
    'wss://example.com/ws',
    headers: {
      'Authorization': 'Bearer $token',
      'X-Client-ID': 'my-app',
    },
  );

  _channel = channel;
}
```

## Multiple Channels

### Managing Multiple Connections

```dart
class WebSocketManager {
  final Map<String, WebSocketChannel> _channels = {};

  void connect(String channelId, String url) {
    if (_channels.containsKey(channelId)) {
      _channels[channelId]?.sink.close();
    }

    _channels[channelId] = WebSocketChannel.connect(Uri.parse(url));
  }

  void send(String channelId, String message) {
    _channels[channelId]?.sink.add(message);
  }

  Stream<dynamic> getStream(String channelId) {
    return _channels[channelId]!.stream;
  }

  void close(String channelId) {
    _channels[channelId]?.sink.close();
    _channels.remove(channelId);
  }

  void closeAll() {
    _channels.forEach((key, channel) => channel.sink.close());
    _channels.clear();
  }
}
```

## Error Handling

### Handling WebSocket Errors

```dart
channel.stream.listen(
  (data) {
    print('Received: $data');
  },
  onError: (error) {
    print('WebSocket error: $error');
  },
  onDone: () {
    print('WebSocket connection closed');
  },
  cancelOnError: false,
);
```

## Best Practices

1. **Always close connections** - Dispose WebSocket in dispose() method
2. **Handle connection states** - Track connecting, connected, disconnected states
3. **Implement reconnection** - Add automatic reconnection with exponential backoff
4. **Validate incoming data** - Parse and validate JSON messages
5. **Use type-safe models** - Create message classes for different message types
6. **Secure connections** - Use wss:// (WebSocket Secure) instead of ws://
7. **Handle network changes** - Reconnect on network state changes
8. **Limit message size** - Validate and limit incoming message sizes
