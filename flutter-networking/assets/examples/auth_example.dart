import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class Album {
  final int userId;
  final int id;
  final String title;

  const Album({required this.userId, required this.id, required this.title});

  factory Album.fromJson(Map<String, dynamic> json) {
    return Album(
      userId: json['userId'] as int,
      id: json['id'] as int,
      title: json['title'] as String,
    );
  }
}

Future<Album> fetchAlbum(String token, int id) async {
  final response = await http.get(
    Uri.parse('https://jsonplaceholder.typicode.com/albums/$id'),
    headers: {'Authorization': 'Bearer $token'},
  );

  if (response.statusCode == 200) {
    return Album.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  } else if (response.statusCode == 401) {
    throw UnauthorizedException();
  } else {
    throw Exception('Failed to load album');
  }
}

class UnauthorizedException implements Exception {
  @override
  String toString() => 'Unauthorized: Please log in';
}

class AuthExample extends StatefulWidget {
  const AuthExample({super.key});

  @override
  State<AuthExample> createState() => _AuthExampleState();
}

class _AuthExampleState extends State<AuthExample> {
  final TextEditingController _tokenController = TextEditingController();
  late Future<Album> futureAlbum;

  @override
  void initState() {
    super.initState();
    futureAlbum = Future<Album>.error('Please enter a token');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Authenticated Request Example')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _tokenController,
              decoration: const InputDecoration(
                labelText: 'Enter Bearer Token',
                hintText: 'your_api_token_here',
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  futureAlbum = fetchAlbum(_tokenController.text, 1);
                });
              },
              child: const Text('Fetch with Auth'),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: FutureBuilder<Album>(
                future: futureAlbum,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error: ${snapshot.error}',
                        textAlign: TextAlign.center,
                      ),
                    );
                  } else if (snapshot.hasData) {
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Album ID: ${snapshot.data!.id}'),
                            const SizedBox(height: 8),
                            Text('Title: ${snapshot.data!.title}'),
                          ],
                        ),
                      ),
                    );
                  }
                  return const SizedBox();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }
}
