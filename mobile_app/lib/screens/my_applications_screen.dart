import 'package:flutter/material.dart';
import '../models/application.dart';
import '../widgets/application_evaluation_panel.dart';
import '../services/api_service.dart';

class MyApplicationsScreen extends StatefulWidget {
  final int candidateId;

  const MyApplicationsScreen({super.key, required this.candidateId});

  @override
  State<MyApplicationsScreen> createState() => _MyApplicationsScreenState();
}

class _MyApplicationsScreenState extends State<MyApplicationsScreen> {
  List<CandidateApplication> _applications = [];
  bool _isLoading = true;
  String? _error;
  int? _evaluatingAppId;

  @override
  void initState() {
    super.initState();
    _loadApplications();
  }

  Future<void> _loadApplications() async {
    setState(() => _isLoading = true);
    try {
      final apps =
          await ApiService.getCandidateApplications(widget.candidateId);
      if (mounted) {
        setState(() {
          _applications = apps;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _evaluate(int appId) async {
    if (_evaluatingAppId != null) return;
    setState(() {
      _evaluatingAppId = appId;
      _error = null;
    });
    try {
      await ApiService.evaluateApplicationMatch(appId);
      await _loadApplications();
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _evaluatingAppId = null);
    }
  }

  Future<void> _showWithdrawDialog(int appId) async {
    final reasonController = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: const Text('Withdraw Application',
              style: TextStyle(color: Colors.redAccent)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Are you sure you want to withdraw this application?',
                  style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Reason for withdrawal (Optional)',
                  labelStyle: TextStyle(color: Colors.white60),
                  enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white24)),
                  focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.indigoAccent)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child:
                  const Text('Cancel', style: TextStyle(color: Colors.white60)),
            ),
            ElevatedButton(
              style:
                  ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () async {
                Navigator.pop(context);
                final reason = reasonController.text.trim().isEmpty
                    ? 'Withdrawn by candidate.'
                    : reasonController.text.trim();
                final success =
                    await ApiService.withdrawApplication(appId, reason);
                if (success) {
                  _loadApplications();
                }
              },
              child: const Text('Confirm Withdraw'),
            ),
          ],
        );
      },
    );
  }

  void _showStatusHistory(CandidateApplication app) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Status History: ${app.vacancyTitle}',
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: app.statusHistories.isEmpty
                    ? const Center(child: Text('No history entries.'))
                    : ListView.builder(
                        itemCount: app.statusHistories.length,
                        itemBuilder: (context, idx) {
                          final sh = app.statusHistories[idx];
                          return ListTile(
                            leading: const Icon(Icons.history,
                                color: Colors.indigoAccent),
                            title: Text(sh.status,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold)),
                            subtitle: Text(sh.notes,
                                style: const TextStyle(
                                    color: Colors.white60, fontSize: 12)),
                            trailing: Text(
                              '${sh.changedAt.month}/${sh.changedAt.day}',
                              style: const TextStyle(
                                  color: Colors.white38, fontSize: 11),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'APPROVED':
        return Colors.green;
      case 'REJECTED':
      case 'WITHDRAWN':
        return Colors.redAccent;
      case 'PENDING_RECRUITER_APPROVAL':
        return Colors.amber;
      default:
        return Colors.indigoAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Applications'),
        backgroundColor: const Color(0xFF0F172A),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(_error!),
                  TextButton(
                      onPressed: _loadApplications, child: const Text('Retry')),
                ]))
              : _applications.isEmpty
                  ? const Center(
                      child:
                          Text('You have not submitted any applications yet.'))
                  : RefreshIndicator(
                      onRefresh: _loadApplications,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _applications.length,
                        itemBuilder: (context, index) {
                          final app = _applications[index];
                          final statusColor = _getStatusColor(app.status);

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            color: const Color(0xFF1E293B),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(color: Colors.white10),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          app.vacancyTitle,
                                          style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: statusColor.withValues(
                                              alpha: 0.15),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border:
                                              Border.all(color: statusColor),
                                        ),
                                        child: Text(
                                          app.status,
                                          style: TextStyle(
                                              color: statusColor,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),

                                  Text(
                                    '${app.companyName} • Applied ${app.appliedAt.day}/${app.appliedAt.month}/${app.appliedAt.year}',
                                    style: const TextStyle(
                                        color: Colors.white60, fontSize: 12),
                                  ),
                                  const SizedBox(height: 12),

                                  ApplicationEvaluationPanel(
                                    application: app,
                                    isEvaluating: _evaluatingAppId == app.id,
                                    onEvaluate: _evaluatingAppId == null
                                        ? () => _evaluate(app.id)
                                        : null,
                                  ),
                                  const SizedBox(height: 12),

                                  // Actions
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      TextButton.icon(
                                        icon: const Icon(Icons.timeline,
                                            size: 16,
                                            color: Colors.indigoAccent),
                                        label: const Text('Status Timeline',
                                            style: TextStyle(
                                                color: Colors.indigoAccent)),
                                        onPressed: () =>
                                            _showStatusHistory(app),
                                      ),
                                      if (app.status != 'WITHDRAWN' &&
                                          app.status != 'REJECTED' &&
                                          app.status != 'APPROVED')
                                        OutlinedButton.icon(
                                          icon: const Icon(
                                              Icons.cancel_outlined,
                                              size: 14,
                                              color: Colors.redAccent),
                                          label: const Text('Withdraw',
                                              style: TextStyle(
                                                  color: Colors.redAccent,
                                                  fontSize: 12)),
                                          style: OutlinedButton.styleFrom(
                                            side: const BorderSide(
                                                color: Colors.redAccent),
                                          ),
                                          onPressed: _evaluatingAppId == app.id
                                              ? null
                                              : () =>
                                                  _showWithdrawDialog(app.id),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
