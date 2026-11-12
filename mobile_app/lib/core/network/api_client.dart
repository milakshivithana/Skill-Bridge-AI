import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../storage/secure_storage_service.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  ApiException(this.message, {this.statusCode, this.data});

  @override
  String toString() => message;
}

class ApiClient {
  final SecureStorageService _storage = SecureStorageService();
  final String _baseUrl = ApiConstants.baseUrl;

  Future<Map<String, String>> _getHeaders({bool isJson = true}) async {
    final token = await _storage.getToken();
    final headers = <String, String>{
      'Accept': 'application/json',
    };
    if (isJson) {
      headers['Content-Type'] = 'application/json';
    }
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Uri _buildUri(String path, [Map<String, dynamic>? queryParams]) {
    final cleanPath = path.startsWith('/') ? path : '/$path';
    final fullUrl = '$_baseUrl$cleanPath';
    final uri = Uri.parse(fullUrl);
    if (queryParams != null && queryParams.isNotEmpty) {
      final stringParams = queryParams.map(
        (key, value) => MapEntry(key, value?.toString() ?? ''),
      );
      return uri.replace(queryParameters: stringParams);
    }
    return uri;
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? queryParams}) async {
    try {
      final uri = _buildUri(path, queryParams);
      final headers = await _getHeaders();
      final response = await http.get(uri, headers: headers);
      return _processResponse(response);
    } on SocketException {
      throw ApiException(
          'Cannot connect to SkillBridge server. Check your network or backend URL.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Unexpected network error: $e');
    }
  }

  Future<dynamic> post(String path, {dynamic body}) async {
    try {
      final uri = _buildUri(path);
      final headers = await _getHeaders(isJson: true);
      final response = await http.post(
        uri,
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      );
      return _processResponse(response);
    } on SocketException {
      throw ApiException('Cannot connect to SkillBridge server.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Unexpected error: $e');
    }
  }

  Future<dynamic> put(String path, {dynamic body}) async {
    try {
      final uri = _buildUri(path);
      final headers = await _getHeaders(isJson: true);
      final response = await http.put(
        uri,
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      );
      return _processResponse(response);
    } on SocketException {
      throw ApiException('Cannot connect to SkillBridge server.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Unexpected error: $e');
    }
  }

  Future<dynamic> delete(String path) async {
    try {
      final uri = _buildUri(path);
      final headers = await _getHeaders();
      final response = await http.delete(uri, headers: headers);
      return _processResponse(response);
    } on SocketException {
      throw ApiException('Cannot connect to SkillBridge server.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Unexpected error: $e');
    }
  }

  Future<dynamic> postMultipart(
    String path, {
    required String filePath,
    required String fileFieldName,
    Map<String, String>? fields,
  }) async {
    try {
      final uri = _buildUri(path);
      final request = http.MultipartRequest('POST', uri);

      final token = await _storage.getToken();
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      request.headers['Accept'] = 'application/json';

      if (fields != null) {
        request.fields.addAll(fields);
      }

      final file = await http.MultipartFile.fromPath(fileFieldName, filePath);
      request.files.add(file);

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      return _processResponse(response);
    } on SocketException {
      throw ApiException('Cannot connect to SkillBridge server.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('File upload failed: $e');
    }
  }

  dynamic _processResponse(http.Response response) {
    dynamic decoded;
    if (response.body.isNotEmpty) {
      try {
        decoded = jsonDecode(response.body);
      } catch (_) {
        decoded = response.body;
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }

    String errorMessage = 'Request failed with status ${response.statusCode}';
    if (decoded is Map) {
      errorMessage = decoded['message']?.toString() ??
          decoded['title']?.toString() ??
          decoded['error']?.toString() ??
          errorMessage;
    }

    if (response.statusCode == 401) {
      throw ApiException(
          'Session expired or unauthorized. Please log in again.',
          statusCode: 401,
          data: decoded);
    }
    if (response.statusCode == 403) {
      throw ApiException('You do not have permission to access this resource.',
          statusCode: 403, data: decoded);
    }
    if (response.statusCode == 404) {
      throw ApiException(
          errorMessage.contains('404')
              ? 'Requested item not found'
              : errorMessage,
          statusCode: 404,
          data: decoded);
    }

    throw ApiException(errorMessage,
        statusCode: response.statusCode, data: decoded);
  }
}
