import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

enum UserRole { kader, bidan }

class AppUser {
  const AppUser({
    required this.id,
    required this.nama,
    required this.nikNip,
    required this.role,
    this.posyanduId,
  });

  final int id;
  final String nama;
  final String nikNip;
  final UserRole role;
  final int? posyanduId;

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: _asInt(json['id']),
      nama: json['nama']?.toString() ?? '-',
      nikNip: json['nik_nip']?.toString() ?? '-',
      role: json['role'] == 'bidan' ? UserRole.bidan : UserRole.kader,
      posyanduId: json['posyandu_id'] == null ? null : _asInt(json['posyandu_id']),
    );
  }
}

class AuthSession {
  const AuthSession({required this.token, required this.user});

  final String token;
  final AppUser user;
}

class PaginatedResult {
  const PaginatedResult({required this.data, this.meta = const {}});

  final List<Map<String, dynamic>> data;
  final Map<String, dynamic> meta;

  factory PaginatedResult.fromJson(Map<String, dynamic> json) {
    final rows = (json['data'] as List<dynamic>? ?? [])
        .whereType<Map>()
        .map((row) => row.cast<String, dynamic>())
        .toList();
    return PaginatedResult(
      data: rows,
      meta: (json['meta'] as Map?)?.cast<String, dynamic>() ?? const {},
    );
  }
}

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

abstract class PosyanduApi {
  String get reportBaseUrl;

  Future<AuthSession> login(String nikNip, String password);
  Future<AppUser> me();
  Future<void> logout();
  Future<Map<String, dynamic>?> getActiveSession();
  Future<PaginatedResult> getChildren({String search = '', int perPage = 10});
  Future<Map<String, dynamic>> storeMeasurement({
    required int sessionId,
    required int childId,
    required double weight,
    required double height,
  });
  Future<Map<String, dynamic>> retryPrediction(int measurementId);
  Future<PaginatedResult> getScreening(int sessionId);
  Future<PaginatedResult> getNotifications();
  Future<PaginatedResult> getReferrals({String search = '', String? status});
  Future<Map<String, dynamic>> getReferral(int id);
  Future<Map<String, dynamic>> validateReferral({
    required int referralId,
    required String decision,
    required String note,
  });
  Future<PaginatedResult> getPmt();
  Future<Map<String, dynamic>> distributePmt({
    required int validationId,
    required int childId,
    required int pmtId,
    required int amount,
    required DateTime date,
    String? note,
  });
  Future<Uint8List> downloadReport({
    required String type,
    String? startDate,
    String? endDate,
  });
}

class HttpPosyanduApi implements PosyanduApi {
  HttpPosyanduApi({
    http.Client? client,
    String? baseUrl,
    String? initialToken,
  }) : _client = client ?? http.Client(),
       _baseUrl = Uri.parse(
         (baseUrl ??
                 const String.fromEnvironment(
                   'API_BASE_URL',
                   defaultValue: 'http://10.0.2.2:8000/api',
                 ))
             .replaceAll(RegExp(r'/+$'), ''),
       ),
       _token = initialToken;

  final http.Client _client;
  final Uri _baseUrl;
  String? _token;

  set token(String? value) => _token = value;

  @override
  String get reportBaseUrl => _baseUrl.toString();

  @override
  Future<AuthSession> login(String nikNip, String password) async {
    final json = await _requestJson(
      'POST',
      '/login',
      body: {'nik_nip': nikNip, 'password': password},
      authenticated: false,
    );
    final token = json['token']?.toString();
    if (token == null || token.isEmpty) {
      throw ApiException('Token login tidak diterima dari server.');
    }
    _token = token;
    return AuthSession(
      token: token,
      user: AppUser.fromJson((json['user'] as Map).cast<String, dynamic>()),
    );
  }

  @override
  Future<AppUser> me() async {
    final json = await _requestJson('GET', '/me');
    return AppUser.fromJson(json);
  }

  @override
  Future<void> logout() async {
    await _requestJson('POST', '/logout');
    _token = null;
  }

  @override
  Future<Map<String, dynamic>?> getActiveSession() async {
    final json = await _requestJson('GET', '/sesi/aktif');
    return json.isEmpty ? null : json;
  }

  @override
  Future<PaginatedResult> getChildren({
    String search = '',
    int perPage = 10,
  }) async {
    return PaginatedResult.fromJson(
      await _requestJson('GET', '/balita', query: {
        if (search.trim().isNotEmpty) 'search': search.trim(),
        'per_page': perPage.toString(),
      }),
    );
  }

  @override
  Future<Map<String, dynamic>> storeMeasurement({
    required int sessionId,
    required int childId,
    required double weight,
    required double height,
  }) async {
    return _requestJson('POST', '/pengukuran', body: {
      'sesi_posyandu_id': sessionId,
      'balita_id': childId,
      'berat_badan': weight,
      'tinggi_badan': height,
    });
  }

  @override
  Future<Map<String, dynamic>> retryPrediction(int measurementId) async {
    return _requestJson('POST', '/pengukuran/$measurementId/retry-prediksi');
  }

  @override
  Future<PaginatedResult> getScreening(int sessionId) async {
    return PaginatedResult.fromJson(
      await _requestJson('GET', '/sesi/$sessionId/skrining'),
    );
  }

  @override
  Future<PaginatedResult> getNotifications() async {
    return PaginatedResult.fromJson(await _requestJson('GET', '/notifikasi'));
  }

  @override
  Future<PaginatedResult> getReferrals({
    String search = '',
    String? status,
  }) async {
    return PaginatedResult.fromJson(
      await _requestJson('GET', '/rujukan', query: {
        if (search.trim().isNotEmpty) 'search': search.trim(),
        if (status != null && status.isNotEmpty) 'status': status,
      }),
    );
  }

  @override
  Future<Map<String, dynamic>> getReferral(int id) async {
    return _requestJson('GET', '/rujukan/$id');
  }

  @override
  Future<Map<String, dynamic>> validateReferral({
    required int referralId,
    required String decision,
    required String note,
  }) async {
    return _requestJson('POST', '/rujukan/$referralId/validasi', body: {
      'keputusan': decision,
      'catatan_bidan': note,
    });
  }

  @override
  Future<PaginatedResult> getPmt() async {
    return PaginatedResult.fromJson(await _requestJson('GET', '/pmt'));
  }

  @override
  Future<Map<String, dynamic>> distributePmt({
    required int validationId,
    required int childId,
    required int pmtId,
    required int amount,
    required DateTime date,
    String? note,
  }) async {
    return _requestJson('POST', '/distribusi-pmt', body: {
      'validasi_medis_id': validationId,
      'balita_id': childId,
      'pmt_id': pmtId,
      'jumlah': amount,
      'tanggal_distribusi': _dateOnly(date),
      if (note != null && note.isNotEmpty) 'keterangan': note,
    });
  }

  @override
  Future<Uint8List> downloadReport({
    required String type,
    String? startDate,
    String? endDate,
  }) async {
    final response = await _client.get(
      _uri('/laporan/$type', {
        if (startDate != null) 'start_date': startDate,
        if (endDate != null) 'end_date': endDate,
      }),
      headers: _headers(),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(_messageFromResponse(response), statusCode: response.statusCode);
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
    final uri = _uri(path, query);
    final encoded = body == null ? null : jsonEncode(body);
    final response = switch (method) {
      'GET' => await _client.get(uri, headers: headers),
      'POST' => await _client.post(uri, headers: headers, body: encoded),
      'PUT' => await _client.put(uri, headers: headers, body: encoded),
      _ => throw ArgumentError('Unsupported method $method'),
    };

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(_messageFromResponse(response), statusCode: response.statusCode);
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
      // Body can be a PDF/html error in deployment; fall back to generic text.
    }
    return 'Koneksi ke server belum berhasil. Coba lagi sebentar.';
  }
}

int _asInt(Object? value) {
  if (value is int) return value;
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

String _dateOnly(DateTime value) {
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  return '${value.year}-$month-$day';
}
