import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/candidate_profile_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class PreferencesScreen extends StatefulWidget {
  const PreferencesScreen({super.key});

  @override
  State<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _roleController;
  late TextEditingController _locController;
  late TextEditingController _stipendController;
  String _employmentType = 'Internship';
  bool _openForRelocation = false;
  bool _openForRemote = true;

  @override
  void initState() {
    super.initState();
    final pref = context.read<CandidateProfileProvider>().profile?.preferences;
    _roleController = TextEditingController(text: pref?.preferredRole ?? '');
    _locController = TextEditingController(text: pref?.preferredLocation ?? '');
    _stipendController = TextEditingController(
      text: pref?.minimumExpectedStipend != null
          ? pref!.minimumExpectedStipend!.toStringAsFixed(0)
          : '',
    );
    _employmentType = pref?.employmentType ?? 'Internship';
    _openForRelocation = pref?.openForRelocation ?? false;
    _openForRemote = pref?.openForRemote ?? true;
  }

  @override
  void dispose() {
    _roleController.dispose();
    _locController.dispose();
    _stipendController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<CandidateProfileProvider>();
    final stipend = double.tryParse(_stipendController.text.trim());

    final success = await provider.updatePreferences(
      preferredRole:
          _roleController.text.isNotEmpty ? _roleController.text : null,
      preferredLocation:
          _locController.text.isNotEmpty ? _locController.text : null,
      employmentType: _employmentType,
      minimumExpectedStipend: stipend,
      openForRelocation: _openForRelocation,
      openForRemote: _openForRemote,
    );

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Career preferences saved successfully!'),
          backgroundColor: AppTheme.accent,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CandidateProfileProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Preferences'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Job Matching & Internship Criteria',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryLight,
                  ),
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: _roleController,
                  label: 'Preferred Role / Track',
                  hint: 'e.g. Backend Developer, Full Stack Engineer',
                  prefixIcon: Icons.badge_outlined,
                ),
                CustomTextField(
                  controller: _locController,
                  label: 'Preferred Work Location',
                  hint: 'e.g. Colombo, Kandy, Gampaha',
                  prefixIcon: Icons.place_outlined,
                ),
                const Text(
                  'Employment Type',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: AppTheme.darkBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.darkBorder),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _employmentType,
                      isExpanded: true,
                      dropdownColor: AppTheme.darkSurface,
                      items: const [
                        DropdownMenuItem(
                            value: 'Internship',
                            child: Text('Internship (Undergraduate)')),
                        DropdownMenuItem(
                            value: 'Full-time', child: Text('Full-time')),
                        DropdownMenuItem(
                            value: 'Part-time', child: Text('Part-time')),
                        DropdownMenuItem(
                            value: 'Contract',
                            child: Text('Contract / Freelance')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _employmentType = val);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _stipendController,
                  label: 'Minimum Expected Monthly Stipend (LKR)',
                  hint: 'e.g. 50000',
                  prefixIcon: Icons.payments_outlined,
                  keyboardType: TextInputType.number,
                ),
                const Divider(color: AppTheme.darkBorder, height: 28),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Open for Remote Work',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary)),
                  subtitle: const Text(
                      'Allow matching with remote and hybrid opportunities',
                      style: TextStyle(
                          fontSize: 12, color: AppTheme.textSecondary)),
                  value: _openForRemote,
                  activeThumbColor: AppTheme.accent,
                  onChanged: (val) => setState(() => _openForRemote = val),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Open for Relocation',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary)),
                  subtitle: const Text(
                      'Willing to relocate for on-site placement',
                      style: TextStyle(
                          fontSize: 12, color: AppTheme.textSecondary)),
                  value: _openForRelocation,
                  activeThumbColor: AppTheme.accent,
                  onChanged: (val) => setState(() => _openForRelocation = val),
                ),
                const SizedBox(height: 24),
                CustomButton(
                  text: 'Save Career Preferences',
                  icon: Icons.check,
                  isLoading: provider.isSaving,
                  onPressed: _handleSave,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
