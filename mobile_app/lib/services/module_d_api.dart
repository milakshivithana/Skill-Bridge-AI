import '../core/constants/api_constants.dart';
import '../core/storage/secure_storage_service.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/module_d.dart';

/// Module D API calls — Shortlisting, Approval & Analytics
/// All calls go through the ASP.NET Core backend at localhost:5264
abstract class ModuleDApiService {
  static String get _base => ApiConstants.baseUrl;

  static Future<Map<String, String>> _headers() async {
    final token = await SecureStorageService().getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // =========================================================================
  // SHORTLISTS
  // =========================================================================

  static Future<List<Shortlist>> getShortlists({int? candidateId}) async {
    try {
      final res = await http.get(
          Uri.parse(candidateId == null
              ? '$_base/shortlists'
              : '$_base/shortlists/me'),
          headers: await _headers());
      if (res.statusCode == 200) {
        final List data = json.decode(res.body);
        return data.map((e) => Shortlist.fromJson(e)).toList();
      }
    } catch (e) {
      print('getShortlists error: $e');
    }
    return [];
  }

  static Future<Shortlist?> getShortlist(int id, {int? candidateId}) async {
    try {
      final res = await http.get(
          Uri.parse(candidateId == null
              ? '$_base/shortlists/$id'
              : '$_base/shortlists/me/$id'),
          headers: await _headers());
      if (res.statusCode == 200)
        return Shortlist.fromJson(json.decode(res.body));
    } catch (e) {
      print('getShortlist error: $e');
    }
    return null;
  }

  // =========================================================================
  // APPROVALS
  // =========================================================================

  static Future<List<Approval>> getApprovals() async {
    try {
      final res = await http.get(Uri.parse('$_base/shortlists/approvals'),
          headers: await _headers());
      if (res.statusCode == 200) {
        final List data = json.decode(res.body);
        return data.map((e) => Approval.fromJson(e)).toList();
      }
    } catch (e) {
      print('getApprovals error: $e');
    }
    return [];
  }

  static Future<bool> submitApprovalDecision({
    required int applicationId,
    required String decision,
    required String comments,
    required String decisionBy,
  }) async {
    try {
      final res = await http.post(
        Uri.parse(
            '$_base/shortlists/$applicationId/${decision == 'APPROVED' ? 'approve' : decision == 'REJECTED' ? 'reject' : 'request-revision'}?comments=${Uri.encodeComponent(comments)}'),
        headers: await _headers(),
        body: json.encode({
          'applicationId': applicationId,
          'decision': decision,
          'comments': comments,
          'decisionBy': decisionBy,
        }),
      );
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      print('submitApprovalDecision error: $e');
      return false;
    }
  }

  // =========================================================================
  // AI WORKFLOWS
  // =========================================================================

  static Future<List<AIWorkflow>> getAIWorkflows() async {
    try {
      final res = await http.get(Uri.parse('$_base/shortlists/workflows'),
          headers: await _headers());
      if (res.statusCode == 200) {
        final List data = json.decode(res.body);
        return data.map((e) => AIWorkflow.fromJson(e)).toList();
      }
    } catch (e) {
      print('getAIWorkflows error: $e');
    }
    return [];
  }

  static Future<Map<String, dynamic>?> triggerAIWorkflow({
    required int candidateId,
    required int vacancyId,
  }) async {
    try {
      final applicationsResponse = await http.get(
          Uri.parse('$_base/applications/candidate/$candidateId'),
          headers: await _headers());
      if (applicationsResponse.statusCode != 200) return null;
      final applications = (json.decode(applicationsResponse.body) as List)
          .where((a) => a['vacancyId'] == vacancyId)
          .toList();
      if (applications.isEmpty) return null;
      final applicationId = applications.first['id'];
      final res = await http.post(
        Uri.parse('$_base/applications/$applicationId/evaluate-match'),
        headers: await _headers(),
      );
      if (res.statusCode == 200 || res.statusCode == 201) {
        return json.decode(res.body);
      }
    } catch (e) {
      print('triggerAIWorkflow error: $e');
    }
    return null;
  }

  // =========================================================================
  // AUDIT LOG
  // =========================================================================

  static Future<List<AuditLog>> getAuditLogs() async {
    try {
      final res = await http.get(Uri.parse('$_base/audit-logs'),
          headers: await _headers());
      if (res.statusCode == 200) {
        final List data = json.decode(res.body)['logs'];
        return data.map((e) => AuditLog.fromJson(e)).toList();
      }
    } catch (e) {
      print('getAuditLogs error: $e');
    }
    return [];
  }

  // =========================================================================
  // ANALYTICS SUMMARY
  // =========================================================================

  static Future<AnalyticsSummary?> getAnalyticsSummary() async {
    try {
      final res = await http.get(
          Uri.parse('$_base/reports/recruitment-summary'),
          headers: await _headers());
      if (res.statusCode == 200) {
        return AnalyticsSummary.fromJson(json.decode(res.body));
      }
    } catch (e) {
      print('getAnalyticsSummary error: $e');
    }
    return null;
  }
}
