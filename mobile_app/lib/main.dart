import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/candidate_profile_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/candidate_home_screen.dart';
import 'screens/vacancy_list_screen.dart';
import 'screens/saved_vacancies_screen.dart';
import 'screens/my_applications_screen.dart';
import 'screens/interview_screen.dart';
import 'screens/shortlist_screen.dart';
import 'screens/ai_workflow_screen.dart';
import 'screens/analytics_dashboard_screen.dart';
import 'screens/audit_log_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SkillBridgeApp());
}

// Preserve the incoming public app name as well as existing clients/tests.
class SkillBridgeMobileApp extends SkillBridgeApp {
  const SkillBridgeMobileApp({super.key});
}

class SkillBridgeApp extends StatelessWidget {
  const SkillBridgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
            create: (_) => AuthProvider()..checkAuthStatus()),
      ],
      child: MaterialApp(
        title: 'SkillBridge AI - Candidate App',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        builder: (context, child) =>
            WebMobileShell(child: child ?? const SizedBox()),
        home: const AuthGate(),
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (auth.isInitializing) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.auto_awesome, size: 48, color: AppTheme.primaryLight),
              SizedBox(height: 16),
              CircularProgressIndicator(color: AppTheme.primaryLight),
              SizedBox(height: 12),
              Text(
                'Connecting to SkillBridge AI...',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    if (auth.isAuthenticated) {
      return ChangeNotifierProvider(
        key: ValueKey(auth.currentUser?.token),
        create: (_) => CandidateProfileProvider(),
        child: const MainTabNavigation(),
      );
    }

    return const LoginScreen();
  }
}

/// Responsive Mobile Device Frame Shell for Web Browsers
class WebMobileShell extends StatelessWidget {
  final Widget child;

  const WebMobileShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final isDesktopWeb = media.size.width > 500;

    if (!isDesktopWeb) {
      return child;
    }

    return Container(
      color: const Color(0xFF070A12), // Dark outer desktop background
      child: Center(
        child: Container(
          width: 420,
          height: 840,
          margin: const EdgeInsets.symmetric(vertical: 24),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(40),
            border: Border.all(color: const Color(0xFF334155), width: 10),
            boxShadow: const [
              BoxShadow(
                color: Colors.black54,
                blurRadius: 40,
                spreadRadius: 10,
                offset: Offset(0, 20),
              ),
              BoxShadow(
                color: Color(0x33818CF8),
                blurRadius: 30,
                spreadRadius: 2,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: Stack(
              children: [
                child,
                // Top Speaker / Notch Indicator for authentic Mobile look
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: IgnorePointer(
                    child: Center(
                      child: Container(
                        width: 140,
                        height: 24,
                        decoration: const BoxDecoration(
                          color: Color(0xFF1E293B),
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(16),
                            bottomRight: Radius.circular(16),
                          ),
                        ),
                        child: Center(
                          child: Container(
                            width: 50,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MainTabNavigation extends StatefulWidget {
  const MainTabNavigation({super.key});

  @override
  State<MainTabNavigation> createState() => _MainTabNavigationState();
}

class _MainTabNavigationState extends State<MainTabNavigation> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser!;
    final isStaff = user.role == 'Recruiter' || user.role == 'Administrator';
    final candidateId = user.candidateId;
    final isInterviewer = user.role == 'Interviewer';
    final screens = isInterviewer
        ? <Widget>[const InterviewScreen()]
        : isStaff
            ? <Widget>[
                const ShortlistScreen(),
                const AIWorkflowScreen(),
                const AnalyticsDashboardScreen(),
                const AuditLogScreen(),
                const InterviewScreen(),
              ]
            : <Widget>[
                const CandidateHomeScreen(),
                if (candidateId != null) ...[
                  VacancyListScreen(candidateId: candidateId),
                  SavedVacanciesScreen(candidateId: candidateId),
                  MyApplicationsScreen(candidateId: candidateId),
                  InterviewScreen(candidateId: candidateId),
                  ShortlistScreen(candidateId: candidateId),
                ],
              ];
    final items = isInterviewer
        ? const [
            BottomNavigationBarItem(
                icon: Icon(Icons.calendar_month), label: 'Interviews')
          ]
        : isStaff
            ? const [
                BottomNavigationBarItem(
                    icon: Icon(Icons.list_alt), label: 'Shortlists'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.smart_toy), label: 'AI'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.bar_chart), label: 'Analytics'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.history), label: 'Audit'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.calendar_month), label: 'Interviews'),
              ]
            : [
                const BottomNavigationBarItem(
                    icon: Icon(Icons.person), label: 'My Profile'),
                if (candidateId != null) ...const [
                  BottomNavigationBarItem(
                      icon: Icon(Icons.work), label: 'Vacancies'),
                  BottomNavigationBarItem(
                      icon: Icon(Icons.bookmark), label: 'Saved'),
                  BottomNavigationBarItem(
                      icon: Icon(Icons.send), label: 'Applications'),
                  BottomNavigationBarItem(
                      icon: Icon(Icons.calendar_month), label: 'Interviews'),
                  BottomNavigationBarItem(
                      icon: Icon(Icons.star), label: 'Shortlists'),
                ],
              ];
    return Scaffold(
      appBar: AppBar(
        title: const Text('SkillBridge AI'),
        actions: [
          IconButton(
              onPressed: () async {
                Navigator.of(context, rootNavigator: true)
                    .popUntil((route) => route.isFirst);
                await auth.logout();
              },
              icon: const Icon(Icons.logout),
              tooltip: 'Sign out')
        ],
      ),
      body: screens[_currentIndex],
      bottomNavigationBar: items.length < 2
          ? null
          : BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) => setState(() => _currentIndex = index),
              type: BottomNavigationBarType.fixed,
              items: items,
            ),
    );
  }
}
