# HTTP Basics

## Overview

Complete guide for HTTP operations in Flutter using the `http` package.

## Dependencies

Add to `pubspec.yaml`:

```yaml
dependencies:
  http: ^1.6.0
```

## GET Requests

### Basic GET Request

```dart
import 'package:http/http.dart' as http;
import 'dart:convert';

Future<Album> fetchAlbum(int id) async {
  final response = await http.get(
    Uri.parse('https://jsonplaceholder.typicode.com/albums/$id'),
  );

  if (response.statusCode == 200) {
    return Album.fromJson(jsonDecode(response.body));
  } else {
    throw Exception('Failed to load album');
  }
}
```

### GET with Query Parameters

```dart
final response = await http.get(
  Uri.parse('https://api.example.com/albums')
      .replace(queryParameters: {
    'userId': '1',
    '_limit': '10',
  }),
);
```

### GET with Custom Headers

```dart
final response = await http.get(
  Uri.parse('https://api.example.com/data'),
  headers: {
    'Accept': 'application/json',
    'User-Agent': 'MyApp/1.0',
  },
);
```

## POST Requests

### Create Resource

```dart
Future<Album> createAlbum(String title) async {
  final response = await http.post(
    Uri.parse('https://jsonplaceholder.typicode.com/albums'),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: jsonEncode(<String, String>{'title': title}),
  );

  if (response.statusCode == 201) {
    return Album.fromJson(jsonDecode(response.body));
  } else {
    throw Exception('Failed to create album');
  }
}
```

### POST with Complex Object

```dart
Future<User> createUser(User user) async {
  final response = await http.post(
    Uri.parse('https://api.example.com/users'),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: jsonEncode(user.toJson()),
  );

  if (response.statusCode == 201) {
    return User.fromJson(jsonDecode(response.body));
  } else {
    throw Exception('Failed to create user');
  }
}
```

## PUT Requests

### Update Entire Resource

```dart
Future<Album> updateAlbum(int id, String title) async {
  final response = await http.put(
    Uri.parse('https://jsonplaceholder.typicode.com/albums/$id'),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: jsonEncode(<String, String>{'title': title, 'id': id.toString()}),
  );

  if (response.statusCode == 200) {
    return Album.fromJson(jsonDecode(response.body));
  } else {
    throw Exception('Failed to update album');
  }
}
```

## DELETE Requests

### Delete Resource

```dart
Future<Album> deleteAlbum(String id) async {
  final http.Response response = await http.delete(
    Uri.parse('https://jsonplaceholder.typicode.com/albums/$id'),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
  );

  if (response.statusCode == 200) {
    return Album.fromJson(jsonDecode(response.body));
  } else {
    throw Exception('Failed to delete album');
  }
}
```

## Model Classes

### JSON Parsing Pattern

```dart
class Album {
  final int userId;
  final int id;
  final String title;

  const Album({
    required this.userId,
    required this.id,
    required this.title,
  });

  factory Album.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {'userId': int userId, 'id': int id, 'title': String title} => Album(
        userId: userId,
        id: id,
        title: title,
      ),
      _ => throw const FormatException('Failed to load album.'),
    };
  }

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'id': id,
    'title': title,
  };
}
```

### Nested JSON Parsing

```dart
class User {
  final int id;
  final String name;
  final Address address;

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      name: json['name'] as String,
      address: Address.fromJson(json['address'] as Map<String, dynamic>),
    );
  }
}

class Address {
  final String street;
  final String city;

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      street: json['street'] as String,
      city: json['city'] as String,
    );
  }
}
```

## List Parsing

```dart
Future<List<Album>> fetchAlbums() async {
  final response = await http.get(
    Uri.parse('https://jsonplaceholder.typicode.com/albums'),
  );

  if (response.statusCode == 200) {
    final List<dynamic> data = jsonDecode(response.body);
    return data.map((json) => Album.fromJson(json)).toList();
  } else {
    throw Exception('Failed to load albums');
  }
}
```

## Using with FutureBuilder

```dart
class _MyAppState extends State<MyApp> {
  late Future<Album> futureAlbum;

  @override
  void initState() {
    super.initState();
    futureAlbum = fetchAlbum(1);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Album>(
      future: futureAlbum,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else if (snapshot.hasData) {
          return Text(snapshot.data!.title);
        } else {
          return const Text('No data');
        }
      },
    );
  }
}
```

## Timeout Configuration

```dart
import 'dart:async';

Future<Album> fetchAlbum() async {
  try {
    final response = await http.get(
      Uri.parse('https://api.example.com/albums/1'),
    ).timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        throw TimeoutException('Request timeout');
      },
    );

    if (response.statusCode == 200) {
      return Album.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    }

    throw ApiHttpException.fromResponse(response);
  } on TimeoutException catch (e) {
    throw ApiTimeoutException('Request timed out: ${e.message}');
  }
}
```

## Common Response Headers

```dart
final contentType = response.headers['content-type'];
final contentLength = int.parse(response.headers['content-length'] ?? '0');
final cacheControl = response.headers['cache-control'];
```

## Best Practices

1. **Always handle status codes** - Check response.statusCode before processing
2. **Use type-safe models** - Create classes with fromJson/toJson methods
3. **Set timeouts** - Prevent indefinite hanging requests
4. **Handle exceptions** - Catch and properly handle network errors
5. **Use appropriate HTTP methods** - GET for reading, POST for creating, PUT for updating, DELETE for removing
