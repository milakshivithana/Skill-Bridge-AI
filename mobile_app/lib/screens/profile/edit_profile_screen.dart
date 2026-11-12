import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/validators.dart';
import '../../providers/candidate_profile_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _phoneController;
  late TextEditingController _cityController;
  late TextEditingController _bioController;
  late TextEditingController _linkedinController;
  late TextEditingController _portfolioController;
  late TextEditingController _gitHubController;

  @override
  void initState() {
    super.initState();
    final profile = context.read<CandidateProfileProvider>().profile;
    _phoneController = TextEditingController(text: profile?.phone ?? '');
    _cityController = TextEditingController(text: profile?.city ?? '');
    _bioController = TextEditingController(text: profile?.bio ?? '');
    _linkedinController =
        TextEditingController(text: profile?.linkedinUrl ?? '');
    _portfolioController =
        TextEditingController(text: profile?.portfolioUrl ?? '');
    _gitHubController = TextEditingController(text: profile?.gitHubUrl ?? '');
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _cityController.dispose();
    _bioController.dispose();
    _linkedinController.dispose();
    _portfolioController.dispose();
    _gitHubController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<CandidateProfileProvider>();
    final success = await provider.updatePersonalDetails(
      phone: _phoneController.text.trim(),
      city: _cityController.text.trim(),
      bio: _bioController.text.trim(),
      linkedinUrl: _linkedinController.text.trim(),
      portfolioUrl: _portfolioController.text.trim(),
      gitHubUrl: _gitHubController.text.trim(),
    );

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Profile saved successfully! Completeness score updated.'),
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
        title: const Text('Personal Details'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (provider.errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppTheme.error.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: AppTheme.error.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      provider.errorMessage!,
                      style: const TextStyle(
                          color: Color(0xFFFCA5A5), fontSize: 13),
                    ),
                  ),
                ],
                const Text(
                  'Mandatory Profile Fields',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryLight,
                  ),
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: _phoneController,
                  label: 'Phone Number *',
                  hint: '+94 77 123 4567',
                  prefixIcon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  validator: Validators.phone,
                ),
                CustomTextField(
                  controller: _cityController,
                  label: 'City / Location *',
                  hint: 'e.g. Colombo, Kandy',
                  prefixIcon: Icons.location_on_outlined,
                  validator: (val) => Validators.required(
                      val, 'City is required for recruitment matching'),
                ),
                CustomTextField(
                  controller: _bioController,
                  label: 'Professional Summary / Bio *',
                  hint:
                      'Share a summary of your career focus, technical passions, and background...',
                  prefixIcon: Icons.description_outlined,
                  maxLines: 4,
                  validator: (val) =>
                      Validators.required(val, 'Professional bio is required'),
                ),
                const Divider(color: AppTheme.darkBorder, height: 32),
                const Text(
                  'Online Presence & Links (Optional)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryLight,
                  ),
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: _linkedinController,
                  label: 'LinkedIn Profile URL',
                  hint: 'https://linkedin.com/in/username',
                  prefixIcon: Icons.link,
                  keyboardType: TextInputType.url,
                  validator: (val) => Validators.url(val, true),
                ),
                CustomTextField(
                  controller: _gitHubController,
                  label: 'GitHub Profile URL',
                  hint: 'https://github.com/username',
                  prefixIcon: Icons.code,
                  keyboardType: TextInputType.url,
                  validator: (val) => Validators.url(val, true),
                ),
                CustomTextField(
                  controller: _portfolioController,
                  label: 'Portfolio Website URL',
                  hint: 'https://alexsilva.dev',
                  prefixIcon: Icons.public,
                  keyboardType: TextInputType.url,
                  validator: (val) => Validators.url(val, true),
                ),
                const SizedBox(height: 12),
                CustomButton(
                  text: 'Save Details',
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
