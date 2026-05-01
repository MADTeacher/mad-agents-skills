# Deep Linking Setup

Use this reference for Android App Links, iOS Universal Links, custom URI
schemes, and deep-link validation. Prefer verified `https` links for production
links that should open the app from the web.

## Routing Model

Flutter can deliver incoming route information to `Navigator` or Router-based
apps. For new deep-link work, prefer `go_router` or another Router-based
solution so an incoming URL maps to a predictable page stack.

```dart
final router = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
    GoRoute(
      path: '/products/:productId',
      builder: (context, state) {
        final productId = state.pathParameters['productId']!;
        return ProductScreen(productId: productId);
      },
    ),
  ],
);
```

If the app uses a third-party deep-link plugin, confirm whether Flutter's
default deep-link handler should be disabled. In recent Flutter versions it is
enabled by default; plugin-based handlers usually require opting out in platform
configuration.

## Android App Links

Android App Links use `http` or `https` links verified against a domain you own.

### AndroidManifest.xml

Add an intent filter to the activity that should receive the link:

```xml
<activity
  android:name=".MainActivity"
  android:exported="true">
  <intent-filter android:autoVerify="true">
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data
      android:scheme="https"
      android:host="example.com" />
  </intent-filter>
</activity>
```

For custom schemes, use a scheme such as `myapp` instead of `https`, but expect
weaker verification and possible scheme conflicts.

```xml
<intent-filter>
  <action android:name="android.intent.action.VIEW" />
  <category android:name="android.intent.category.DEFAULT" />
  <category android:name="android.intent.category.BROWSABLE" />
  <data android:scheme="myapp" />
</intent-filter>
```

### assetlinks.json

Host the association file at:

```text
https://example.com/.well-known/assetlinks.json
```

Example:

```json
[
  {
    "relation": ["delegate_permission/common.handle_all_urls"],
    "target": {
      "namespace": "android_app",
      "package_name": "com.example.app",
      "sha256_cert_fingerprints": ["SHA256_FINGERPRINT"]
    }
  }
]
```

Use the release signing fingerprint for production builds and include debug
fingerprints only for debug validation.

### Android Tests

```bash
adb shell am start -W -a android.intent.action.VIEW -d "https://example.com/products/42"
adb shell am start -W -a android.intent.action.VIEW -d "myapp://products/42"
```

## iOS Universal Links

iOS Universal Links use `http` or `https` and require Associated Domains. They
are not configured by putting the Associated Domains entitlement in
`Info.plist`.

### Associated Domains

Add the Associated Domains capability in Xcode, or edit
`ios/Runner/Runner.entitlements`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>com.apple.developer.associated-domains</key>
  <array>
    <string>applinks:example.com</string>
  </array>
</dict>
</plist>
```

Personal development teams might not support Associated Domains. Confirm the
target signing team before treating Universal Links as verified.

### apple-app-site-association

Host the association file with no `.json` extension:

```text
https://example.com/.well-known/apple-app-site-association
```

Example:

```json
{
  "applinks": {
    "apps": [],
    "details": [
      {
        "appIDs": ["TEAMID.com.example.app"],
        "paths": ["*"],
        "components": [
          { "/": "/*" }
        ]
      }
    ]
  }
}
```

Apple's CDN can delay Universal Link validation. Account for that delay when
debugging fresh domain changes.

### iOS Custom Schemes

Use `Info.plist` for custom schemes:

```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLName</key>
    <string>com.example.app</string>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>myapp</string>
    </array>
  </dict>
</array>
```

Custom schemes are useful for app-only flows, but they are not domain-verified
like Universal Links.

### iOS Tests

```bash
xcrun simctl openurl booted "https://example.com/products/42"
xcrun simctl openurl booted "myapp://products/42"
```

## Web Deep Links

Flutter web handles URL paths in the browser. With the default hash strategy,
links look like:

```text
https://example.com/#/products/42
```

With path strategy, links look like:

```text
https://example.com/products/42
```

Path strategy requires server rewrites to `index.html`. See
[web-navigation.md](web-navigation.md).

## Validation Checklist

- Route table includes the expected incoming path.
- Required path parameters are parsed from `state.pathParameters`.
- Optional query values are parsed from `state.uri.queryParameters`.
- Invalid or missing values show an error screen, redirect, or safe fallback.
- Android manifest filters match scheme, host, and path expectations.
- `assetlinks.json` uses the correct package name and signing fingerprint.
- iOS Associated Domains are in Xcode capabilities or `Runner.entitlements`.
- The AASA file is reachable with the correct domain, team ID, and bundle ID.
- Third-party link plugins are not fighting Flutter's default handler.
- Device or simulator commands were run for the exact URLs changed.
