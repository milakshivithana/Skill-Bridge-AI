import '../core/constants/api_constants.dart';
import '../core/storage/secure_storage_service.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/vacancy.dart';
import '../models/application.dart';

class ApiService {
  // localhost:5264 for web/Chrome, 10.164.158.135:5264 for real Android device
  static String get baseUrl => ApiConstants.baseUrl;

  static Future<Map<String, String>> _headers() async {
    final token = await SecureStorageService().getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ---- Vacancies API ----
  static Future<List<Vacancy>> getVacancies({
    String? searchQuery,
    String? location,
    String? employmentType,
  }) async {
    final queryParams = <String, String>{};
    if (searchQuery != null && searchQuery.isNotEmpty)
      queryParams['searchQuery'] = searchQuery;
    if (location != null && location.isNotEmpty)
      queryParams['location'] = location;
    if (employmentType != null && employmentType.isNotEmpty)
      queryParams['employmentType'] = employmentType;

    final uri =
        Uri.parse('$baseUrl/vacancies').replace(queryParameters: queryParams);

    try {
      final response = await http.get(uri, headers: await _headers());
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List items = data is Map ? (data['items'] ?? []) : (data as List);
        return items.map((v) => Vacancy.fromJson(v)).toList();
      }
    } catch (e) {
      print('Error fetching vacancies: $e');
    }
    return [];
  }

  static Future<Vacancy?> getVacancyDetails(int id) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/vacancies/$id'),
          headers: await _headers());
      if (response.statusCode == 200) {
        return Vacancy.fromJson(json.decode(response.body));
      }
    } catch (e) {
      print('Error getting vacancy details: $e');
    }
    return null;
  }

  // ---- Saved Vacancies API ----
  static Future<bool> saveVacancy(int vacancyId, int candidateId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/vacancies/$vacancyId/save'),
        headers: await _headers(),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error saving vacancy: $e');
      return false;
    }
  }

  static Future<bool> unsaveVacancy(int vacancyId, int candidateId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/vacancies/$vacancyId/save'),
        headers: await _headers(),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error unsaving vacancy: $e');
      return false;
    }
  }

  static Future<List<SavedVacancy>> getSavedVacancies(int candidateId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/vacancies/saved/me'),
          headers: await _headers());
      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        return data.map((sv) => SavedVacancy.fromJson(sv)).toList();
      }
    } catch (e) {
      print('Error getting saved vacancies: $e');
    }
    return [];
  }

  // ---- Applications API ----
  static Future<bool> applyToVacancy(int vacancyId, int candidateId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/vacancies/$vacancyId/apply'),
        headers: await _headers(),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error applying to vacancy: $e');
      return false;
    }
  }

  static Future<List<CandidateApplication>> getCandidateApplications(
      int candidateId) async {
    final response = await http.get(Uri.parse('$baseUrl/applications/me'),
        headers: await _headers());
    if (response.statusCode != 200) {
      throw Exception(
          'Unable to load applications (${response.statusCode}). Please retry.');
    }
    final List data = json.decode(response.body);
    return data.map((app) => CandidateApplication.fromJson(app)).toList();
  }

  static Future<void> evaluateApplicationMatch(int appId) async {
    final response = await http.post(
        Uri.parse('$baseUrl/applications/$appId/evaluate-match'),
        headers: await _headers());
    if (response.statusCode != 200) {
      String message = 'AI evaluation failed (${response.statusCode}).';
      try {
        final body = json.decode(response.body);
        if (body is Map && body['message'] is String) message = body['message'];
      } on FormatException {/* Keep the HTTP error if response is not JSON. */}
      throw Exception(message);
    }
  }

  static Future<bool> withdrawApplication(int appId, String reason) async {
    try {
      final uri = Uri.parse(
          '$baseUrl/applications/$appId/withdraw?reason=${Uri.encodeComponent(reason)}');
      final response = await http.post(uri, headers: await _headers());
      return response.statusCode == 200;
    } catch (e) {
      print('Error withdrawing application: $e');
      return false;
    }
  }

  static Future<EligibilityResult?> checkEligibility(int appId) async {
    try {
      final response = await http.post(
          Uri.parse('$baseUrl/applications/$appId/eligibility-check'),
          headers: await _headers());
      if (response.statusCode == 200) {
        return EligibilityResult.fromJson(json.decode(response.body));
      }
    } catch (e) {
      print('Error checking eligibility: $e');
    }
    return null;
  }
}
