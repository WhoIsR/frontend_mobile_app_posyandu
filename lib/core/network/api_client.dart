import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'api_exception.dart';

class ApiClient {
  ApiClient({http.Client? client, String? baseUrl, String? initialToken})
    : _client = client ?? http.Client(),
      _baseUrl = Uri.parse(
        (baseUrl ??
                const String.fromEnvironment(
                  'API_BASE_URL',
                  defaultValue: 'http://167.172.71.213/api',
                ))
            .replaceAll(RegExp(r'/+$'), ''),
      ),
      _token = initialToken;

  final http.Client _client;
  final Uri _baseUrl;
  String? _token;

  String get baseUrl => _baseUrl.toString();

  set token(String? value) => _token = value;

  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, String>? query,
  }) {
    return _requestJson('GET', path, query: query);
  }

  Future<Map<String, dynamic>> postJson(
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = true,
  }) {
    return _requestJson('POST', path, body: body, authenticated: authenticated);
  }

  Future<Map<String, dynamic>> putJson(
    String path, {
    Map<String, dynamic>? body,
  }) {
    return _requestJson('PUT', path, body: body);
  }

  Future<Uint8List> download(String path, {Map<String, String>? query}) async {
    final response = await _client.get(_uri(path, query), headers: _headers());
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        _messageFromResponse(response),
        statusCode: response.statusCode,
      );
    }
    return response.bodyBytes;
  }

  Future<Map<String, dynamic>> _requestJson(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? query,
    bool authenticated = true,
  }) async {
    final headers = _headers(authenticated: authenticated);
    final encoded = body == null ? null : jsonEncode(body);
    final uri = _uri(path, query);
    final response = switch (method) {
      'GET' => await _client.get(uri, headers: headers),
      'POST' => await _client.post(uri, headers: headers, body: encoded),
      'PUT' => await _client.put(uri, headers: headers, body: encoded),
      _ => throw ArgumentError('Unsupported method $method'),
    };

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        _messageFromResponse(response),
        statusCode: response.statusCode,
      );
    }
    if (response.body.trim().isEmpty || response.body == 'null') {
      return {};
    }
    final decoded = jsonDecode(response.body);
    return decoded is Map ? decoded.cast<String, dynamic>() : {};
  }

  Uri _uri(String path, [Map<String, String>? query]) {
    final normalizedPath = path.startsWith('/') ? path.substring(1) : path;
    return _baseUrl.replace(
      path: '${_baseUrl.path.replaceAll(RegExp(r'/+$'), '')}/$normalizedPath',
      queryParameters: query?.isEmpty ?? true ? null : query,
    );
  }

  Map<String, String> _headers({bool authenticated = true}) {
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (authenticated && _token != null) 'Authorization': 'Bearer $_token',
    };
  }

  String _messageFromResponse(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map && decoded['message'] != null) {
        return decoded['message'].toString();
      }
    } catch (_) {
      // Non-JSON errors can happen for PDF or deployment responses.
    }
    return 'Koneksi ke server belum berhasil. Coba lagi sebentar.';
  }
}
