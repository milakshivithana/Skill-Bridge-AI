import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/validators.dart';
import '../../providers/candidate_profile_provider.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/empty_state_view.dart';

class ExperienceScreen extends StatelessWidget {
  const ExperienceScreen({super.key});

  void _showAddExperienceDialog(BuildContext context) {
    final provider = context.read<CandidateProfileProvider>();
    final formKey = GlobalKey<FormState>();
    final companyCtrl = TextEditingController();
    final titleCtrl = TextEditingController();
    final locationCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    DateTime startDate = DateTime.now().subtract(const Duration(days: 365));
    DateTime? endDate;
    bool isCurrent = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
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
                            'Add Work Experience / Internship',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close,
                                color: AppTheme.textMuted),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      CustomTextField(
                        controller: titleCtrl,
                        label: 'Job Title / Role *',
                        hint: 'e.g. Software Engineering Intern',
                        prefixIcon: Icons.work_outline,
                        validator: (val) =>
                            Validators.required(val, 'Job title is required'),
                      ),
                      CustomTextField(
                        controller: companyCtrl,
                        label: 'Company / Organization *',
                        hint: 'e.g. WSO2, IFS, Virtusa',
                        prefixIcon: Icons.business_outlined,
                        validator: (val) => Validators.required(
                            val, 'Company name is required'),
                      ),
                      CustomTextField(
                        controller: locationCtrl,
                        label: 'Location (Optional)',
                        hint: 'e.g. Colombo / Remote',
                        prefixIcon: Icons.location_on_outlined,
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('I currently work in this role',
                            style: TextStyle(
                                fontSize: 14, color: AppTheme.textPrimary)),
                        value: isCurrent,
                        activeThumbColor: AppTheme.accent,
                        onChanged: (val) {
                          setModalState(() {
                            isCurrent = val;
                            if (isCurrent) endDate = null;
                          });
                        },
                      ),
                      CustomTextField(
                        controller: descCtrl,
                        label: 'Responsibilities & Impact',
                        hint:
                            'Developed backend REST APIs using ASP.NET Core and React components...',
                        prefixIcon: Icons.subject_outlined,
                        maxLines: 3,
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () async {
                          if (!formKey.currentState!.validate()) return;
                          Navigator.pop(context);

                          final success = await provider.addExperience(
                            company: companyCtrl.text,
                            title: titleCtrl.text,
                            location: locationCtrl.text.isNotEmpty
                                ? locationCtrl.text
                                : null,
                            startDate: startDate,
                            endDate: endDate,
                            isCurrent: isCurrent,
                            description:
                                descCtrl.text.isNotEmpty ? descCtrl.text : null,
                          );

                          if (context.mounted && success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Experience record saved!')),
                            );
                          }
                        },
                        child: const Text('Save Experience'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CandidateProfileProvider>();
    final experiences = provider.profile?.experiences ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Experience'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppTheme.primaryLight),
            onPressed: () => _showAddExperienceDialog(context),
          ),
        ],
      ),
      body: experiences.isEmpty
          ? EmptyStateView(
              icon: Icons.work_outline,
              title: 'No Work Experience Added',
              message:
                  'Add internships, part-time roles, or project experiences to strengthen your recruiter profile.',
              buttonText: 'Add Experience',
              onButtonPressed: () => _showAddExperienceDialog(context),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: experiences.length,
              itemBuilder: (context, index) {
                final exp = experiences[index];
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
                                color: AppTheme.accent.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.work,
                                  color: AppTheme.accent, size: 22),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    exp.title,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    exp.company,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppTheme.primaryLight,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  if (exp.location != null) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      exp.location!,
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.textMuted),
                                    ),
                                  ],
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
                                    title: const Text('Delete Experience?'),
                                    content: Text(
                                        'Remove "${exp.title} at ${exp.company}"?'),
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
                                  await provider.deleteExperience(exp.id);
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
                              exp.durationText,
                              style: const TextStyle(
                                  fontSize: 12, color: AppTheme.textMuted),
                            ),
                            if (exp.isCurrent)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color:
                                      AppTheme.accent.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'Current Role',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.accent,
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                          ],
                        ),
                        if (exp.description != null &&
                            exp.description!.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Text(
                            exp.description!,
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                                height: 1.4),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'experience_fab',
        backgroundColor: AppTheme.accent,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Experience',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        onPressed: () => _showAddExperienceDialog(context),
      ),
    );
  }
}
