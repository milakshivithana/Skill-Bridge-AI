import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/validators.dart';
import '../../providers/candidate_profile_provider.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/empty_state_view.dart';

class EducationScreen extends StatelessWidget {
  const EducationScreen({super.key});

  void _showAddEducationDialog(BuildContext context) {
    final provider = context.read<CandidateProfileProvider>();
    final formKey = GlobalKey<FormState>();
    final instCtrl = TextEditingController();
    final degreeCtrl = TextEditingController();
    final fieldCtrl = TextEditingController();
    final startYearCtrl =
        TextEditingController(text: DateTime.now().year.toString());
    final endYearCtrl = TextEditingController();
    final gradeCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Add Education Qualification',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary),
                      ),
                      IconButton(
                        icon:
                            const Icon(Icons.close, color: AppTheme.textMuted),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  CustomTextField(
                    controller: instCtrl,
                    label: 'Institution / University *',
                    hint: 'e.g. SLIIT, University of Colombo',
                    prefixIcon: Icons.school_outlined,
                    validator: (val) => Validators.required(
                        val, 'Institution name is required'),
                  ),
                  CustomTextField(
                    controller: degreeCtrl,
                    label: 'Degree / Certificate *',
                    hint: 'e.g. BSc (Hons) in Information Technology',
                    prefixIcon: Icons.workspace_premium_outlined,
                    validator: (val) =>
                        Validators.required(val, 'Degree name is required'),
                  ),
                  CustomTextField(
                    controller: fieldCtrl,
                    label: 'Field of Study *',
                    hint: 'e.g. Software Engineering',
                    prefixIcon: Icons.menu_book_outlined,
                    validator: (val) =>
                        Validators.required(val, 'Field of study is required'),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          controller: startYearCtrl,
                          label: 'Start Year *',
                          hint: '2022',
                          keyboardType: TextInputType.number,
                          validator: (val) {
                            if (val == null || val.trim().isEmpty)
                              return 'Required';
                            final y = int.tryParse(val.trim());
                            if (y == null || y < 1950 || y > 2100)
                              return '1950-2100';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomTextField(
                          controller: endYearCtrl,
                          label: 'End Year *',
                          hint: '2026',
                          keyboardType: TextInputType.number,
                          validator: (val) {
                            if (val == null || val.trim().isEmpty)
                              return 'Required';
                            final y = int.tryParse(val.trim());
                            if (y == null || y < 1950 || y > 2100)
                              return '1950-2100';
                            final s = int.tryParse(startYearCtrl.text.trim());
                            if (s != null && y < s) return '>= Start';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  CustomTextField(
                    controller: gradeCtrl,
                    label: 'GPA / Grade (Optional)',
                    hint: 'e.g. 3.82 GPA or First Class',
                    prefixIcon: Icons.grade_outlined,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      Navigator.pop(ctx);

                      final startYear =
                          int.tryParse(startYearCtrl.text.trim()) ??
                              DateTime.now().year;
                      final endYear =
                          int.tryParse(endYearCtrl.text.trim()) ?? startYear;

                      final success = await provider.addEducation(
                        institution: instCtrl.text,
                        degree: degreeCtrl.text,
                        fieldOfStudy: fieldCtrl.text,
                        startYear: startYear,
                        endYear: endYear,
                        grade:
                            gradeCtrl.text.isNotEmpty ? gradeCtrl.text : null,
                      );

                      if (context.mounted && success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Education qualification saved!')),
                        );
                      }
                    },
                    child: const Text('Save Education'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CandidateProfileProvider>();
    final educations = provider.profile?.educations ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Education'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppTheme.primaryLight),
            onPressed: () => _showAddEducationDialog(context),
          ),
        ],
      ),
      body: educations.isEmpty
          ? EmptyStateView(
              icon: Icons.school_outlined,
              title: 'No Education Records',
              message:
                  'Adding at least one academic qualification is mandatory to reach 100% profile completeness.',
              buttonText: 'Add Education',
              onButtonPressed: () => _showAddEducationDialog(context),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: educations.length,
              itemBuilder: (context, index) {
                final edu = educations[index];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.school,
                                  color: AppTheme.primaryLight, size: 22),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    edu.degree,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    edu.institution,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppTheme.primaryLight,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    edu.fieldOfStudy,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  color: AppTheme.error, size: 20),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    backgroundColor: AppTheme.darkSurface,
                                    title: const Text('Delete Education?'),
                                    content: Text(
                                        'Remove "${edu.degree}" from your profile?'),
                                    actions: [
                                      TextButton(
                                          onPressed: () =>
                                              Navigator.pop(ctx, false),
                                          child: const Text('Cancel')),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, true),
                                        style: TextButton.styleFrom(
                                            foregroundColor: AppTheme.error),
                                        child: const Text('Delete'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  await provider.deleteEducation(edu.id);
                                }
                              },
                            ),
                          ],
                        ),
                        const Divider(color: AppTheme.darkBorder, height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              edu.yearRange,
                              style: const TextStyle(
                                  fontSize: 12, color: AppTheme.textMuted),
                            ),
                            if (edu.grade != null && edu.grade!.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color:
                                      AppTheme.accent.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  edu.grade!,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.accent,
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'education_fab',
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Degree',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        onPressed: () => _showAddEducationDialog(context),
      ),
    );
  }
}
