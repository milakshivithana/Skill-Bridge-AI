import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/validators.dart';
import '../../providers/candidate_profile_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class CvUploadScreen extends StatefulWidget {
  const CvUploadScreen({super.key});

  @override
  State<CvUploadScreen> createState() => _CvUploadScreenState();
}

class _CvUploadScreenState extends State<CvUploadScreen> {
  String? _selectedFilePath;
  String? _selectedFileName;
  int? _selectedFileSize;
  String? _localError;

  Future<void> _pickCvFile() async {
    setState(() => _localError = null);

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.size > 5 * 1024 * 1024) {
          setState(() => _localError =
              'File size exceeds 5MB limit. Please choose a smaller file.');
          return;
        }

        if (file.path != null) {
          setState(() {
            _selectedFilePath = file.path;
            _selectedFileName = file.name;
            _selectedFileSize = file.size;
          });
        }
      }
    } catch (e) {
      setState(() => _localError = 'Error selecting file: $e');
    }
  }

  Future<void> _uploadCv() async {
    if (_selectedFilePath == null) return;

    final provider = context.read<CandidateProfileProvider>();
    final success = await provider.uploadCv(_selectedFilePath!);

    if (!mounted) return;
    if (success) {
      setState(() {
        _selectedFilePath = null;
        _selectedFileName = null;
        _selectedFileSize = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('CV uploaded and parsed successfully!'),
          backgroundColor: AppTheme.accent,
        ),
      );
    }
  }

  void _showAddCertificateDialog() {
    final provider = context.read<CandidateProfileProvider>();
    final formKey = GlobalKey<FormState>();
    final titleCtrl = TextEditingController();
    final orgCtrl = TextEditingController();
    final credIdCtrl = TextEditingController();
    final credUrlCtrl = TextEditingController();

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
                        'Add Verified Certificate',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary),
                      ),
                      IconButton(
                          icon: const Icon(Icons.close,
                              color: AppTheme.textMuted),
                          onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  CustomTextField(
                    controller: titleCtrl,
                    label: 'Certificate Title *',
                    hint: 'e.g. AWS Certified Cloud Practitioner',
                    prefixIcon: Icons.verified_outlined,
                    validator: (v) =>
                        Validators.required(v, 'Title is required'),
                  ),
                  CustomTextField(
                    controller: orgCtrl,
                    label: 'Issuing Organization *',
                    hint: 'e.g. Amazon Web Services, Coursera',
                    prefixIcon: Icons.business_outlined,
                    validator: (v) =>
                        Validators.required(v, 'Organization is required'),
                  ),
                  CustomTextField(
                    controller: credIdCtrl,
                    label: 'Credential ID (Optional)',
                    hint: 'e.g. ABC-12345-XYZ',
                    prefixIcon: Icons.badge_outlined,
                  ),
                  CustomTextField(
                    controller: credUrlCtrl,
                    label: 'Verification URL (Optional)',
                    hint: 'https://credly.com/badges/...',
                    prefixIcon: Icons.link,
                    keyboardType: TextInputType.url,
                    validator: (v) => Validators.url(v, true),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      Navigator.pop(ctx);
                      final messenger = ScaffoldMessenger.of(context);

                      final success = await provider.addCertificate(
                        title: titleCtrl.text,
                        issuingOrganization: orgCtrl.text,
                        issueDate: DateTime.now(),
                        credentialId:
                            credIdCtrl.text.isNotEmpty ? credIdCtrl.text : null,
                        credentialUrl: credUrlCtrl.text.isNotEmpty
                            ? credUrlCtrl.text
                            : null,
                      );

                      if (success) {
                        messenger.showSnackBar(
                          const SnackBar(content: Text('Certificate added!')),
                        );
                      }
                    },
                    child: const Text('Add Certificate'),
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
    final cvDoc = provider.profile?.cvDocument;
    final certs = provider.profile?.certificates ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('CV & Certs'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Error banner
              if (_localError != null || provider.errorMessage != null) ...[
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
                    _localError ?? provider.errorMessage!,
                    style:
                        const TextStyle(color: Color(0xFFFCA5A5), fontSize: 13),
                  ),
                ),
              ],

              // Upload Section
              const Text(
                'Upload Curriculum Vitae (CV) *',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 6),
              const Text(
                'Supported formats: PDF, DOC, DOCX (Maximum 5MB). Required for deterministic profile completeness.',
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 16),

              // Current Uploaded CV card
              if (cvDoc != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.darkSurface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: AppTheme.accent.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.picture_as_pdf,
                            color: AppTheme.accent, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cvDoc.fileName,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${cvDoc.formattedSize} • Uploaded ${DateFormat('MMM d, yyyy').format(cvDoc.uploadedAt)}',
                              style: const TextStyle(
                                  fontSize: 12, color: AppTheme.textMuted),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.accent.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                '✓ Active CV on Profile',
                                style: TextStyle(
                                    fontSize: 10,
                                    color: AppTheme.accent,
                                    fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // File Selection Box
              GestureDetector(
                onTap: _pickCvFile,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.darkBackground,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _selectedFilePath != null
                          ? AppTheme.primary
                          : AppTheme.darkBorder,
                      width: 1.5,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        _selectedFilePath != null
                            ? Icons.file_present_rounded
                            : Icons.cloud_upload_outlined,
                        size: 40,
                        color: _selectedFilePath != null
                            ? AppTheme.primaryLight
                            : AppTheme.textMuted,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _selectedFileName ??
                            'Tap to select PDF/DOCX from device',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _selectedFileName != null
                              ? AppTheme.textPrimary
                              : AppTheme.primaryLight,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (_selectedFileSize != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          '${(_selectedFileSize! / 1024).toStringAsFixed(1)} KB selected',
                          style: const TextStyle(
                              fontSize: 12, color: AppTheme.textMuted),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              if (_selectedFilePath != null) ...[
                const SizedBox(height: 14),
                CustomButton(
                  text: 'Upload and Process CV',
                  icon: Icons.upload,
                  isLoading: provider.isUploadingCv,
                  onPressed: _uploadCv,
                ),
              ],

              const Divider(color: AppTheme.darkBorder, height: 36),

              // Certifications Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Certifications',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary),
                  ),
                  TextButton.icon(
                    onPressed: _showAddCertificateDialog,
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add Cert'),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (certs.isEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.darkSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.darkBorder),
                  ),
                  child: const Center(
                    child: Text(
                      'No certificates added yet (Optional)',
                      style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
                    ),
                  ),
                ),
              ] else ...[
                ...certs.map((cert) {
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.workspace_premium,
                          color: AppTheme.accent),
                      title: Text(cert.title,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 14)),
                      subtitle: Text(
                          '${cert.issuingOrganization} • ${cert.issueDate.year}',
                          style: const TextStyle(
                              fontSize: 12, color: AppTheme.textMuted)),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: AppTheme.error, size: 20),
                        onPressed: () => provider.deleteCertificate(cert.id),
                      ),
                    ),
                  );
                }),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
