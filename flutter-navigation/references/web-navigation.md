# Web Navigation

Use this reference when fixing Flutter web URLs, browser history, refresh/direct
load behavior, server rewrites, or non-root hosting.

## URL Strategies

Flutter web supports two URL strategies:

### Hash Strategy

```text
https://example.com/#/path/to/screen
```

Use it when you cannot configure the web server. Hash URLs avoid server rewrites
because the route after `#` is not sent to the server.

### Path Strategy

```text
https://example.com/path/to/screen
```

Use it when you control server rewrites and want clean, shareable paths.

```dart
import 'package:flutter_web_plugins/url_strategy.dart';

void main() {
  usePathUrlStrategy();
  runApp(const App());
}
```

`flutter_web_plugins` is an SDK dependency:

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_web_plugins:
    sdk: flutter
```

Call `usePathUrlStrategy()` before `runApp()`.

## Server Rewrites

Path strategy uses the browser History API. Configure the server to serve
`index.html` for app routes that are not real files.

### Nginx

```nginx
location / {
  try_files $uri $uri/ /index.html;
}
```

### Apache

```apache
<IfModule mod_rewrite.c>
  RewriteEngine On
  RewriteBase /
  RewriteRule ^index\.html$ - [L]
  RewriteCond %{REQUEST_FILENAME} !-f
  RewriteCond %{REQUEST_FILENAME} !-d
  RewriteRule . /index.html [L]
</IfModule>
```

### Firebase Hosting

```json
{
  "hosting": {
    "public": "build/web",
    "rewrites": [
      { "source": "**", "destination": "/index.html" }
    ]
  }
}
```

### Vercel

```json
{
  "rewrites": [
    { "source": "/(.*)", "destination": "/index.html" }
  ]
}
```

### Netlify

```text
/* /index.html 200
```

## Browser History

Router-based navigation, including `go_router`, integrates with the browser URL
and History API for direct loads, refresh, back, and forward behavior.

Prefer canonical route state with `context.go(location)` for browser-visible
navigation. `context.push(location)` is useful for page-stack style flows, but
imperative navigation can be harder to reason about in browser history.

Build locations with query parameters using `Uri`:

```dart
context.go(
  Uri(
    path: '/search',
    queryParameters: {'q': query},
  ).toString(),
);
```

## Hosting At A Non-Root Path

If the app is hosted at `https://example.com/myapp/`, update the base href in
`web/index.html`:

```html
<base href="/myapp/">
```

Keep app route paths app-relative unless the target project already includes the
deployment prefix in routes:

```dart
GoRouter(
  routes: [
    GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
    GoRoute(path: '/details/:id', builder: (context, state) => const DetailsScreen()),
  ],
);
```

Configure the hosting server so `/myapp/details/42` rewrites to the built
`index.html` for that deployed app.

## Not Found And Error Routes

For public web URLs, define a deliberate not-found or error surface:

```dart
GoRouter(
  errorBuilder: (context, state) => NotFoundScreen(error: state.error),
  routes: [
    // ...
  ],
);
```

Validate bad routes and malformed parameters. Do not let a bad URL crash during
`int.parse`, forced casts, or missing path parameter access.

## Web Validation

When feasible, run the app in Chrome and test:

- direct load of `/`;
- direct load of every changed route;
- refresh on every changed route;
- browser back and forward;
- query parameter preservation;
- unknown URL and malformed parameter behavior;
- deployed non-root path if applicable.

For production hosts, test after deployment as well as on the Flutter dev
server. The dev server handles fallback routing automatically, while production
hosting only works if rewrites are configured.

## Accessibility And Titles

Navigation changes can affect focus, page announcements, and keyboard flow.
After route changes, check that keyboard users can reach primary actions and
that screen names, app bars, or semantic labels make the destination clear.
