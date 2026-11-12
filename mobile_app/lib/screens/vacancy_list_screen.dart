import 'package:flutter/material.dart';
import '../models/vacancy.dart';
import '../services/api_service.dart';
import 'vacancy_detail_screen.dart';

class VacancyListScreen extends StatefulWidget {
  final int candidateId;

  const VacancyListScreen({super.key, required this.candidateId});

  @override
  State<VacancyListScreen> createState() => _VacancyListScreenState();
}

class _VacancyListScreenState extends State<VacancyListScreen> {
  List<Vacancy> _vacancies = [];
  Set<int> _savedVacancyIds = {};
  bool _isLoading = true;

  String _searchQuery = '';
  String _selectedLocation = 'All';
  String _selectedType = 'All';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      final locParam = _selectedLocation == 'All' ? null : _selectedLocation;
      final typeParam = _selectedType == 'All' ? null : _selectedType;

      final vacancies = await ApiService.getVacancies(
        searchQuery: _searchQuery,
        location: locParam,
        employmentType: typeParam,
      );

      // Saved vacancies should not prevent the main vacancy list from loading.
      Set<int> savedIds = {};

      try {
        final saved = await ApiService.getSavedVacancies(widget.candidateId);

        savedIds = saved.map((s) => s.vacancyId).toSet();
      } catch (e) {
        debugPrint('Failed to load saved vacancies: $e');
      }

      if (!mounted) return;

      setState(() {
        _vacancies = vacancies;
        _savedVacancyIds = savedIds;
      });

      debugPrint('Loaded ${vacancies.length} vacancies');
    } catch (e, stackTrace) {
      debugPrint('Failed to load vacancies: $e');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      setState(() {
        _vacancies = [];
        _savedVacancyIds = {};
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load vacancies: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _toggleSave(int vacancyId) async {
    final isSaved = _savedVacancyIds.contains(vacancyId);
    bool success;
    if (isSaved) {
      success = await ApiService.unsaveVacancy(vacancyId, widget.candidateId);
    } else {
      success = await ApiService.saveVacancy(vacancyId, widget.candidateId);
    }

    if (!context.mounted) return;
    if (success) {
      setState(() {
        if (isSaved) {
          _savedVacancyIds.remove(vacancyId);
        } else {
          _savedVacancyIds.add(vacancyId);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SkillBridge Vacancies'),
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Filter Toolbar
          Container(
            padding: const EdgeInsets.all(12),
            color: const Color(0xFF1E293B),
            child: Column(
              children: [
                TextField(
                  onChanged: (val) {
                    _searchQuery = val;
                    _loadData();
                  },
                  decoration: InputDecoration(
                    hintText: 'Search vacancies or skills...',
                    prefixIcon:
                        const Icon(Icons.search, color: Colors.indigoAccent),
                    filled: true,
                    fillColor: const Color(0xFF0F172A),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButton<String>(
                        value: _selectedLocation,
                        isExpanded: true,
                        dropdownColor: const Color(0xFF1E293B),
                        items: ['All', 'Colombo', 'Kandy', 'Remote']
                            .map((loc) => DropdownMenuItem(
                                  value: loc,
                                  child: Text('Location: $loc',
                                      style: const TextStyle(fontSize: 13)),
                                ))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedLocation = val);
                            _loadData();
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButton<String>(
                        value: _selectedType,
                        isExpanded: true,
                        dropdownColor: const Color(0xFF1E293B),
                        items: ['All', 'Internship', 'FullTime', 'PartTime']
                            .map((t) => DropdownMenuItem(
                                  value: t,
                                  child: Text('Type: $t',
                                      style: const TextStyle(fontSize: 13)),
                                ))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedType = val);
                            _loadData();
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Vacancies List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _vacancies.isEmpty
                    ? const Center(
                        child: Text('No active vacancies match your criteria.'))
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _vacancies.length,
                          itemBuilder: (context, index) {
                            final v = _vacancies[index];
                            final isSaved = _savedVacancyIds.contains(v.id);
                            final isWithdrawn =
                                v.currentApplicationStatus?.toUpperCase() ==
                                    'WITHDRAWN';
                            final isApplied = v.hasApplied && !isWithdrawn;

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
                                            v.title,
                                            style: const TextStyle(
                                              fontSize: 17,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            isSaved
                                                ? Icons.bookmark
                                                : Icons.bookmark_border,
                                            color: isSaved
                                                ? Colors.indigoAccent
                                                : Colors.white54,
                                          ),
                                          onPressed: () => _toggleSave(v.id),
                                        ),
                                      ],
                                    ),

                                    Row(
                                      children: [
                                        const Icon(Icons.business,
                                            size: 14, color: Colors.white70),
                                        const SizedBox(width: 4),
                                        Text(v.companyName,
                                            style: const TextStyle(
                                                color: Colors.white70,
                                                fontSize: 13)),
                                        const SizedBox(width: 16),
                                        const Icon(Icons.location_on,
                                            size: 14, color: Colors.white70),
                                        const SizedBox(width: 4),
                                        Text(v.location,
                                            style: const TextStyle(
                                                color: Colors.white70,
                                                fontSize: 13)),
                                      ],
                                    ),
                                    const SizedBox(height: 10),

                                    Text(
                                      v.description,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          color: Colors.white60, fontSize: 13),
                                    ),
                                    const SizedBox(height: 12),

                                    // Skills Chips
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 4,
                                      children: v.skills.take(4).map((sk) {
                                        return Chip(
                                          label: Text(sk.skillName,
                                              style: const TextStyle(
                                                  fontSize: 11)),
                                          backgroundColor:
                                              const Color(0xFF0F172A),
                                          padding: EdgeInsets.zero,
                                          materialTapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        );
                                      }).toList(),
                                    ),
                                    const SizedBox(height: 14),

                                    // Actions
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        OutlinedButton.icon(
                                          icon: const Icon(Icons.info_outline,
                                              size: 16),
                                          label: const Text('Details'),
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    VacancyDetailScreen(
                                                  vacancy: v,
                                                  candidateId:
                                                      widget.candidateId,
                                                ),
                                              ),
                                            ).then((_) => _loadData());
                                          },
                                        ),
                                        if (isWithdrawn)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.orange
                                                  .withValues(alpha: 0.2),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                  color: Colors.orange),
                                            ),
                                            child: const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.undo,
                                                  color: Colors.orange,
                                                  size: 14,
                                                ),
                                                SizedBox(width: 4),
                                                Text(
                                                  'Withdrawn',
                                                  style: TextStyle(
                                                    color: Colors.orange,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )
                                        else if (isApplied)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.green
                                                  .withValues(alpha: 0.2),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                  color: Colors.green),
                                            ),
                                            child: const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.check_circle,
                                                  color: Colors.green,
                                                  size: 14,
                                                ),
                                                SizedBox(width: 4),
                                                Text(
                                                  'Applied',
                                                  style: TextStyle(
                                                    color: Colors.green,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )
                                        else
                                          ElevatedButton.icon(
                                            icon: const Icon(Icons.send,
                                                size: 16),
                                            label: const Text('Apply Now'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  Colors.indigoAccent,
                                              foregroundColor: Colors.white,
                                            ),
                                            onPressed: () async {
                                              final success = await ApiService
                                                  .applyToVacancy(
                                                v.id,
                                                widget.candidateId,
                                              );

                                              if (!context.mounted) return;

                                              if (success) {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      'Application submitted successfully!',
                                                    ),
                                                  ),
                                                );

                                                _loadData();
                                              }
                                            },
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
          ),
        ],
      ),
    );
  }
}
