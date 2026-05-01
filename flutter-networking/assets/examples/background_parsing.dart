import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class Photo {
  final int albumId;
  final int id;
  final String title;
  final String url;
  final String thumbnailUrl;

  const Photo({
    required this.albumId,
    required this.id,
    required this.title,
    required this.url,
    required this.thumbnailUrl,
  });

  factory Photo.fromJson(Map<String, dynamic> json) {
    return Photo(
      albumId: json['albumId'] as int,
      id: json['id'] as int,
      title: json['title'] as String,
      url: json['url'] as String,
      thumbnailUrl: json['thumbnailUrl'] as String,
    );
  }
}

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

class BackgroundParsingExample extends StatefulWidget {
  const BackgroundParsingExample({super.key});

  @override
  State<BackgroundParsingExample> createState() =>
      _BackgroundParsingExampleState();
}

class _BackgroundParsingExampleState extends State<BackgroundParsingExample> {
  late final http.Client _client;
  late Future<List<Photo>> futurePhotos;

  @override
  void initState() {
    super.initState();
    _client = http.Client();
    futurePhotos = fetchPhotos(_client);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Background Parsing Example'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                futurePhotos = fetchPhotos(_client);
              });
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Photo>>(
        future: futurePhotos,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                ],
              ),
            );
          } else if (snapshot.hasData) {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final photo = snapshot.data![index];
                return ListTile(
                  leading: Image.network(
                    photo.thumbnailUrl,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                  title: Text('Photo ${photo.id}'),
                  subtitle: Text(photo.title),
                );
              },
            );
          }
          return const SizedBox();
        },
      ),
    );
  }

  @override
  void dispose() {
    _client.close();
    super.dispose();
  }
}
