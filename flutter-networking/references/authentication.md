# Authentication

Use this reference when a Flutter networking task needs authorization headers,
token storage, login, refresh, or authenticated retry behavior.

## Authentication Methods

### Bearer Token

```dart
Future<Album> fetchAlbum(http.Client client, String token) async {
  final response = await client.get(
    Uri.parse('https://api.example.com/albums/1'),
    headers: {'Authorization': 'Bearer $token'},
  );

  if (response.statusCode == 200) {
    return Album.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  throw ApiHttpException.fromResponse(response);
}
```

### Basic Authentication

```dart
String basicAuthHeader(String username, String password) {
  final credentials = '$username:$password';
  return 'Basic ${base64Encode(utf8.encode(credentials))}';
}

final response = await client.get(
  Uri.parse('https://api.example.com/me'),
  headers: {'Authorization': basicAuthHeader(username, password)},
);
```

### API Key

```dart
final response = await client.get(
  Uri.parse('https://api.example.com/data'),
  headers: {'X-API-Key': apiKey},
);
```

## Token Storage

Use `flutter_secure_storage` for access tokens, refresh tokens, and other
sensitive values:

```yaml
dependencies:
  flutter_secure_storage: ^10.0.0
```

```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenPair {
  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt;

  const TokenPair({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
  });

  bool get isExpired {
    final refreshWindow = DateTime.now().add(const Duration(minutes: 1));
    return !expiresAt.isAfter(refreshWindow);
  }
}

abstract class TokenStorage {
  Future<TokenPair?> read();
  Future<void> save(TokenPair tokens);
  Future<void> clear();
}

class SecureTokenStorage implements TokenStorage {
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _expiresAtKey = 'expires_at';

  final FlutterSecureStorage _storage;

  const SecureTokenStorage([
    this._storage = const FlutterSecureStorage(),
  ]);

  @override
  Future<TokenPair?> read() async {
    final accessToken = await _storage.read(key: _accessTokenKey);
    final refreshToken = await _storage.read(key: _refreshTokenKey);
    final expiresAtRaw = await _storage.read(key: _expiresAtKey);

    if (accessToken == null || refreshToken == null || expiresAtRaw == null) {
      return null;
    }

    final expiresAt = DateTime.tryParse(expiresAtRaw);
    if (expiresAt == null) {
      await clear();
      return null;
    }

    return TokenPair(
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresAt: expiresAt,
    );
  }

  @override
  Future<void> save(TokenPair tokens) async {
    await _storage.write(key: _accessTokenKey, value: tokens.accessToken);
    await _storage.write(key: _refreshTokenKey, value: tokens.refreshToken);
    await _storage.write(
      key: _expiresAtKey,
      value: tokens.expiresAt.toIso8601String(),
    );
  }

  @override
  Future<void> clear() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _expiresAtKey);
  }
}
```

`shared_preferences` is acceptable for non-sensitive session flags or cached
profile preferences. If it is needed, use the current package line:

```yaml
dependencies:
  shared_preferences: ^2.5.5
```

Do not store bearer tokens, refresh tokens, passwords, or API keys in
`shared_preferences`.

## Token Refresh

Keep refresh logic in an auth manager or authenticated client. The manager owns
the token lifecycle; callers ask it for a valid access token.

```dart
class AuthManager {
  final TokenStorage _tokenStorage;
  final http.Client _client;

  AuthManager(this._tokenStorage, this._client);

  Future<String> getAccessToken() async {
    final tokens = await _tokenStorage.read();
    if (tokens == null) {
      throw const UnauthorizedException('Missing auth tokens');
    }

    if (!tokens.isExpired) {
      return tokens.accessToken;
    }

    return refreshAccessToken(tokens.refreshToken);
  }

  Future<String> refreshAccessToken(String refreshToken) async {
    final response = await _client.post(
      Uri.parse('https://api.example.com/auth/refresh'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'refreshToken': refreshToken}),
    );

    if (response.statusCode != 200) {
      await _tokenStorage.clear();
      throw ApiHttpException.fromResponse(response);
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final tokens = TokenPair(
      accessToken: data['accessToken'] as String,
      refreshToken: data['refreshToken'] as String,
      expiresAt: DateTime.parse(data['expiresAt'] as String),
    );

    await _tokenStorage.save(tokens);
    return tokens.accessToken;
  }

  Future<void> logout() {
    return _tokenStorage.clear();
  }

  Future<TokenPair?> readTokens() {
    return _tokenStorage.read();
  }
}
```

## Authenticated Client

Do not resend the same `BaseRequest` after a 401. A streamed request may already
be finalized. Accept a request factory, recreate the request after refresh, and
retry only when the original operation is safe for the product/API contract.

```dart
typedef RequestFactory = http.BaseRequest Function(String accessToken);

class AuthenticatedClient {
  final http.Client _inner;
  final AuthManager _authManager;

  AuthenticatedClient(this._inner, this._authManager);

  Future<http.StreamedResponse> send(
    RequestFactory requestFactory, {
    bool retryOnUnauthorized = true,
  }) async {
    final token = await _authManager.getAccessToken();
    final response = await _inner.send(requestFactory(token));

    if (response.statusCode != 401 || !retryOnUnauthorized) {
      return response;
    }

    final tokens = await _authManager.readTokens();
    if (tokens == null) {
      return response;
    }

    await response.stream.drain<void>();
    final newToken = await _authManager.refreshAccessToken(tokens.refreshToken);
    return _inner.send(requestFactory(newToken));
  }
}
```

Usage:

```dart
final response = await authenticatedClient.send(
  (token) => http.Request(
    'GET',
    Uri.parse('https://api.example.com/albums/1'),
  )..headers['Authorization'] = 'Bearer $token',
);
```

## Login Flow

```dart
class AuthService {
  final http.Client _client;
  final TokenStorage _tokenStorage;

  AuthService(this._client, this._tokenStorage);

  Future<User> login(String email, String password) async {
    final response = await _client.post(
      Uri.parse('https://api.example.com/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 401) {
      throw const UnauthorizedException('Invalid email or password');
    }

    if (response.statusCode != 200) {
      throw ApiHttpException.fromResponse(response);
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    await _tokenStorage.save(
      TokenPair(
        accessToken: data['accessToken'] as String,
        refreshToken: data['refreshToken'] as String,
        expiresAt: DateTime.parse(data['expiresAt'] as String),
      ),
    );

    return User.fromJson(data['user'] as Map<String, dynamic>);
  }
}
```

## OAuth2

Use an OAuth2 package or the platform's browser flow for production OAuth. If a
project already has an OAuth helper, adapt to that helper instead of adding a
second flow. Never embed client secrets in a mobile app.

## Best Practices

1. Store sensitive tokens in secure storage, not `shared_preferences`.
2. Refresh tokens before expiration and clear storage when refresh fails.
3. Retry 401s with a newly created request, not an already-sent request object.
4. Send tokens only over HTTPS or `wss://`.
5. Keep token values out of logs, analytics, crash reports, screenshots, and
   source control.
6. Scope tokens narrowly and follow the backend's rotation policy.
