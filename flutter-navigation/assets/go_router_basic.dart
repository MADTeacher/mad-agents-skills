import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

void main() {
  runApp(
    MaterialApp.router(
      title: 'Navigation with go_router',
      routerConfig: _router,
    ),
  );
}

final _router = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
    GoRoute(
      path: '/details',
      builder: (context, state) {
        final id = state.uri.queryParameters['id'] ?? 'default';
        return DetailsScreen(id: id);
      },
    ),
  ],
);

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: Center(
        child: ElevatedButton(
          child: const Text('Go to details'),
          onPressed: () {
            final location = Uri(
              path: '/details',
              queryParameters: {'id': '123'},
            ).toString();
            context.push(location);
          },
        ),
      ),
    );
  }
}

class DetailsScreen extends StatelessWidget {
  const DetailsScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Details: $id')),
      body: Center(
        child: ElevatedButton(
          child: const Text('Go back'),
          onPressed: () => context.pop(),
        ),
      ),
    );
  }
}
