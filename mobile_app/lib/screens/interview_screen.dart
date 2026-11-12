import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';
import '../core/storage/secure_storage_service.dart';

class InterviewScreen extends StatefulWidget {
  final int? candidateId;

  const InterviewScreen({super.key, this.candidateId});

  @override
  State<InterviewScreen> createState() => _InterviewScreenState();
}

class _InterviewScreenState extends State<InterviewScreen> {
  bool _loading = true;
  List<dynamic> _interviews = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchInterviews();
  }

  Future<void> _fetchInterviews() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final token = await SecureStorageService().getToken();
      final res = await http.get(
          Uri.parse('${ApiConstants.baseUrl}/interviews/me'),
          headers: {if (token != null) 'Authorization': 'Bearer $token'});
      if (!mounted) return;
      if (res.statusCode == 200) {
        final List data = json.decode(res.body);
        setState(() {
          _interviews = data;
          _loading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Server returned ${res.statusCode}';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Could not connect to backend';
        _loading = false;
      });
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'CONFIRMED':
      case 'SCHEDULED':
        return const Color(0xFF10B981);
      case 'COMPLETED':
        return const Color(0xFF6366F1);
      case 'CANCELLED':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFFF59E0B);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text(
          'Interview Invitations',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchInterviews,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.indigoAccent),
            )
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 48, color: Colors.amber),
                        const SizedBox(height: 16),
                        Text(_errorMessage!,
                            style: const TextStyle(color: Colors.white70)),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _fetchInterviews,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Try Again'),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigoAccent),
                        ),
                      ],
                    ),
                  ),
                )
              : _interviews.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E293B),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white10),
                              ),
                              child: const Icon(Icons.calendar_month,
                                  size: 48, color: Colors.indigoAccent),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'No Scheduled Interviews Yet',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Once a recruiter approves your application in the HITL queue, your proposed interview slot will appear here.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: Colors.white60,
                                  fontSize: 13,
                                  height: 1.4),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _interviews.length,
                      itemBuilder: (context, index) {
                        final item = _interviews[index];
                        final vacancy = item['application']?['vacancy'];
                        final vacancyTitle =
                            vacancy?['title'] ?? 'Technical Internship';
                        final candidate = item['application']?['candidate']
                                ?['user']?['fullName'] ??
                            'Candidate';
                        final interviewer = item['interviewer']?['user']
                                ?['fullName'] ??
                            'Interviewer';
                        final department = item['interviewer']?['department'] ??
                            'Technical Panel';
                        final scheduledTime = item['scheduledTime'] ?? '';
                        final duration = item['durationMinutes'] ?? 45;
                        final status = item['status'] ?? 'SCHEDULED';
                        final meetingLink = item['meetingLinkOrLocation'] ??
                            'Online Teams Meeting';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFF334155)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(18.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        vacancyTitle,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(status)
                                            .withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                            color: _getStatusColor(status)
                                                .withValues(alpha: 0.3)),
                                      ),
                                      child: Text(
                                        status,
                                        style: TextStyle(
                                          color: _getStatusColor(status),
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Candidate: $candidate',
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 13),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.person_outline,
                                        size: 14, color: Colors.indigoAccent),
                                    const SizedBox(width: 6),
                                    Text(
                                      '$interviewer ($department)',
                                      style: const TextStyle(
                                          color: Colors.white60, fontSize: 12),
                                    ),
                                  ],
                                ),
                                const Divider(
                                    color: Colors.white12, height: 24),
                                Row(
                                  children: [
                                    const Icon(Icons.access_time,
                                        size: 15, color: Colors.amber),
                                    const SizedBox(width: 6),
                                    Text(
                                      scheduledTime.isNotEmpty
                                          ? scheduledTime
                                              .replaceFirst('T', ' ')
                                              .substring(0, 16)
                                          : 'Time slot confirmed',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600),
                                    ),
                                    const Spacer(),
                                    Text(
                                      '$duration mins',
                                      style: const TextStyle(
                                          color: Colors.white54, fontSize: 12),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.04),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.videocam_outlined,
                                          size: 16, color: Colors.cyanAccent),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          meetingLink,
                                          style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 12),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
