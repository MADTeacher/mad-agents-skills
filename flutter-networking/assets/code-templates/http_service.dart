import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

typedef JsonDecoder<T> = T Function(Object? json);
typedef HeadersProvider = FutureOr<Map<String, String>> Function();

class ApiService {
  final http.Client _client;
  final String _baseUrl;
  final Duration _timeout;
  final HeadersProvider? _headersProvider;
  final bool _ownsClient;

  ApiService({
    required String baseUrl,
    http.Client? client,
    Duration timeout = const Duration(seconds: 15),
    HeadersProvider? headersProvider,
  }) : _baseUrl = baseUrl,
       _client = client ?? http.Client(),
       _timeout = timeout,
       _headersProvider = headersProvider,
       _ownsClient = client == null;

  Future<T?> getJson<T>(
    String path, {
    Map<String, String>? queryParameters,
    Map<String, String>? headers,
    required JsonDecoder<T> decode,
  }) {
    return _sendJson(
      'GET',
      path,
      queryParameters: queryParameters,
      headers: headers,
      decode: decode,
    );
  }

  Future<T?> postJson<T>(
    String path, {
    Object? body,
    Map<String, String>? queryParameters,
    Map<String, String>? headers,
    required JsonDecoder<T> decode,
  }) {
    return _sendJson(
      'POST',
      path,
      queryParameters: queryParameters,
      headers: headers,
      body: body,
      decode: decode,
    );
  }

  Future<T?> putJson<T>(
    String path, {
    Object? body,
    Map<String, String>? queryParameters,
    Map<String, String>? headers,
    required JsonDecoder<T> decode,
  }) {
    return _sendJson(
      'PUT',
      path,
      queryParameters: queryParameters,
      headers: headers,
      body: body,
      decode: decode,
    );
  }

  Future<T?> deleteJson<T>(
    String path, {
    Map<String, String>? queryParameters,
    Map<String, String>? headers,
    JsonDecoder<T>? decode,
  }) {
    return _sendJson(
      'DELETE',
      path,
      queryParameters: queryParameters,
      headers: headers,
      decode: decode,
    );
  }

  Future<T?> _sendJson<T>(
    String method,
    String path, {
    Map<String, String>? queryParameters,
    Map<String, String>? headers,
    Object? body,
    JsonDecoder<T>? decode,
  }) async {
    final uri = _uri(path, queryParameters);
    final requestHeaders = await _headers(headers, hasBody: body != null);
    final encodedBody = body == null ? null : jsonEncode(body);

    try {
      final response = await switch (method) {
        'GET' => _client.get(uri, headers: requestHeaders),
        'POST' => _client.post(uri, headers: requestHeaders, body: encodedBody),
        'PUT' => _client.put(uri, headers: requestHeaders, body: encodedBody),
        'DELETE' => _client.delete(uri, headers: requestHeaders),
        _ => throw ArgumentError.value(method, 'method', 'Unsupported method'),
      }.timeout(_timeout);

      return _handleResponse(response, decode);
    } on TimeoutException catch (error) {
      throw ApiTimeoutException(
        'Request timed out after ${_timeout.inSeconds}s',
        cause: error,
      );
    } on http.ClientException catch (error) {
      throw ApiNetworkException(error.message, cause: error);
    }
  }

  Uri _uri(String path, Map<String, String>? queryParameters) {
    final base = _baseUrl.endsWith('/')
        ? _baseUrl.substring(0, _baseUrl.length - 1)
        : _baseUrl;
    final normalizedPath = path.startsWith('/') ? path : '/$path';

    return Uri.parse(
      '$base$normalizedPath',
    ).replace(queryParameters: queryParameters);
  }

  Future<Map<String, String>> _headers(
    Map<String, String>? extra, {
    required bool hasBody,
  }) async {
    final provided = await _headersProvider?.call();
    return {
      'Accept': 'application/json',
      if (hasBody && _extraBodyNeedsJson(extra))
        'Content-Type': 'application/json',
      ...?provided,
      ...?extra,
    };
  }

  bool _extraBodyNeedsJson(Map<String, String>? extra) {
    return extra == null ||
        !extra.keys.any((key) => key.toLowerCase() == 'content-type');
  }

  T? _handleResponse<T>(http.Response response, JsonDecoder<T>? decode) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        return null;
      }
      if (decode == null) {
        throw ApiDecodeException('No decoder supplied for non-empty response');
      }

      return decode(jsonDecode(response.body));
    }

    throw ApiHttpException.fromResponse(response);
  }

  void dispose() {
    if (_ownsClient) {
      _client.close();
    }
  }
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? responseBody;
  final Object? cause;

  const ApiException(
    this.message, {
    this.statusCode,
    this.responseBody,
    this.cause,
  });

  @override
  String toString() {
    final code = statusCode == null ? '' : ' ($statusCode)';
    return '$runtimeType$code: $message';
  }
}

class ApiHttpException extends ApiException {
  const ApiHttpException(
    super.message, {
    required super.statusCode,
    super.responseBody,
  });

  factory ApiHttpException.fromResponse(http.Response response) {
    final message = response.reasonPhrase ?? 'HTTP ${response.statusCode}';
    return switch (response.statusCode) {
      400 => BadRequestException(message, response.body),
      401 => UnauthorizedException(message, response.body),
      403 => ForbiddenException(message, response.body),
      404 => NotFoundException(message, response.body),
      429 => TooManyRequestsException(message, response.body),
      >= 500 && < 600 => ServerException(
        message,
        response.statusCode,
        response.body,
      ),
      _ => ApiHttpException(
        message,
        statusCode: response.statusCode,
        responseBody: response.body,
      ),
    };
  }
}

class BadRequestException extends ApiHttpException {
  const BadRequestException(super.message, String responseBody)
    : super(statusCode: 400, responseBody: responseBody);
}

class UnauthorizedException extends ApiHttpException {
  const UnauthorizedException(super.message, String responseBody)
    : super(statusCode: 401, responseBody: responseBody);
}

class ForbiddenException extends ApiHttpException {
  const ForbiddenException(super.message, String responseBody)
    : super(statusCode: 403, responseBody: responseBody);
}

class NotFoundException extends ApiHttpException {
  const NotFoundException(super.message, String responseBody)
    : super(statusCode: 404, responseBody: responseBody);
}

class TooManyRequestsException extends ApiHttpException {
  const TooManyRequestsException(super.message, String responseBody)
    : super(statusCode: 429, responseBody: responseBody);
}

class ServerException extends ApiHttpException {
  const ServerException(super.message, int statusCode, String responseBody)
    : super(statusCode: statusCode, responseBody: responseBody);
}

class ApiNetworkException extends ApiException {
  const ApiNetworkException(super.message, {super.cause});
}

class ApiTimeoutException extends ApiException {
  const ApiTimeoutException(super.message, {super.cause});
}

class ApiDecodeException extends ApiException {
  const ApiDecodeException(super.message, {super.cause});
}
