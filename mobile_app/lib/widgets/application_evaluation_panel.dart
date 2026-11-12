import 'package:flutter/material.dart';
import '../models/application.dart';

class ApplicationEvaluationPanel extends StatelessWidget {
  final CandidateApplication application;
  final bool isEvaluating;
  final VoidCallback? onEvaluate;
  const ApplicationEvaluationPanel(
      {super.key,
      required this.application,
      required this.isEvaluating,
      this.onEvaluate});

  @override
  Widget build(BuildContext context) {
    final result = application.evaluation;
    final evidence = result?.evidence;
    final skillGroups = <String, dynamic>{
      'Matched required skills': evidence?['matched_required_skills'],
      if (evidence?['matched_required_skills'] == null)
        'Matched skills': evidence?['matched_skills'],
      'Missing required skills': evidence?['missing_required_skills'],
      'Matched preferred skills': evidence?['matched_preferred_skills'],
      'Missing preferred skills': evidence?['missing_preferred_skills'],
    };
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('AI Evaluation (advisory)',
          style: TextStyle(fontWeight: FontWeight.bold)),
      if (result == null)
        const Text('AI evaluation has not been run yet')
      else ...[
        Text('Match Score: ${result.matchScore}%'),
        if (evidence == null)
          const Text(
              'Detailed evidence is unavailable for this saved evaluation.'),
        for (final group in skillGroups.entries)
          if (group.value is List)
            Text(
                '${group.key}: ${(group.value as List).isEmpty ? 'None' : (group.value as List).join(', ')}'),
        if (evidence?['reasoning'] is String) Text(evidence!['reasoning']),
        for (final key in ['education_evidence', 'experience_evidence'])
          for (final record in (evidence?[key] as List? ?? []))
            if (record is Map)
              Text(
                  '${key == 'education_evidence' ? 'Education' : 'Experience'}: ${record.values.where((v) => v != null && v != '').join(' - ')}'),
        for (final requirement
            in (evidence?['requirements_review'] as List? ?? []))
          Text(
            '${requirement['text'].toString().replaceFirst(RegExp(r'\.$'), '')}: '
            '${requirement['result'] == 'REQUIRES_HUMAN_REVIEW' ? 'REQUIRES RECRUITER REVIEW' : requirement['result']}',
          ),
        const Text('The recruiter makes the final decision.'),
      ],
      if (application.status == 'PENDING_RECRUITER_APPROVAL')
        const Text('Awaiting recruiter review and approval.'),
      if (application.canEvaluate)
        ElevatedButton.icon(
          onPressed: isEvaluating ? null : onEvaluate,
          icon: isEvaluating
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.auto_awesome),
          label: Text(isEvaluating
              ? 'Running AI evaluation...'
              : 'Run Agentic AI Evaluation'),
        ),
    ]);
  }
}
