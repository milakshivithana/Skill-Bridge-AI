import 'package:flutter/material.dart';
import '../models/vacancy.dart';
import '../services/api_service.dart';

class SavedVacanciesScreen extends StatefulWidget {
  final int candidateId;

  const SavedVacanciesScreen({super.key, required this.candidateId});

  @override
  State<SavedVacanciesScreen> createState() => _SavedVacanciesScreenState();
}

class _SavedVacanciesScreenState extends State<SavedVacanciesScreen> {
  List<SavedVacancy> _savedList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSavedVacancies();
  }

  Future<void> _loadSavedVacancies() async {
    setState(() => _isLoading = true);
    final saved = await ApiService.getSavedVacancies(widget.candidateId);
    if (mounted) {
      setState(() {
        _savedList = saved;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleRemove(int vacancyId) async {
    final success =
        await ApiService.unsaveVacancy(vacancyId, widget.candidateId);
    if (success) {
      _loadSavedVacancies();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Vacancies'),
        backgroundColor: const Color(0xFF0F172A),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _savedList.isEmpty
              ? const Center(child: Text('No bookmarked vacancies.'))
              : RefreshIndicator(
                  onRefresh: _loadSavedVacancies,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _savedList.length,
                    itemBuilder: (context, index) {
                      final item = _savedList[index];

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        color: const Color(0xFF1E293B),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: Colors.white10),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: const CircleAvatar(
                            backgroundColor: Colors.indigo,
                            child: Icon(Icons.bookmark, color: Colors.white),
                          ),
                          title: Text(
                            item.vacancyTitle,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                          subtitle: Text(
                            '${item.companyName} • ${item.location} (${item.employmentType})',
                            style: const TextStyle(
                                color: Colors.white60, fontSize: 12),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: Colors.redAccent),
                            onPressed: () => _handleRemove(item.vacancyId),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
