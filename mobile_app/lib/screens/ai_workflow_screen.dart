import 'package:flutter/material.dart';
import '../models/module_d.dart';
import '../services/module_d_api.dart';

/// Module D — AI Workflow Status Screen
/// Shows all AI workflow executions with per-step status, match score,
/// and a trigger button to run a new workflow for a candidate+vacancy.
class AIWorkflowScreen extends StatefulWidget {
  const AIWorkflowScreen({super.key});

  @override
  State<AIWorkflowScreen> createState() => _AIWorkflowScreenState();
}

class _AIWorkflowScreenState extends State<AIWorkflowScreen> {
  List<AIWorkflow> _workflows = [];
  bool _isLoading = true;
  bool _isTriggering = false;

  final _candidateIdController = TextEditingController();
  final _vacancyIdController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _candidateIdController.dispose();
    _vacancyIdController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final data = await ModuleDApiService.getAIWorkflows();
    if (mounted)
      setState(() {
        _workflows = data;
        _isLoading = false;
      });
  }

  Future<void> _triggerWorkflow() async {
    final cid = int.tryParse(_candidateIdController.text.trim());
    final vid = int.tryParse(_vacancyIdController.text.trim());
    if (cid == null || vid == null) {
      _showSnack('Enter valid candidate & vacancy IDs.', Colors.redAccent);
      return;
    }
    setState(() => _isTriggering = true);
    final result = await ModuleDApiService.triggerAIWorkflow(
      candidateId: cid,
      vacancyId: vid,
    );
    setState(() => _isTriggering = false);
    if (result != null) {
      _showSnack('✅ AI Workflow triggered successfully!', Colors.green);
      _load();
    } else {
      _showSnack(
          'Unable to run evaluation. Check the application and connection.',
          Colors.redAccent);
    }
  }

  void _showSnack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        title: const Text('AI Workflows',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _load,
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Trigger Panel ─────────────────────────────────────────────
          _TriggerPanel(
            candidateIdController: _candidateIdController,
            vacancyIdController: _vacancyIdController,
            isTriggering: _isTriggering,
            onTrigger: _triggerWorkflow,
          ),
          // ── Workflow List ─────────────────────────────────────────────
          Expanded(
            child: _isLoading
                ? const Center(
                    child:
                        CircularProgressIndicator(color: Colors.indigoAccent))
                : _workflows.isEmpty
                    ? _emptyState()
                    : RefreshIndicator(
                        onRefresh: _load,
                        color: Colors.indigoAccent,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          itemCount: _workflows.length,
                          itemBuilder: (_, i) =>
                              _WorkflowCard(workflow: _workflows[i]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.smart_toy_outlined, size: 64, color: Colors.white24),
            SizedBox(height: 16),
            Text('No AI workflows yet.',
                style: TextStyle(color: Colors.white38, fontSize: 16)),
            SizedBox(height: 8),
            Text('Use the panel above to trigger the\n4-agent AI pipeline.',
                style: TextStyle(color: Colors.white24, fontSize: 12),
                textAlign: TextAlign.center),
          ],
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────

class _TriggerPanel extends StatelessWidget {
  final TextEditingController candidateIdController;
  final TextEditingController vacancyIdController;
  final bool isTriggering;
  final VoidCallback onTrigger;

  const _TriggerPanel({
    required this.candidateIdController,
    required this.vacancyIdController,
    required this.isTriggering,
    required this.onTrigger,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.indigoAccent.withValues(alpha: 0.15),
            Colors.purple.withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.indigoAccent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.rocket_launch_outlined,
                  color: Colors.indigoAccent, size: 18),
              SizedBox(width: 8),
              Text('Trigger AI Pipeline',
                  style: TextStyle(
                      color: Colors.indigoAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 14)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _idField(
                    controller: candidateIdController, label: 'Candidate ID'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _idField(
                    controller: vacancyIdController, label: 'Vacancy ID'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigoAccent,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              icon: isTriggering
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.play_arrow_rounded, color: Colors.white),
              label: Text(
                isTriggering ? 'Running pipeline...' : 'Run 4-Agent Pipeline',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
              onPressed: isTriggering ? null : onTrigger,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Plan → Analyze Profile → Match Jobs → Validate & Route to HITL',
            style: TextStyle(color: Colors.white38, fontSize: 10),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _idField(
      {required TextEditingController controller, required String label}) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54, fontSize: 12),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.white12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.white12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.indigoAccent),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _WorkflowCard extends StatelessWidget {
  final AIWorkflow workflow;
  const _WorkflowCard({required this.workflow});

  Color get _statusColor {
    switch (workflow.status.toUpperCase()) {
      case 'PENDING_RECRUITER_APPROVAL':
        return Colors.amber;
      case 'APPROVED':
        return const Color(0xFF22C55E);
      case 'REJECTED':
        return Colors.redAccent;
      case 'ERROR':
        return Colors.red;
      default:
        return Colors.indigoAccent;
    }
  }

  IconData get _statusIcon {
    switch (workflow.status.toUpperCase()) {
      case 'PENDING_RECRUITER_APPROVAL':
        return Icons.pending_actions;
      case 'APPROVED':
        return Icons.check_circle_outline;
      case 'REJECTED':
        return Icons.cancel_outlined;
      case 'ERROR':
        return Icons.error_outline;
      default:
        return Icons.smart_toy_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_statusIcon, color: _statusColor, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(workflow.candidateName,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                  border:
                      Border.all(color: _statusColor.withValues(alpha: 0.4)),
                ),
                child: Text(
                  workflow.status.replaceAll('_', ' '),
                  style: TextStyle(
                      color: _statusColor,
                      fontSize: 9,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _info(Icons.label_outline, workflow.workflowType),
              const SizedBox(width: 16),
              if (workflow.matchScore != null)
                _info(Icons.analytics_outlined,
                    '${workflow.matchScore!.toStringAsFixed(0)}% match',
                    color: Colors.greenAccent),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Started ${workflow.startedAt.day}/${workflow.startedAt.month}/${workflow.startedAt.year}',
            style: const TextStyle(color: Colors.white24, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _info(IconData icon, String label, {Color color = Colors.white54}) =>
      Row(children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: color, fontSize: 11)),
      ]);
}
