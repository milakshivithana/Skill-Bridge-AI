import 'package:flutter/material.dart';
import '../models/module_d.dart';
import '../services/module_d_api.dart';

/// Module D — Audit Log Screen
/// Immutable audit trail of all system and AI actions.
class AuditLogScreen extends StatefulWidget {
  const AuditLogScreen({super.key});

  @override
  State<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends State<AuditLogScreen> {
  List<AuditLog> _logs = [];
  List<AuditLog> _filtered = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final data = await ModuleDApiService.getAuditLogs();
    if (mounted) {
      setState(() {
        _logs = data;
        _filtered = _logs;
        _isLoading = false;
      });
    }
  }

  void _onSearch(String q) {
    setState(() {
      _filtered = q.isEmpty
          ? _logs
          : _logs
              .where((l) =>
                  l.entityName.toLowerCase().contains(q.toLowerCase()) ||
                  l.action.toLowerCase().contains(q.toLowerCase()) ||
                  l.performedBy.toLowerCase().contains(q.toLowerCase()))
              .toList();
    });
  }

  Color _actionColor(String action) {
    final a = action.toUpperCase();
    if (a.contains('APPROVED') || a.contains('CREATED'))
      return const Color(0xFF22C55E);
    if (a.contains('REJECTED') || a.contains('WITHDRAWN'))
      return Colors.redAccent;
    if (a.contains('AI') || a.contains('WORKFLOW')) return Colors.indigoAccent;
    if (a.contains('HITL') || a.contains('PENDING')) return Colors.amber;
    return Colors.white54;
  }

  IconData _actionIcon(String action) {
    final a = action.toUpperCase();
    if (a.contains('WORKFLOW') || a.contains('AI'))
      return Icons.smart_toy_outlined;
    if (a.contains('APPROVED')) return Icons.check_circle_outline;
    if (a.contains('REJECTED')) return Icons.cancel_outlined;
    if (a.contains('HITL')) return Icons.pending_actions_outlined;
    if (a.contains('CREATED')) return Icons.add_circle_outline;
    if (a.contains('STATUS')) return Icons.update_outlined;
    return Icons.history_outlined;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        title: const Text('Audit Log',
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
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              onChanged: _onSearch,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search entity, action or user…',
                hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                prefixIcon:
                    const Icon(Icons.search, color: Colors.white38, size: 18),
                filled: true,
                fillColor: const Color(0xFF1E293B),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          // Entry count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Text(
                  '${_filtered.length} entries',
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(5),
                    border:
                        Border.all(color: Colors.green.withValues(alpha: 0.3)),
                  ),
                  child: const Text('Immutable Record',
                      style: TextStyle(color: Colors.green, fontSize: 9)),
                ),
              ],
            ),
          ),
          // Log entries
          Expanded(
            child: _isLoading
                ? const Center(
                    child:
                        CircularProgressIndicator(color: Colors.indigoAccent))
                : _filtered.isEmpty
                    ? const Center(
                        child: Text('No entries match your search.',
                            style: TextStyle(color: Colors.white38)))
                    : RefreshIndicator(
                        onRefresh: _load,
                        color: Colors.indigoAccent,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                          itemCount: _filtered.length,
                          itemBuilder: (_, i) {
                            final log = _filtered[i];
                            final color = _actionColor(log.action);
                            final isLast = i == _filtered.length - 1;
                            return IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Timeline rail
                                  Column(
                                    children: [
                                      Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: color.withValues(alpha: 0.12),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                              color:
                                                  color.withValues(alpha: 0.4),
                                              width: 1.5),
                                        ),
                                        child: Icon(_actionIcon(log.action),
                                            size: 14, color: color),
                                      ),
                                      if (!isLast)
                                        Expanded(
                                          child: Container(
                                            width: 1.5,
                                            color: Colors.white10,
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(width: 12),
                                  // Entry content
                                  Expanded(
                                    child: Padding(
                                      padding: EdgeInsets.only(
                                          bottom: isLast ? 0 : 16),
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        margin:
                                            const EdgeInsets.only(bottom: 4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF1E293B),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                              color: color.withValues(
                                                  alpha: 0.15)),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 6,
                                                      vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: color.withValues(
                                                        alpha: 0.12),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            4),
                                                  ),
                                                  child: Text(
                                                      log.entityName
                                                          .toUpperCase(),
                                                      style: TextStyle(
                                                          color: color,
                                                          fontSize: 9,
                                                          fontWeight:
                                                              FontWeight.bold)),
                                                ),
                                                const Spacer(),
                                                Text(
                                                  _formatTime(log.timestamp),
                                                  style: const TextStyle(
                                                      color: Colors.white24,
                                                      fontSize: 10),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              log.action.replaceAll('_', ' '),
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'by ${log.performedBy}',
                                              style: const TextStyle(
                                                  color: Colors.white54,
                                                  fontSize: 11),
                                            ),
                                            if (log.details != null &&
                                                log.details!.isNotEmpty) ...[
                                              const SizedBox(height: 6),
                                              Container(
                                                padding:
                                                    const EdgeInsets.all(6),
                                                decoration: BoxDecoration(
                                                  color: Colors.white
                                                      .withValues(alpha: 0.03),
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  log.details!,
                                                  style: const TextStyle(
                                                      color: Colors.white38,
                                                      fontSize: 10,
                                                      fontFamily: 'monospace'),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
