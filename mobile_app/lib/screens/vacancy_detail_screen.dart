import 'package:flutter/material.dart';
import '../models/vacancy.dart';
import '../services/api_service.dart';

class VacancyDetailScreen extends StatefulWidget {
  final Vacancy vacancy;
  final int candidateId;

  const VacancyDetailScreen({
    super.key,
    required this.vacancy,
    required this.candidateId,
  });

  @override
  State<VacancyDetailScreen> createState() => _VacancyDetailScreenState();
}

class _VacancyDetailScreenState extends State<VacancyDetailScreen> {
  bool _isApplying = false;
  bool _isApplied = false;
  String? _applicationStatus;
  bool _checkingStatus = true;

  @override
  void initState() {
    super.initState();
    _checkAppliedStatus();
  }

  Future<void> _checkAppliedStatus() async {
    final vacancy = await ApiService.getVacancyDetails(widget.vacancy.id);
    if (mounted) {
      setState(() {
        _applicationStatus = vacancy?.currentApplicationStatus;
        _isApplied = vacancy?.hasApplied == true || _applicationStatus != null;
        _checkingStatus = vacancy == null;
      });
    }
  }

  Future<void> _handleApply() async {
    setState(() => _isApplying = true);
    final success =
        await ApiService.applyToVacancy(widget.vacancy.id, widget.candidateId);
    setState(() => _isApplying = false);

    if (success) {
      setState(() => _isApplied = true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Application submitted successfully!')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to submit application.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.vacancy;

    return Scaffold(
      appBar: AppBar(
        title: Text(v.title),
        backgroundColor: const Color(0xFF0F172A),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              v.title,
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            const SizedBox(height: 6),
            Text(
              '${v.companyName} • ${v.location} (${v.employmentType})',
              style: const TextStyle(fontSize: 14, color: Colors.indigoAccent),
            ),
            const SizedBox(height: 16),
            const Divider(color: Colors.white24),
            const Text(
              'Job Description',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            const SizedBox(height: 6),
            Text(
              v.description,
              style: const TextStyle(
                  fontSize: 14, color: Colors.white70, height: 1.4),
            ),
            const SizedBox(height: 20),
            const Text(
              'Required Skills Taxonomy',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: v.skills.map((sk) {
                return Chip(
                  avatar: Icon(
                    sk.isMandatory ? Icons.star : Icons.check_circle_outline,
                    size: 14,
                    color: sk.isMandatory ? Colors.amber : Colors.white70,
                  ),
                  label: Text(
                    '${sk.skillName} ${sk.isMandatory ? "(Mandatory)" : "(Preferred)"}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  backgroundColor: sk.isMandatory
                      ? Colors.indigo.withValues(alpha: 0.3)
                      : const Color(0xFF1E293B),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            const Text(
              'Member 2 Non-Negotiable Eligibility Requirements',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.redAccent),
            ),
            const SizedBox(height: 8),
            if (v.requirements.isEmpty)
              const Text(
                  'Standard university SE/CS candidate qualifications required.',
                  style: TextStyle(color: Colors.white60))
            else
              Column(
                children: v.requirements.map((req) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.rule,
                            color: Colors.redAccent, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            req.requirementText,
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: _isApplied
                  ? ElevatedButton.icon(
                      icon: const Icon(Icons.check_circle, color: Colors.green),
                      label: Text(
                          _applicationStatus == 'WITHDRAWN'
                              ? 'Withdrawn'
                              : 'Application Submitted',
                          style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.withValues(alpha: 0.15),
                        elevation: 0,
                      ),
                      onPressed: null,
                    )
                  : ElevatedButton.icon(
                      icon: _isApplying
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.send),
                      label: Text(_isApplying
                          ? 'Submitting...'
                          : 'Submit Candidate Application'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigoAccent,
                        foregroundColor: Colors.white,
                      ),
                      onPressed:
                          _isApplying || _checkingStatus ? null : _handleApply,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
