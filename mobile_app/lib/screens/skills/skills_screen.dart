import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/candidate_profile_provider.dart';
import '../../widgets/empty_state_view.dart';

class SkillsScreen extends StatefulWidget {
  const SkillsScreen({super.key});

  @override
  State<SkillsScreen> createState() => _SkillsScreenState();
}

class _SkillsScreenState extends State<SkillsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<CandidateProfileProvider>().loadTaxonomySkills();
      }
    });
  }

  void _showAddSkillDialog() {
    final provider = context.read<CandidateProfileProvider>();
    final currentSkillIds =
        provider.profile?.skills.map((s) => s.skillId).toSet() ?? {};

    final TextEditingController searchCtrl = TextEditingController();
    int selectedProficiency = 3; // Advanced default

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
            final taxonomy = provider.taxonomySkills;
            final trimmed = searchCtrl.text.trim();

            // Filter taxonomy to matching, unowned skills
            final filtered = taxonomy
                .where((s) =>
                    !currentSkillIds.contains(s.id) &&
                    s.name.toLowerCase().contains(trimmed.toLowerCase()))
                .toList();

            // True when typed name doesn't match any taxonomy entry
            final noExactMatch = trimmed.isNotEmpty &&
                !taxonomy.any(
                  (s) => s.name.toLowerCase() == trimmed.toLowerCase(),
                );

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Header ──────────────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Add Technical Skill',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      IconButton(
                        icon:
                            const Icon(Icons.close, color: AppTheme.textMuted),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // ── Search / type skill name ─────────────────────────────
                  const Text(
                    'Search or type a skill name',
                    style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: searchCtrl,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'e.g. Flutter, Machine Learning…',
                      hintStyle: const TextStyle(
                          color: AppTheme.textMuted, fontSize: 13),
                      prefixIcon: const Icon(Icons.search,
                          color: AppTheme.textMuted, size: 18),
                      filled: true,
                      fillColor: AppTheme.darkBackground,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: AppTheme.darkBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: AppTheme.darkBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppTheme.primary),
                      ),
                    ),
                    onChanged: (_) => setModalState(() {}),
                  ),
                  const SizedBox(height: 12),

                  // ── Matching taxonomy results ───────────────────────────
                  if (filtered.isNotEmpty) ...[
                    const Text(
                      'Matching Skills',
                      style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textMuted,
                          fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: filtered.take(12).map((s) {
                        return ActionChip(
                          label: Text('${s.name} (${s.category})'),
                          labelStyle: const TextStyle(
                              color: AppTheme.primaryLight, fontSize: 12),
                          backgroundColor:
                              AppTheme.primary.withValues(alpha: 0.12),
                          side: BorderSide(
                              color: AppTheme.primary.withValues(alpha: 0.4)),
                          onPressed: () async {
                            final messenger =
                                ScaffoldMessenger.of(this.context);
                            Navigator.pop(ctx);
                            final success = await provider.addSkill(
                              skillId: s.id,
                              proficiencyLevel: selectedProficiency,
                              yearsOfExperience: 1,
                            );
                            if (mounted && success) {
                              messenger.showSnackBar(const SnackBar(
                                content: Text('Skill added successfully!'),
                                backgroundColor: AppTheme.accent,
                              ));
                            }
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // ── Custom skill — "+ Add 'Flutter'" ───────────────────
                  if (noExactMatch) ...[
                    OutlinedButton.icon(
                      icon: const Icon(Icons.add, size: 16),
                      label: Text(
                        'Add "$trimmed"',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.accent,
                        side: const BorderSide(
                            color: AppTheme.accent, style: BorderStyle.solid),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.of(this.context);
                        Navigator.pop(ctx);
                        final success = await provider.createAndAddSkill(
                          skillName: trimmed,
                          proficiencyLevel: selectedProficiency,
                        );
                        if (mounted) {
                          messenger.showSnackBar(SnackBar(
                            content: Text(success
                                ? 'Skill "$trimmed" added!'
                                : (provider.errorMessage ??
                                    'Failed to add skill.')),
                            backgroundColor:
                                success ? AppTheme.accent : AppTheme.error,
                          ));
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                  ],

                  // ── Proficiency slider ─────────────────────────────────
                  Text(
                    'Proficiency Level: ${_getProficiencyText(selectedProficiency)} ($selectedProficiency/5)',
                    style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w600),
                  ),
                  Slider(
                    value: selectedProficiency.toDouble(),
                    min: 1,
                    max: 5,
                    divisions: 4,
                    activeColor: AppTheme.primary,
                    inactiveColor: AppTheme.darkBorder,
                    onChanged: (v) {
                      setModalState(() => selectedProficiency = v.round());
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _getProficiencyText(int level) {
    switch (level) {
      case 1:
        return 'Beginner';
      case 2:
        return 'Intermediate';
      case 3:
        return 'Advanced';
      case 4:
        return 'Expert';
      case 5:
        return 'Master';
      default:
        return 'Level $level';
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CandidateProfileProvider>();
    final skills = provider.profile?.skills ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Skills'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppTheme.primaryLight),
            onPressed: _showAddSkillDialog,
          ),
        ],
      ),
      body: skills.isEmpty
          ? EmptyStateView(
              icon: Icons.code,
              title: 'No Skills Added Yet',
              message:
                  'Adding at least one technical skill is required for profile completeness and job matching.',
              buttonText: 'Add First Skill',
              onButtonPressed: _showAddSkillDialog,
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: skills.length,
              itemBuilder: (context, index) {
                final skill = skills[index];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.code_rounded,
                              color: AppTheme.primaryLight, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                skill.skillName,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primary
                                          .withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      skill.proficiencyLabel,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppTheme.primaryLight,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${skill.yearsOfExperience} yr${skill.yearsOfExperience == 1 ? '' : 's'} exp',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.textMuted),
                                  ),
                                ],
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
                                title: const Text('Remove Skill?'),
                                content: Text(
                                    'Remove "${skill.skillName}" from your profile?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    style: TextButton.styleFrom(
                                        foregroundColor: AppTheme.error),
                                    child: const Text('Remove'),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true) {
                              await provider.removeSkill(skill.skillId);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'skills_fab',
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Skill',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        onPressed: _showAddSkillDialog,
      ),
    );
  }
}
