import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/module_d.dart';
import '../providers/auth_provider.dart';
import '../services/module_d_api.dart';

/// Module D Ã¢â‚¬â€ Shortlist Screen
/// Shows AI-generated shortlists and recommendations scoped to the candidate.
class ShortlistScreen extends StatefulWidget {
  final int? candidateId;
  const ShortlistScreen({super.key, this.candidateId});

  @override
  State<ShortlistScreen> createState() => _ShortlistScreenState();
}

class _ShortlistScreenState extends State<ShortlistScreen> {
  List<Shortlist> _shortlists = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final auth = context.read<AuthProvider>();
    final user = auth.currentUser;
    final candidateId = user?.candidateId;
    final userEmail = user?.email.trim().toLowerCase() ?? '';

    final isStaff = user?.role == 'Recruiter' || user?.role == 'Administrator';
    if (!isStaff && candidateId == null) {
      if (mounted) {
        setState(() {
          _shortlists = [];
          _isLoading = false;
        });
      }
      return;
    }
    final data = await ModuleDApiService.getShortlists(
        candidateId: isStaff ? null : candidateId);

    // Strictly filter out any shortlist or recommendation that does NOT belong to the logged-in candidate
    List<Shortlist> scopedShortlists = [];
    if (!isStaff) {
      for (final sl in data) {
        final myRecs = sl.recommendations.where((r) {
          final emailMatch = userEmail.isNotEmpty &&
              r.candidateEmail.trim().toLowerCase() == userEmail;
          final idMatch = candidateId != null &&
              candidateId > 0 &&
              r.candidateId > 0 &&
              r.candidateId == candidateId;
          return idMatch && (userEmail.isEmpty || emailMatch);
        }).toList();

        if (myRecs.isNotEmpty) {
          scopedShortlists.add(
            Shortlist(
              id: sl.id,
              title: sl.title,
              vacancyTitle: sl.vacancyTitle,
              createdAt: sl.createdAt,
              recommendations: myRecs,
            ),
          );
        }
      }
    } else {
      scopedShortlists = data;
    }

    if (mounted) {
      setState(() {
        _shortlists = scopedShortlists;
        _isLoading = false;
      });
    }
  }

  void _openDetail(Shortlist sl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _ShortlistDetailSheet(
          shortlist: sl,
          currentCandidateId: widget.candidateId,
        ),
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
        title: const Text('My AI Shortlists',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _load,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.indigoAccent))
          : _shortlists.isEmpty
              ? _emptyState()
              : RefreshIndicator(
                  onRefresh: _load,
                  color: Colors.indigoAccent,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _shortlists.length,
                    itemBuilder: (_, i) => _ShortlistCard(
                      shortlist: _shortlists[i],
                      currentCandidateId: widget.candidateId,
                      onTap: () => _openDetail(_shortlists[i]),
                    ),
                  ),
                ),
    );
  }

  Widget _emptyState() => Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.indigoAccent.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.star_border_rounded,
                    size: 48, color: Colors.indigoAccent),
              ),
              const SizedBox(height: 20),
              const Text('No Shortlists For Your Account',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text(
                'Your results appear here when your application is added to a shortlist.',
                style:
                    TextStyle(color: Colors.white54, fontSize: 13, height: 1.4),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
}

class _ShortlistCard extends StatelessWidget {
  final Shortlist shortlist;
  final int? currentCandidateId;
  final VoidCallback onTap;

  const _ShortlistCard({
    required this.shortlist,
    this.currentCandidateId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final candidateId = user?.candidateId;
    final userEmail = user?.email.trim().toLowerCase() ?? '';

    // Check if the current candidate is recommended in this shortlist
    final myRec = shortlist.recommendations.where((r) {
      final emailMatch = userEmail.isNotEmpty &&
          r.candidateEmail.trim().toLowerCase() == userEmail;
      final idMatch = candidateId != null &&
          candidateId > 0 &&
          r.candidateId > 0 &&
          r.candidateId == candidateId;
      return idMatch && (userEmail.isEmpty || emailMatch);
    }).firstOrNull;

    final displayScore = myRec != null
        ? myRec.calculatedScore
        : (shortlist.recommendations.isNotEmpty
            ? shortlist.recommendations.first.calculatedScore
            : 0.0);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: myRec != null
                ? const Color(0xFF10B981).withValues(alpha: 0.5)
                : const Color(0xFF334155),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.indigoAccent.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (myRec != null
                            ? const Color(0xFF10B981)
                            : Colors.indigoAccent)
                        .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    myRec != null
                        ? Icons.verified_user_outlined
                        : Icons.auto_awesome,
                    color: myRec != null
                        ? const Color(0xFF34D399)
                        : Colors.indigoAccent,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(shortlist.title,
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                      Text(shortlist.vacancyTitle,
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 12)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.white38),
              ],
            ),
            const SizedBox(height: 14),
            // Stats row
            Row(
              children: [
                if (myRec != null) ...[
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFF10B981)),
                    ),
                    child: const Text('You are Shortlisted',
                        style: TextStyle(
                            color: Color(0xFF34D399),
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 12),
                ] else ...[
                  _stat(Icons.people_outline,
                      '${shortlist.recommendations.length} candidate${shortlist.recommendations.length == 1 ? '' : 's'}'),
                  const SizedBox(width: 16),
                ],
                if (shortlist.recommendations.isNotEmpty)
                  _stat(Icons.star_outline,
                      'Match: ${displayScore.toStringAsFixed(0)}%',
                      color: Colors.amber),
                const Spacer(),
                Text(
                  '${shortlist.createdAt.day}/${shortlist.createdAt.month}/${shortlist.createdAt.year}',
                  style: const TextStyle(color: Colors.white24, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(IconData icon, String label, {Color color = Colors.white54}) =>
      Row(children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: color, fontSize: 12)),
      ]);
}

// Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
// Shortlist Detail Screen
// Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬

class _ShortlistDetailSheet extends StatelessWidget {
  final Shortlist shortlist;
  final int? currentCandidateId;
  const _ShortlistDetailSheet(
      {required this.shortlist, this.currentCandidateId});

  Color _scoreColor(double score) {
    if (score >= 80) return const Color(0xFF22C55E);
    if (score >= 60) return Colors.amber;
    return Colors.redAccent;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final candidateId = user?.candidateId;
    final userEmail = user?.email.trim().toLowerCase() ?? '';

    // Filter strictly to current candidate
    final recommendationsToShow = user?.role == 'Candidate'
        ? shortlist.recommendations.where((r) {
            final emailMatch = userEmail.isNotEmpty &&
                r.candidateEmail.trim().toLowerCase() == userEmail;
            final idMatch = candidateId != null &&
                candidateId > 0 &&
                r.candidateId > 0 &&
                r.candidateId == candidateId;
            return idMatch && (userEmail.isEmpty || emailMatch);
          }).toList()
        : shortlist.recommendations;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(shortlist.title,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
            Text(shortlist.vacancyTitle,
                style: const TextStyle(color: Colors.white54, fontSize: 12)),
          ],
        ),
      ),
      body: recommendationsToShow.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.shield_outlined,
                        size: 48, color: Colors.white24),
                    SizedBox(height: 14),
                    Text('Not Shortlisted for this Vacancy',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text(
                      'Your profile is not in this shortlist. Only vacancies where your application is shortlisted will show your match score here.',
                      style: TextStyle(
                          color: Colors.white54, fontSize: 12, height: 1.4),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: recommendationsToShow.length,
              itemBuilder: (_, i) {
                final r = recommendationsToShow[i];
                final isMe = (userEmail.isNotEmpty &&
                        r.candidateEmail.trim().toLowerCase() == userEmail) ||
                    (candidateId != null &&
                        candidateId > 0 &&
                        r.candidateId == candidateId);
                final scoreColor = _scoreColor(r.calculatedScore);
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isMe
                          ? const Color(0xFF10B981).withValues(alpha: 0.5)
                          : const Color(0xFF334155),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // Rank badge
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: i == 0
                                  ? Colors.amber.withValues(alpha: 0.2)
                                  : Colors.white10,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text('#${i + 1}',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: i == 0
                                          ? Colors.amber
                                          : Colors.white54)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        r.candidateName,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            fontSize: 14),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (isMe) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF10B981)
                                              .withValues(alpha: 0.2),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                          border: Border.all(
                                              color: const Color(0xFF10B981),
                                              width: 0.8),
                                        ),
                                        child: const Text('YOU',
                                            style: TextStyle(
                                                color: Color(0xFF34D399),
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  ],
                                ),
                                Text(r.candidateEmail,
                                    style: const TextStyle(
                                        color: Colors.white54, fontSize: 11)),
                              ],
                            ),
                          ),
                          // Score badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: scoreColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: scoreColor),
                            ),
                            child: Text(
                              '${r.calculatedScore.toStringAsFixed(0)}%',
                              style: TextStyle(
                                  color: scoreColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                      // Score bar
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: r.calculatedScore / 100,
                          backgroundColor: Colors.white10,
                          valueColor: AlwaysStoppedAnimation(scoreColor),
                          minHeight: 5,
                        ),
                      ),
                      // AI Justification
                      if (r.aiJustification.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.psychology_outlined,
                                size: 13, color: Colors.indigoAccent),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(r.aiJustification,
                                  style: const TextStyle(
                                      color: Colors.white54,
                                      fontSize: 11,
                                      fontStyle: FontStyle.italic)),
                            ),
                          ],
                        ),
                      ],
                      // Status chip
                      const SizedBox(height: 8),
                      _StatusChip(status: r.applicationStatus),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  Color get _color {
    switch (status.toUpperCase()) {
      case 'APPROVED':
        return const Color(0xFF22C55E);
      case 'REJECTED':
        return Colors.redAccent;
      case 'PENDING_RECRUITER_APPROVAL':
        return Colors.amber;
      case 'WITHDRAWN':
        return Colors.orange;
      default:
        return Colors.indigoAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _color.withValues(alpha: 0.4)),
      ),
      child: Text(status,
          style: TextStyle(
              color: _color, fontSize: 10, fontWeight: FontWeight.w600)),
    );
  }
}
