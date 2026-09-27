import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../storage/token_store.dart';

/// Thrown for any non-2xx response. Mirrors the backend's ApiError envelope.
class ApiException implements Exception {
  final int statusCode;
  final String message;
  final Map<String, dynamic>? fieldErrors;

  ApiException(this.statusCode, this.message, {this.fieldErrors});

  @override
  String toString() => message;
}

/// Thin HTTP wrapper: injects the Bearer token, transparently refreshes it on a
/// 401 (rotating refresh token), and normalizes backend errors into [ApiException].
class ApiClient {
  final TokenStore _tokenStorage;
  final http.Client _http;
  bool _refreshing = false;

  ApiClient(this._tokenStorage, {http.Client? httpClient})
      : _http = httpClient ?? http.Client();

  Uri _uri(String path) =>
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.apiPrefix}$path');

  Future<Map<String, String>> _headers({required bool auth}) async {
    final headers = {'Content-Type': 'application/json'};
    if (auth) {
      final token = await _tokenStorage.getAccessToken();
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<dynamic> get(String path, {bool auth = true}) =>
      _send('GET', path, auth: auth);

  Future<dynamic> post(String path, {Object? body, bool auth = true}) =>
      _send('POST', path, body: body, auth: auth);

  Future<dynamic> put(String path, {Object? body, bool auth = true}) =>
      _send('PUT', path, body: body, auth: auth);

  Future<dynamic> delete(String path, {Object? body, bool auth = true}) =>
      _send('DELETE', path, body: body, auth: auth);

  Future<dynamic> _send(String method, String path, {Object? body, bool auth = true}) async {
    var res = await _raw(method, path, body: body, auth: auth);
    // On an expired access token, try one refresh + retry (but never for /auth/*).
    if (res.statusCode == 401 && auth && !path.startsWith('/auth/')) {
      if (await _tryRefresh()) {
        res = await _raw(method, path, body: body, auth: auth);
      }
    }
    return _handle(res);
  }

  Future<http.Response> _raw(String method, String path, {Object? body, bool auth = true}) async {
    final uri = _uri(path);
    final headers = await _headers(auth: auth);
    final encoded = body != null ? jsonEncode(body) : null;
    switch (method) {
      case 'GET':
        return _http.get(uri, headers: headers);
      case 'POST':
        return _http.post(uri, headers: headers, body: encoded);
      case 'PUT':
        return _http.put(uri, headers: headers, body: encoded);
      case 'DELETE':
        return _http.delete(uri, headers: headers, body: encoded);
      default:
        throw ArgumentError('Unsupported method $method');
    }
  }

  Future<bool> _tryRefresh() async {
    if (_refreshing) return false;
    _refreshing = true;
    try {
      final rt = await _tokenStorage.getRefreshToken();
      if (rt == null) return false;
      final res = await _http.post(_uri('/auth/refresh'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'refreshToken': rt}));
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        await _tokenStorage.saveTokens(
          accessToken: data['accessToken'] as String,
          refreshToken: data['refreshToken'] as String,
        );
        return true;
      }
      return false;
    } catch (_) {
      return false;
    } finally {
      _refreshing = false;
    }
  }

  dynamic _handle(http.Response res) {
    final dynamic body = res.body.isNotEmpty ? jsonDecode(res.body) : null;
    if (res.statusCode >= 200 && res.statusCode < 300) return body;

    final message = (body is Map && body['message'] != null)
        ? body['message'].toString()
        : 'Request failed (${res.statusCode})';
    final fieldErrors = (body is Map && body['fieldErrors'] is Map)
        ? Map<String, dynamic>.from(body['fieldErrors'] as Map)
        : null;
    throw ApiException(res.statusCode, message, fieldErrors: fieldErrors);
  }
}
