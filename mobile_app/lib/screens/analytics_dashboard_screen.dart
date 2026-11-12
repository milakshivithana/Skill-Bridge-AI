import 'package:flutter/material.dart';
import '../models/module_d.dart';
import '../services/module_d_api.dart';

/// Module D — Analytics Dashboard Screen
/// Shows recruitment KPI summary cards plus approval history list.
class AnalyticsDashboardScreen extends StatefulWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  State<AnalyticsDashboardScreen> createState() =>
      _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen>
    with SingleTickerProviderStateMixin {
  AnalyticsSummary? _summary;
  List<Approval> _approvals = [];
  bool _isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([
      ModuleDApiService.getAnalyticsSummary(),
      ModuleDApiService.getApprovals(),
    ]);
    if (mounted) {
      setState(() {
        _summary = results[0] as AnalyticsSummary?;
        _approvals = results[1] as List<Approval>;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        title: const Text('Analytics & Approvals',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _load),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.indigoAccent,
          labelColor: Colors.indigoAccent,
          unselectedLabelColor: Colors.white38,
          tabs: const [
            Tab(icon: Icon(Icons.bar_chart_rounded, size: 18), text: 'Summary'),
            Tab(
                icon: Icon(Icons.approval_outlined, size: 18),
                text: 'Approvals'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.indigoAccent))
          : TabBarView(
              controller: _tabController,
              children: [
                _SummaryTab(summary: _summary),
                _ApprovalsTab(approvals: _approvals, onRefresh: _load),
              ],
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Summary Tab
// ─────────────────────────────────────────────────────────────────────────────

class _SummaryTab extends StatelessWidget {
  final AnalyticsSummary? summary;
  const _SummaryTab({required this.summary});

  @override
  Widget build(BuildContext context) {
    final s = summary;
    if (s == null) {
      return const Center(child: Text('Unable to load recruitment analytics.'));
    }

    final approvalRate = s.totalApplications > 0
        ? (s.totalApproved / s.totalApplications * 100)
        : 0.0;
    final rejectionRate = s.totalApplications > 0
        ? (s.totalRejected / s.totalApplications * 100)
        : 0.0;

    return RefreshIndicator(
      onRefresh: () async {},
      color: Colors.indigoAccent,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Headline metric ──────────────────────────────────────
            _HeadlineCard(
              score: s.averageMatchScore,
              workflowsRun: s.totalWorkflowsRun,
            ),
            const SizedBox(height: 16),

            // ── KPI Grid ─────────────────────────────────────────────
            const Text('Recruitment KPIs',
                style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.bold,
                    fontSize: 13)),
            const SizedBox(height: 10),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.35,
              children: [
                _KpiCard(
                  label: 'Total Applications',
                  value: '${s.totalApplications}',
                  icon: Icons.send_outlined,
                  color: Colors.indigoAccent,
                ),
                _KpiCard(
                  label: 'Approved',
                  value: '${s.totalApproved}',
                  icon: Icons.check_circle_outline,
                  color: const Color(0xFF22C55E),
                ),
                _KpiCard(
                  label: 'Rejected',
                  value: '${s.totalRejected}',
                  icon: Icons.cancel_outlined,
                  color: Colors.redAccent,
                ),
                _KpiCard(
                  label: 'Pending HITL',
                  value: '${s.totalPending}',
                  icon: Icons.pending_actions_outlined,
                  color: Colors.amber,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Rate bars ─────────────────────────────────────────────
            const Text('Outcome Rates',
                style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.bold,
                    fontSize: 13)),
            const SizedBox(height: 12),
            _RateBar(
              label: 'Approval Rate',
              value: approvalRate / 100,
              displayValue: '${approvalRate.toStringAsFixed(1)}%',
              color: const Color(0xFF22C55E),
            ),
            const SizedBox(height: 10),
            _RateBar(
              label: 'Rejection Rate',
              value: rejectionRate / 100,
              displayValue: '${rejectionRate.toStringAsFixed(1)}%',
              color: Colors.redAccent,
            ),
            const SizedBox(height: 10),
            _RateBar(
              label: 'Avg AI Match Score',
              value: s.averageMatchScore / 100,
              displayValue: '${s.averageMatchScore.toStringAsFixed(1)}%',
              color: Colors.indigoAccent,
            ),
          ],
        ),
      ),
    );
  }
}

class _HeadlineCard extends StatelessWidget {
  final double score;
  final int workflowsRun;
  const _HeadlineCard({required this.score, required this.workflowsRun});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.indigoAccent.withValues(alpha: 0.25),
            Colors.purple.withValues(alpha: 0.15),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.indigoAccent.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Avg AI Match Score',
                  style: TextStyle(color: Colors.white54, fontSize: 12)),
              const SizedBox(height: 4),
              Text(
                '${score.toStringAsFixed(1)}%',
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 36),
              ),
              const SizedBox(height: 4),
              Text('$workflowsRun workflows completed',
                  style: const TextStyle(color: Colors.white38, fontSize: 11)),
            ],
          ),
          const Spacer(),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 72,
                height: 72,
                child: CircularProgressIndicator(
                  value: score / 100,
                  backgroundColor: Colors.white10,
                  valueColor: const AlwaysStoppedAnimation(Colors.indigoAccent),
                  strokeWidth: 6,
                ),
              ),
              Icon(Icons.auto_awesome,
                  color: Colors.indigoAccent.withValues(alpha: 0.8), size: 28),
            ],
          ),
        ],
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _KpiCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: TextStyle(
                      color: color, fontSize: 26, fontWeight: FontWeight.bold)),
              Text(label,
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ],
      ),
    );
  }
}

class _RateBar extends StatelessWidget {
  final String label;
  final double value;
  final String displayValue;
  final Color color;

  const _RateBar({
    required this.label,
    required this.value,
    required this.displayValue,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(color: Colors.white60, fontSize: 12)),
            Text(displayValue,
                style: TextStyle(
                    color: color, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: value.clamp(0.0, 1.0),
            backgroundColor: Colors.white10,
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Approvals Tab
// ─────────────────────────────────────────────────────────────────────────────

class _ApprovalsTab extends StatelessWidget {
  final List<Approval> approvals;
  final Future<void> Function() onRefresh;

  const _ApprovalsTab({required this.approvals, required this.onRefresh});

  Color _decisionColor(String decision) {
    switch (decision.toUpperCase()) {
      case 'APPROVED':
        return const Color(0xFF22C55E);
      case 'REJECTED':
        return Colors.redAccent;
      case 'REVISION_REQUESTED':
        return Colors.orange;
      default:
        return Colors.amber;
    }
  }

  IconData _decisionIcon(String decision) {
    switch (decision.toUpperCase()) {
      case 'APPROVED':
        return Icons.check_circle;
      case 'REJECTED':
        return Icons.cancel;
      case 'REVISION_REQUESTED':
        return Icons.edit_note;
      default:
        return Icons.pending_actions;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (approvals.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.approval_outlined, size: 64, color: Colors.white24),
            SizedBox(height: 16),
            Text('No approval decisions yet.',
                style: TextStyle(color: Colors.white38, fontSize: 16)),
            SizedBox(height: 8),
            Text(
                'Recruiter HITL decisions appear here\nafter AI workflows complete.',
                style: TextStyle(color: Colors.white24, fontSize: 12),
                textAlign: TextAlign.center),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: Colors.indigoAccent,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: approvals.length,
        itemBuilder: (_, i) {
          final a = approvals[i];
          final color = _decisionColor(a.decision);
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color.withValues(alpha: 0.25)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child:
                      Icon(_decisionIcon(a.decision), color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(a.candidateName,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14)),
                      Text(a.vacancyTitle,
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 12)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(a.decision,
                                style: TextStyle(
                                    color: color,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 8),
                          Text('by ${a.decisionBy}',
                              style: const TextStyle(
                                  color: Colors.white38, fontSize: 10)),
                        ],
                      ),
                      if (a.comments.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text('"${a.comments}"',
                            style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 11,
                                fontStyle: FontStyle.italic)),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        '${a.decisionAt.day}/${a.decisionAt.month}/${a.decisionAt.year}',
                        style: const TextStyle(
                            color: Colors.white24, fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
