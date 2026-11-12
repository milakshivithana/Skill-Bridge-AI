import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/candidate_profile_provider.dart';
import '../../widgets/completeness_banner.dart';
import 'edit_profile_screen.dart';
import '../skills/skills_screen.dart';
import '../education/education_screen.dart';
import '../experience/experience_screen.dart';
import '../preferences/preferences_screen.dart';
import '../cv/cv_upload_screen.dart';

class CandidateProfileScreen extends StatefulWidget {
  const CandidateProfileScreen({super.key});

  @override
  State<CandidateProfileScreen> createState() => _CandidateProfileScreenState();
}

class _CandidateProfileScreenState extends State<CandidateProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<CandidateProfileProvider>().loadProfile();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final profileProvider = context.watch<CandidateProfileProvider>();
    final profile = profileProvider.profile;
    final completeness = profileProvider.completeness;

    final candidateName = profile?.fullName.isNotEmpty == true
        ? profile!.fullName
        : (auth.currentUser?.name.isNotEmpty == true
            ? auth.currentUser!.name
            : 'Candidate');
    final candidateEmail = profile?.email.isNotEmpty == true
        ? profile!.email
        : (auth.currentUser?.email ?? '');
    final initialLetter =
        candidateName.isNotEmpty ? candidateName[0].toUpperCase() : 'C';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Profile & Skills',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.textSecondary),
            tooltip: 'Refresh Profile',
            onPressed: () => profileProvider.loadProfile(),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: AppTheme.error),
            tooltip: 'Logout',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: AppTheme.darkSurface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: AppTheme.darkBorder),
                  ),
                  title: const Text('Sign Out'),
                  content: const Text(
                      'Are you sure you want to sign out from SkillBridge AI?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style:
                          TextButton.styleFrom(foregroundColor: AppTheme.error),
                      child: const Text('Sign Out'),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                if (context.mounted) {
                  Navigator.of(context, rootNavigator: true)
                      .popUntil((route) => route.isFirst);
                }
                await auth.logout();
              }
            },
          ),
        ],
      ),
      body: profileProvider.isLoading && profile == null
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryLight),
            )
          : RefreshIndicator(
              onRefresh: () => profileProvider.loadProfile(),
              color: AppTheme.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Subtitle banner matching React header
                    Padding(
                      padding: const EdgeInsets.only(
                          left: 18, right: 18, top: 8, bottom: 4),
                      child: Text(
                        'Manage your candidate profile, skills, education, experience, and CV.',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary.withValues(alpha: 0.9),
                          height: 1.3,
                        ),
                      ),
                    ),

                    // Profile Header Card (Candidate Identity)
                    Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.darkSurface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.darkBorder),
                      ),
                      child: Row(
                        children: [
                          // Gradient avatar matching React linear-gradient(135deg, #6366f1, #06b6d4)
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              gradient: AppTheme.brandGradient,
                              borderRadius: BorderRadius.circular(26),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      AppTheme.primary.withValues(alpha: 0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                initialLetter,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        candidateName,
                                        style: const TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w800,
                                          color: AppTheme.textPrimary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppTheme.cyanAccent
                                            .withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: AppTheme.cyanAccent
                                              .withValues(alpha: 0.35),
                                        ),
                                      ),
                                      child: const Text(
                                        'Candidate',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.cyanAccent,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  candidateEmail,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppTheme.textSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if ((profile?.phone?.isNotEmpty == true) ||
                                    (profile?.city?.isNotEmpty == true)) ...[
                                  const SizedBox(height: 6),
                                  Wrap(
                                    spacing: 10,
                                    runSpacing: 4,
                                    children: [
                                      if (profile?.city?.isNotEmpty == true)
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.location_on,
                                                size: 13,
                                                color: AppTheme.cyanAccent),
                                            const SizedBox(width: 3),
                                            Text(
                                              profile!.city!,
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  color:
                                                      AppTheme.textSecondary),
                                            ),
                                          ],
                                        ),
                                      if (profile?.phone?.isNotEmpty == true)
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.phone,
                                                size: 13,
                                                color: AppTheme.primaryLight),
                                            const SizedBox(width: 3),
                                            Text(
                                              profile!.phone!,
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  color:
                                                      AppTheme.textSecondary),
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          IconButton(
                            icon: const Icon(
                              Icons.edit_outlined,
                              color: AppTheme.primaryLight,
                              size: 20,
                            ),
                            tooltip: 'Edit Personal Details',
                            onPressed: () {
                              _openWithProfileProvider(
                                  const EditProfileScreen());
                            },
                          ),
                        ],
                      ),
                    ),

                    // Deterministic Completeness Widget
                    CompletenessBanner(
                      completeness: completeness,
                      onRefresh: () => profileProvider.refreshCompleteness(),
                    ),

                    // Bio display if available
                    if (profile?.bio != null && profile!.bio!.isNotEmpty) ...[
                      Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.darkSurface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppTheme.darkBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.format_quote,
                                    size: 16, color: AppTheme.primaryLight),
                                SizedBox(width: 6),
                                Text(
                                  'Bio / Professional Summary',
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.textMuted),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              profile.bio!,
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textPrimary,
                                  height: 1.4),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 10),
                    const Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                      child: Text(
                        'Profile Sections',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryLight,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),

                    // 1. Personal Details
                    _buildSectionTile(
                      context,
                      icon: Icons.person_outline,
                      title: 'Personal Details',
                      subtitle: (profile?.phone != null &&
                              profile!.phone!.isNotEmpty)
                          ? '${profile.phone} • ${profile.city ?? "No city set"}'
                          : 'Phone, City, Bio, Social links',
                      isComplete: profile?.phone?.isNotEmpty == true &&
                          profile?.city?.isNotEmpty == true &&
                          profile?.bio?.isNotEmpty == true,
                      onTap: () {
                        _openWithProfileProvider(const EditProfileScreen());
                      },
                    ),

                    // 2. Skills
                    _buildSectionTile(
                      context,
                      icon: Icons.code,
                      title: 'Skills',
                      subtitle: (profile?.skills.isNotEmpty == true)
                          ? '${profile!.skills.length} skills declared (${profile.skills.take(3).map((s) => s.skillName).join(", ")})'
                          : 'Add technical & soft skills for job matching',
                      isComplete: (profile?.skills.length ?? 0) > 0,
                      onTap: () {
                        _openWithProfileProvider(const SkillsScreen());
                      },
                    ),

                    // 3. Education
                    _buildSectionTile(
                      context,
                      icon: Icons.school_outlined,
                      title: 'Education',
                      subtitle: (profile?.educations.isNotEmpty == true)
                          ? '${profile!.educations.length} qualifications • ${profile.educations.first.degree} (${profile.educations.first.startYear} - ${profile.educations.first.endYear})'
                          : 'Add degree, institution, and graduation years',
                      isComplete: (profile?.educations.length ?? 0) > 0,
                      onTap: () {
                        _openWithProfileProvider(const EducationScreen());
                      },
                    ),

                    // 4. Experience
                    _buildSectionTile(
                      context,
                      icon: Icons.work_outline,
                      title: 'Experience',
                      subtitle: (profile?.experiences.isNotEmpty == true)
                          ? '${profile!.experiences.length} experiences • ${profile.experiences.first.title} at ${profile.experiences.first.company}'
                          : 'Internships and work experience (Optional)',
                      isComplete: (profile?.experiences.length ?? 0) > 0,
                      onTap: () {
                        _openWithProfileProvider(const ExperienceScreen());
                      },
                    ),

                    // 5. Preferences
                    _buildSectionTile(
                      context,
                      icon: Icons.tune,
                      title: 'Preferences',
                      subtitle: profile?.preferences?.preferredRole != null
                          ? '${profile!.preferences!.preferredRole} (${profile.preferences?.employmentType ?? "Internship"})'
                          : 'Target role, stipend, remote & relocation',
                      isComplete: profile?.preferences != null,
                      onTap: () {
                        _openWithProfileProvider(const PreferencesScreen());
                      },
                    ),

                    // 6. CV & Certs
                    _buildSectionTile(
                      context,
                      icon: Icons.file_present_outlined,
                      title: 'CV & Certs',
                      subtitle: profile?.cvDocument != null
                          ? '${profile!.cvDocument!.fileName} • ${profile.certificates.length} certs'
                          : 'Upload PDF CV (Mandatory for eligibility)',
                      isComplete: profile?.cvDocument != null,
                      onTap: () {
                        _openWithProfileProvider(const CvUploadScreen());
                      },
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  void _openWithProfileProvider(Widget screen) {
    final profileProvider = context.read<CandidateProfileProvider>();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider<CandidateProfileProvider>.value(
          value: profileProvider,
          child: screen,
        ),
      ),
    );
  }

  Widget _buildSectionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isComplete,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: AppTheme.darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppTheme.darkBorder),
        ),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppTheme.primaryLight, size: 22),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isComplete ? Icons.check_circle : Icons.radio_button_unchecked,
                size: 18,
                color: isComplete ? AppTheme.accent : AppTheme.textMuted,
              ),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right,
                  color: AppTheme.textMuted, size: 20),
            ],
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}
