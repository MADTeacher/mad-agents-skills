# go_router Guide

Use this reference when implementing, fixing, or reviewing `go_router` in a
Flutter app. Check the target app's installed `go_router` version before using a
newer API.

## Basic Setup

Add the dependency to `pubspec.yaml`:

```yaml
dependencies:
  go_router: ^17.2.2
```

Minimal configuration:

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

final router = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
    GoRoute(path: '/details', builder: (context, state) => const DetailsScreen()),
  ],
);

void main() {
  runApp(MaterialApp.router(routerConfig: router));
}
```

## Navigation APIs

Use URL locations for direct navigation:

```dart
context.go('/details'); // Replace the displayed route stack.
final result = await context.push<bool>('/picker'); // Push and wait for data.
if (!context.mounted) return;
```

Return a value:

```dart
context.pop(true);
```

Build URLs with query parameters using `Uri`:

```dart
final location = Uri(
  path: '/search',
  queryParameters: {'q': query, 'page': '$page'},
).toString();

context.go(location);
```

Do not call `context.push('/search', queryParameters: {...})`; `push` accepts a
location string and optional `extra`.

## Named Routes

Named routes are useful when paths should be generated from route names and
parameter maps.

```dart
GoRoute(
  name: 'user',
  path: '/users/:userId',
  builder: (context, state) {
    final userId = state.pathParameters['userId']!;
    return UserScreen(userId: userId);
  },
);

context.goNamed(
  'user',
  pathParameters: {'userId': '42'},
  queryParameters: {'tab': 'activity'},
);
```

Use `pushNamed` when the destination should be added to the stack:

```dart
final saved = await context.pushNamed<bool>(
  'editUser',
  pathParameters: {'userId': '42'},
);
```

## Reading Route Data

### Path Parameters

Use path parameters for required addressable identity:

```dart
GoRoute(
  path: '/projects/:projectId',
  builder: (context, state) {
    final projectId = state.pathParameters['projectId']!;
    return ProjectScreen(projectId: projectId);
  },
);
```

### Query Parameters

Use query parameters for optional, shareable route state:

```dart
GoRoute(
  path: '/search',
  builder: (context, state) {
    final query = state.uri.queryParameters['q'] ?? '';
    final page = int.tryParse(state.uri.queryParameters['page'] ?? '1') ?? 1;
    return SearchScreen(query: query, page: page);
  },
);
```

### Extra Data

Use `extra` only for data that does not need to survive refresh, restore,
sharing, or native deep-link entry.

```dart
context.push('/details', extra: item);

GoRoute(
  path: '/details',
  builder: (context, state) {
    final item = state.extra as Item?;
    return DetailsScreen(item: item);
  },
);
```

On web, complex `extra` data can be dropped during browser serialization unless
the router is configured with a suitable codec. Prefer path/query parameters for
addressable state.

## Shell Routes

Use `ShellRoute` for persistent UI around child routes:

```dart
ShellRoute(
  builder: (context, state, child) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: switch (state.uri.path) {
          final path when path.startsWith('/settings') => 1,
          _ => 0,
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.settings), label: 'Settings'),
        ],
        onDestinationSelected: (index) {
          context.go(index == 0 ? '/home' : '/settings');
        },
      ),
    );
  },
  routes: [
    GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
    GoRoute(path: '/settings', builder: (context, state) => const SettingsScreen()),
  ],
);
```

Use `StatefulShellRoute` when each tab or branch needs its own independent
navigation stack. Keep branch selection derived from the current route instead
of duplicating selected-index state.

## Redirects And Guards

Use redirects for login, onboarding, feature gates, or legacy URL migration.
Keep redirects deterministic and loop-free.

```dart
GoRouter(
  redirect: (context, state) {
    final signedIn = AuthScope.of(context).isSignedIn;
    final loggingIn = state.matchedLocation == '/login';

    if (!signedIn && !loggingIn) {
      final from = Uri.encodeComponent(state.uri.toString());
      return '/login?from=$from';
    }

    if (signedIn && loggingIn) {
      return state.uri.queryParameters['from'] ?? '/';
    }

    return null;
  },
  routes: [
    // ...
  ],
);
```

For newer `go_router` versions, `onEnter` can block navigation before redirects.
Prefer it only when the installed version and app architecture justify that
extra control.

## Error Handling

Add an explicit not-found or error surface for bad URLs:

```dart
GoRouter(
  errorBuilder: (context, state) => NotFoundScreen(error: state.error),
  routes: [
    // ...
  ],
);
```

Validate path and query parameters inside route builders. If a parameter cannot
be parsed, show a route error screen or redirect to a safe canonical location.

## Common Pitfalls

1. Mixing `Navigator.push` with main `go_router` routes makes browser and
   deep-link behavior harder to reason about.
2. `context.push` is imperative and can interact awkwardly with browser history.
   Use `context.go` for canonical URL state.
3. Query params are read from `state.uri.queryParameters`, not
   `state.queryParameters`.
4. `context.go` and `context.push` take a location string plus optional `extra`;
   build query strings with `Uri` or use named-route APIs.
5. Do not rely on `extra` for data that must survive browser refresh or native
   deep links.
6. Preserve intended destinations across auth redirects.
7. Test shell routes for selected destination, back behavior, and independent
   branch stacks when using `StatefulShellRoute`.
