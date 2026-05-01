# Performance

## Overview

Complete guide for optimizing Flutter networking performance.

## Background Parsing with Isolates

### Using compute() for JSON Parsing

For large JSON responses, parse in a background isolate to prevent UI jank:

```yaml
dependencies:
  http: ^1.6.0
```

```dart
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

Future<List<Photo>> fetchPhotos(http.Client client) async {
  final response = await client.get(
    Uri.parse('https://jsonplaceholder.typicode.com/photos'),
  );

  if (response.statusCode == 200) {
    return compute(parsePhotos, response.body);
  } else {
    throw Exception('Failed to load photos');
  }
}

List<Photo> parsePhotos(String responseBody) {
  final parsed = (jsonDecode(responseBody) as List)
      .cast<Map<String, dynamic>>();

  return parsed.map<Photo>((json) => Photo.fromJson(json)).toList();
}
```

### When to Use compute()

Use `compute()` when:
- JSON response is larger than 10KB
- Parsing takes more than 10ms
- UI jank is noticeable during parsing

Don't use for:
- Small responses (<1KB)
- Simple objects with few fields
- When response speed is critical (isolate overhead)

## Caching

### In-Memory Cache

```dart
class CacheService<T> {
  final Map<String, CacheEntry<T>> _cache = {};
  final Duration defaultTtl;

  CacheService({this.defaultTtl = const Duration(minutes: 5)});

  Future<T?> get(String key) async {
    final entry = _cache[key];
    if (entry == null) return null;

    if (DateTime.now().isAfter(entry.expiry)) {
      _cache.remove(key);
      return null;
    }

    return entry.value;
  }

  Future<void> set(String key, T value, {Duration? ttl}) async {
    _cache[key] = CacheEntry(
      value: value,
      expiry: DateTime.now().add(ttl ?? defaultTtl),
    );
  }

  Future<void> clear() async {
    _cache.clear();
  }
}

class CacheEntry<T> {
  final T value;
  final DateTime expiry;

  CacheEntry({required this.value, required this.expiry});
}
```

### HTTP Cache Headers

Respect server cache directives:

```dart
Future<Album> fetchAlbum(int id) async {
  final response = await http.get(
    Uri.parse('https://api.example.com/albums/$id'),
  );

  final cacheControl = response.headers['cache-control'];
  if (cacheControl != null) {
    // Parse and respect cache headers
  }

  return Album.fromJson(jsonDecode(response.body));
}
```

## Request Batching

### Batching Multiple Requests

```dart
Future<List<Album>> fetchAlbumsBatch(List<int> ids) async {
  final futures = ids.map((id) => fetchAlbum(id));
  return await Future.wait(futures);
}

// Usage
final albums = await fetchAlbumsBatch([1, 2, 3, 4, 5]);
```

### Request Deduplication

```dart
class RequestDeduplicator<T> {
  final Map<String, Future<T>> _pendingRequests = {};

  Future<T> fetch(String key, Future<T> Function() fetchFn) async {
    if (_pendingRequests.containsKey(key)) {
      return await _pendingRequests[key]!;
    }

    final future = fetchFn();
    _pendingRequests[key] = future;

    try {
      return await future;
    } finally {
      _pendingRequests.remove(key);
    }
  }
}

// Usage
final deduplicator = RequestDeduplicator<Album>();

final album1 = await deduplicator.fetch(
  'album-1',
  () => fetchAlbum(1),
);

final album2 = await deduplicator.fetch(
  'album-1', // Same key - won't make duplicate request
  () => fetchAlbum(1),
);
```

## Pagination

### Offset-Based Pagination

```dart
Future<List<Album>> fetchAlbumsPage({
  int offset = 0,
  int limit = 20,
}) async {
  final response = await http.get(
    Uri.parse('https://api.example.com/albums')
        .replace(queryParameters: {
      'offset': offset.toString(),
      'limit': limit.toString(),
    }),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body) as List;
    return data.map((json) => Album.fromJson(json)).toList();
  } else {
    throw Exception('Failed to load albums');
  }
}
```

### Cursor-Based Pagination

```dart
Future<PageResult<Album>> fetchAlbumsPage({
  String? cursor,
  int limit = 20,
}) async {
  final uri = Uri.parse('https://api.example.com/albums')
      .replace(queryParameters: {
    'limit': limit.toString(),
    if (cursor != null) 'cursor': cursor,
  });

  final response = await http.get(uri);

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return PageResult(
      items: (data['items'] as List)
          .map((json) => Album.fromJson(json))
          .toList(),
      nextCursor: data['nextCursor'] as String?,
    );
  } else {
    throw Exception('Failed to load albums');
  }
}

class PageResult<T> {
  final List<T> items;
  final String? nextCursor;

  PageResult({required this.items, required this.nextCursor});
}
```

## Compression

`package:http` and the underlying platform clients normally negotiate
compression for you. Do not set `Accept-Encoding` by default unless the app has
a measured interoperability need and the chosen client stack supports the header
on the target platforms.

## Connection Pooling

### Reuse HTTP Client

Create a single HTTP client instance for the app:

```dart
class SharedApiClient {
  static final SharedApiClient _instance = SharedApiClient._internal();
  factory SharedApiClient() => _instance;

  final http.Client _client = http.Client();

  SharedApiClient._internal();

  http.Client get client => _client;

  void dispose() {
    _client.close();
  }
}

// Usage
final apiClient = SharedApiClient();
final response = await apiClient.client.get(url);
```

## Optimistic UI

### Optimistic Updates

```dart
class AlbumRepository {
  final CacheService<Album> _cache;

  Future<Album> updateAlbum(int id, String title) async {
    // Optimistic update
    final cachedAlbum = await _cache.get('album-$id');
    final updatedAlbum = Album(
      userId: cachedAlbum!.userId,
      id: cachedAlbum.id,
      title: title,
    );
    await _cache.set('album-$id', updatedAlbum);

    try {
      final networkAlbum = await _updateAlbumOnServer(id, title);
      await _cache.set('album-$id', networkAlbum);
      return networkAlbum;
    } catch (e) {
      // Revert on error
      await _cache.set('album-$id', cachedAlbum);
      rethrow;
    }
  }

  Future<Album> _updateAlbumOnServer(int id, String title) async {
    final response = await http.put(
      Uri.parse('https://api.example.com/albums/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'title': title}),
    );

    if (response.statusCode == 200) {
      return Album.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to update album');
    }
  }
}
```

## Lazy Loading

### Lazy Load Images

```dart
class NetworkImageLoader {
  static const int _maxCacheSize = 100;
  static final Map<String, Uint8List> _imageCache = {};

  static Future<Uint8List> loadImage(String url) async {
    if (_imageCache.containsKey(url)) {
      return _imageCache[url]!;
    }

    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw ApiHttpException.fromResponse(response);
    }

    final bytes = response.bodyBytes;

    if (_imageCache.length >= _maxCacheSize) {
      _imageCache.clear();
    }

    _imageCache[url] = bytes;
    return bytes;
  }
}
```

## Performance Monitoring

### Request Timing

```dart
class RequestTimer {
  Future<T> timeRequest<T>(String name, Future<T> Function() request) async {
    final stopwatch = Stopwatch()..start();

    try {
      return await request();
    } finally {
      stopwatch.stop();
      debugPrint('$name took ${stopwatch.elapsedMilliseconds}ms');
    }
  }
}

// Usage
final timer = RequestTimer();
final album = await timer.timeRequest('fetchAlbum', () => fetchAlbum(1));
```

## Best Practices

1. **Use compute() for large JSON** - Parse large responses in isolates
2. **Implement caching** - Reduce network requests with in-memory cache
3. **Batch requests** - Combine multiple requests when possible
4. **Deduplicate requests** - Avoid duplicate in-flight requests
5. **Use pagination** - Load data in chunks for large datasets
6. **Enable compression** - Use gzip for request/response compression
7. **Reuse HTTP client** - Create single client instance for app
8. **Optimistic UI** - Update UI immediately, rollback on error
9. **Lazy load resources** - Load images and resources on demand
10. **Monitor performance** - Track request times for optimization
