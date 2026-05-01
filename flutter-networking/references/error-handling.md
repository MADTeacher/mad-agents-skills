# Error Handling

## Overview

Complete guide for handling errors in Flutter networking operations.

## HTTP Status Code Handling

### Standard Status Codes

```dart
Future<Album> fetchAlbum(int id) async {
  final response = await http.get(
    Uri.parse('https://api.example.com/albums/$id'),
  );

  switch (response.statusCode) {
    case 200:
    case 201:
      return Album.fromJson(jsonDecode(response.body));

    case 204:
      throw JsonParseException('Expected album body, got empty response');

    case 400:
      throw BadRequestException('Invalid request');

    case 401:
      throw UnauthorizedException('Not authenticated');

    case 403:
      throw ForbiddenException('Access denied');

    case 404:
      throw NotFoundException('Album not found');

    case 429:
      throw TooManyRequestsException('Rate limit exceeded');

    case 500:
    case 502:
    case 503:
      throw ServerException('Server error');

    default:
      throw HttpException(
        'HTTP ${response.statusCode}: ${response.reasonPhrase}',
      );
  }
}
```

## Custom Exception Classes

### Base Exception Classes

```dart
abstract class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

class BadRequestException extends ApiException {
  BadRequestException(String message) : super(message, 400);
}

class UnauthorizedException extends ApiException {
  UnauthorizedException(String message) : super(message, 401);
}

class ForbiddenException extends ApiException {
  ForbiddenException(String message) : super(message, 403);
}

class NotFoundException extends ApiException {
  NotFoundException(String message) : super(message, 404);
}

class TooManyRequestsException extends ApiException {
  TooManyRequestsException(String message) : super(message, 429);
}

class ServerException extends ApiException {
  ServerException(String message) : super(message, 500);
}

class NetworkException extends ApiException {
  NetworkException(String message) : super(message);
}

class ApiTimeoutException extends ApiException {
  ApiTimeoutException(String message) : super(message);
}
```

## Parsing Errors

### JSON Parsing with Error Handling

```dart
class Album {
  final int userId;
  final int id;
  final String title;

  Album({required this.userId, required this.id, required this.title});

  factory Album.fromJson(Map<String, dynamic> json) {
    try {
      return Album(
        userId: json['userId'] as int,
        id: json['id'] as int,
        title: json['title'] as String,
      );
    } on TypeError catch (e) {
      throw JsonParseException('Failed to parse album: $e');
    } catch (e) {
      throw JsonParseException('Unknown parsing error: $e');
    }
  }
}

class JsonParseException extends ApiException {
  JsonParseException(String message) : super(message);
}
```

### Safe JSON Parsing

```dart
class SafeParser {
  static String? parseString(Map<String, dynamic> json, String key) {
    try {
      return json[key] as String?;
    } catch (_) {
      return null;
    }
  }

  static int? parseInt(Map<String, dynamic> json, String key) {
    try {
      return json[key] as int?;
    } catch (_) {
      return null;
    }
  }

  static double? parseDouble(Map<String, dynamic> json, String key) {
    try {
      return json[key] as double?;
    } catch (_) {
      return null;
    }
  }
}

// Usage
factory User.fromJson(Map<String, dynamic> json) {
  return User(
    name: SafeParser.parseString(json, 'name') ?? 'Unknown',
    age: SafeParser.parseInt(json, 'age') ?? 0,
    score: SafeParser.parseDouble(json, 'score') ?? 0.0,
  );
}
```

## Network Error Handling

### Timeout Handling

```dart
import 'dart:async';

Future<T> withTimeout<T>(Future<T> future, Duration duration) async {
  try {
    return await future.timeout(
      duration,
      onTimeout: () {
        throw ApiTimeoutException(
          'Request timed out after ${duration.inSeconds}s',
        );
      },
    );
  } on TimeoutException catch (e) {
    throw ApiTimeoutException(e.message ?? 'Request timed out');
  }
}

// Usage
final response = await withTimeout(
  http.get(Uri.parse('https://api.example.com/data')),
  const Duration(seconds: 10),
);
```

### Connection Errors

```dart
Future<T> withConnectionHandling<T>(Future<T> future) async {
  try {
    return await future;
  } on SocketException catch (e) {
    throw NetworkException('No internet connection: ${e.message}');
  } on HttpException catch (e) {
    throw NetworkException('HTTP error: ${e.message}');
  } on FormatException catch (e) {
    throw NetworkException('Invalid response format: ${e.message}');
  } catch (e) {
    throw NetworkException('Unknown network error: $e');
  }
}
```

## Error Display in UI

### Error Widget

```dart
class ErrorDisplay extends StatelessWidget {
  final Object error;
  final VoidCallback? onRetry;

  const ErrorDisplay({
    super.key,
    required this.error,
    this.onRetry,
  });

  String get _errorMessage {
    if (error is NetworkException) {
      return 'Network error. Please check your connection.';
    } else if (error is UnauthorizedException) {
      return 'You are not authorized. Please log in.';
    } else if (error is NotFoundException) {
      return 'The requested resource was not found.';
    } else if (error is ServerException) {
      return 'Server error. Please try again later.';
    } else if (error is ApiTimeoutException) {
      return 'Request timed out. Please try again.';
    } else {
      return 'An error occurred: $error';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
```

### FutureBuilder with Error Handling

```dart
FutureBuilder<Album>(
  future: futureAlbum,
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    }

    if (snapshot.hasError) {
      return ErrorDisplay(
        error: snapshot.error!,
        onRetry: () {
          setState(() {
            futureAlbum = fetchAlbum();
          });
        },
      );
    }

    if (snapshot.hasData) {
      return AlbumCard(album: snapshot.data!);
    }

    return const SizedBox();
  },
)
```

## Retry Logic

### Exponential Backoff

```dart
Future<T> fetchWithRetry<T>(
  Future<T> Function() fetch, {
  int maxRetries = 3,
  Duration initialDelay = const Duration(seconds: 1),
}) async {
  for (int i = 0; i < maxRetries; i++) {
    try {
      return await fetch();
    } catch (e) {
      if (i == maxRetries - 1) rethrow;

      if (!_isRetryableError(e)) rethrow;

      final delay = initialDelay * (i + 1);
      await Future.delayed(delay);
    }
  }

  throw StateError('Unreachable');
}

bool _isRetryableError(Object error) {
  return error is NetworkException ||
      error is ApiTimeoutException ||
      error is ServerException ||
      error is TooManyRequestsException;
}
```

### Retry on Specific Status Codes

```dart
Future<Album> fetchAlbumWithRetry(int id) async {
  return await fetchWithRetry(
    () => fetchAlbum(id),
    maxRetries: 3,
  );
}
```

## Error Logging

### Error Logger

```dart
class ErrorLogger {
  static void logError(Object error, StackTrace? stackTrace) {
    debugPrint('Error: $error');
    if (stackTrace != null) {
      debugPrint('StackTrace: $stackTrace');
    }

    // Send to error tracking service
    // AnalyticsService.logError(error, stackTrace);
  }
}

// Usage
try {
  await fetchAlbum();
} catch (e, stackTrace) {
  ErrorLogger.logError(e, stackTrace);
}
```

## Best Practices

1. **Handle all status codes** - Don't assume 200 is the only success code
2. **Use specific exception types** - Create custom exceptions for different error types
3. **Parse JSON safely** - Handle type errors gracefully
4. **Implement retry logic** - Retry transient failures with exponential backoff
5. **Set timeouts** - Prevent indefinite hanging requests
6. **Display user-friendly messages** - Show clear error messages in the UI
7. **Log errors** - Track errors for debugging and monitoring
8. **Provide retry options** - Allow users to retry failed operations
