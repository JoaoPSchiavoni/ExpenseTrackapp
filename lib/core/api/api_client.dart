import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:spendlyapp/core/api/api_config.dart';
import 'package:spendlyapp/core/api/api_exception.dart';

typedef AccessTokenProvider = Future<String?> Function();

class ApiClient {
  ApiClient({
    required this.baseUrl,
    required this._accessToken,
    http.Client? httpClient,
    this.onUnauthorized,
  }) : _http = httpClient ?? http.Client();

  final String baseUrl;
  final AccessTokenProvider _accessToken;
  final http.Client _http;
  final Future<void> Function()? onUnauthorized;

  Uri _uri(String path, [Map<String, Object?> query = const {}]) {
    final base = Uri.parse(baseUrl);
    return base.replace(
      path: path.startsWith('/') ? path : '/$path',
      queryParameters: {
        for (final entry in query.entries)
          if (entry.value != null) entry.key: entry.value.toString(),
      },
    );
  }

  Future<Map<String, String>> _headers({bool authenticated = true}) async {
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    if (authenticated) {
      final token = await _accessToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  Future<dynamic> get(
    String path, {
    Map<String, Object?> query = const {},
    bool authenticated = true,
    Duration timeout = ApiConfig.requestTimeout,
  }) async {
    final response = await _http
        .get(
          _uri(path, query),
          headers: await _headers(authenticated: authenticated),
        )
        .timeout(timeout);
    return _decode(response);
  }

  Future<Uint8List> getBytes(
    String path, {
    Map<String, Object?> query = const {},
  }) async {
    final response = await _http
        .get(_uri(path, query), headers: await _headers())
        .timeout(ApiConfig.requestTimeout);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response.bodyBytes;
    }
    _decode(response);
    throw StateError('Resposta binária inválida');
  }

  Future<dynamic> post(
    String path, {
    Object? body,
    Map<String, Object?> query = const {},
    bool authenticated = true,
  }) async {
    final response = await _http
        .post(
          _uri(path, query),
          headers: await _headers(authenticated: authenticated),
          body: body == null ? null : jsonEncode(body),
        )
        .timeout(ApiConfig.requestTimeout);
    return _decode(response);
  }

  Future<dynamic> put(String path, {Object? body}) async {
    final response = await _http
        .put(
          _uri(path),
          headers: await _headers(),
          body: body == null ? null : jsonEncode(body),
        )
        .timeout(ApiConfig.requestTimeout);
    return _decode(response);
  }

  Future<dynamic> patch(String path, {Object? body}) async {
    final response = await _http
        .patch(
          _uri(path),
          headers: await _headers(),
          body: body == null ? null : jsonEncode(body),
        )
        .timeout(ApiConfig.requestTimeout);
    return _decode(response);
  }

  Future<dynamic> delete(String path) async {
    final response = await _http
        .delete(_uri(path), headers: await _headers())
        .timeout(ApiConfig.requestTimeout);
    return _decode(response);
  }

  Future<dynamic> multipart(
    String path, {
    required Map<String, String> fields,
    required String filename,
    required Uint8List bytes,
  }) async {
    final request = http.MultipartRequest('POST', _uri(path));
    final headers = await _headers();
    headers.remove('Content-Type');
    request.headers.addAll(headers);
    request.fields.addAll(fields);
    request.files.add(
      http.MultipartFile.fromBytes('file', bytes, filename: filename),
    );
    final streamed = await _http
        .send(request)
        .timeout(ApiConfig.requestTimeout);
    return _decode(await http.Response.fromStream(streamed));
  }

  dynamic _decode(http.Response response) {
    dynamic payload;
    if (response.body.isNotEmpty) {
      try {
        payload = jsonDecode(utf8.decode(response.bodyBytes));
      } on FormatException {
        payload = response.body;
      }
    }
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return payload;
    }
    if (response.statusCode == 401) {
      onUnauthorized?.call();
    }
    final detail = payload is Map ? payload['detail'] : null;
    final message = detail is String
        ? detail
        : response.statusCode >= 500
        ? 'O servidor está indisponível. Tente novamente em instantes.'
        : 'Não foi possível concluir a solicitação.';
    throw ApiException(
      message,
      statusCode: response.statusCode,
      details: payload,
    );
  }

  void close() => _http.close();
}
