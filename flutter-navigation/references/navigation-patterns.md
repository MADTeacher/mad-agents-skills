# Navigation Patterns

Use this reference to choose a navigation approach before editing app code.

## Approach Selection

### Navigator With MaterialPageRoute

Use for simple, local flows that do not need to be addressable by URL:

- opening a detail screen from a list in a small mobile app;
- selecting a value and returning it to the previous screen;
- modal-like flows that should not survive browser refresh or external links.

Example: `assets/navigator_basic.dart`

```dart
final result = await Navigator.of(context).push<String>(
  MaterialPageRoute<String>(
    builder: (context) => const SelectionScreen(),
  ),
);
if (!context.mounted) return;
```

### go_router

Use for route tables that need stable URLs or controlled page stacks:

- web apps with browser back, forward, refresh, and direct links;
- Android App Links, iOS Universal Links, or custom schemes;
- auth, onboarding, or feature redirects;
- nested navigation with persistent app shell;
- multiple Navigator branches;
- scalable route names and generated locations.

Example: `assets/go_router_basic.dart`

### Legacy MaterialApp.routes Named Routes

Avoid adding new legacy named routes for most apps. They can handle simple
static route names, but incoming deep links always push a new route and browser
forward support is limited. Preserve them only when maintaining a small existing
app with no custom deep-link or web-history requirements.

## Data Passing

### Constructor Data With Navigator

Use direct constructor arguments for local, in-memory data:

```dart
Navigator.push(
  context,
  MaterialPageRoute<void>(
    builder: (context) => DetailScreen(item: item),
  ),
);
```

Example: `assets/passing_data.dart`

### Path Parameters With go_router

Use path parameters for required identity:

```dart
GoRoute(
  path: '/users/:userId',
  builder: (context, state) {
    final userId = state.pathParameters['userId']!;
    return UserScreen(userId: userId);
  },
);

context.go('/users/42');
```

### Query Parameters With go_router

Use query parameters for optional URL state:

```dart
final location = Uri(
  path: '/search',
  queryParameters: {'q': 'flutter', 'tab': 'docs'},
).toString();

context.go(location);
```

Read them from `state.uri.queryParameters`:

```dart
final query = state.uri.queryParameters['q'] ?? '';
```

### Extra Data With go_router

Use `extra` only for data that is intentionally not addressable:

```dart
context.push('/details', extra: item);
```

Do not rely on `extra` for browser refresh, shared URLs, or native deep-link
entry.

## Returning Data

Navigator:

```dart
final result = await Navigator.push<String>(
  context,
  MaterialPageRoute<String>(builder: (context) => const SelectionScreen()),
);
if (!context.mounted) return;
```

go_router:

```dart
final result = await context.push<String>('/selection');
if (!context.mounted) return;
```

Return from the pushed route:

```dart
context.pop('selected-value');
```

Example: `assets/returning_data.dart`

## Deep Linking Behavior

| Requirement | Prefer |
|---|---|
| Direct URL opens a predictable page stack | `go_router` or Router API |
| App replaces current pages when a link is opened | `go_router` or Router API |
| Browser forward/back support | `go_router` or Router API |
| Very simple mobile-only stack | `Navigator` |
| Static legacy app route names | Existing `MaterialApp.routes`, with limitations |

When Router and imperative Navigator are mixed, pages pushed imperatively are
not deep-linkable and can be removed when the parent Router-backed page changes.

## Web-Specific Choices

Hash strategy works without server changes:

```text
https://example.com/#/details/42
```

Path strategy needs server rewrites but gives cleaner URLs:

```text
https://example.com/details/42
```

See [web-navigation.md](web-navigation.md) for setup and validation.
