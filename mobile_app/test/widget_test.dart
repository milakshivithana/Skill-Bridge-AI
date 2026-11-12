import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_app/main.dart';
import 'package:mobile_app/models/user_model.dart';
import 'package:mobile_app/screens/auth/login_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
      'Missing candidate identity never falls back to the user ID or a demo account',
      () {
    expect(UserModel.fromJson({'userId': 102, 'role': 'Candidate'}).candidateId,
        isNull);
    final candidate = UserModel.fromJson(
        {'userId': 102, 'candidateId': '7', 'email': 'candidate@example.test'});
    expect(candidate.candidateId, 7);
    expect(UserModel.fromJson(candidate.toJson()).candidateId, 7);
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    const MethodChannel channel =
        MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      return null;
    });
  });

  testWidgets('SkillBridgeApp existing entry point renders', (tester) async {
    await tester.pumpWidget(const SkillBridgeApp());
    expect(find.byType(MaterialApp), findsOneWidget);
    await tester.pumpAndSettle();
  });

  testWidgets(
      'SkillBridgeMobileApp smoke test – renders MaterialApp without error',
      (WidgetTester tester) async {
    await tester.pumpWidget(const SkillBridgeMobileApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets(
      'SkillBridgeMobileApp – renders LoginScreen for unauthenticated candidates',
      (WidgetTester tester) async {
    await tester.pumpWidget(const SkillBridgeMobileApp());
    await tester.pump();
    await tester.pump();

    // Verify LoginScreen is shown as entry gate when unauthenticated
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Sign In to SkillBridge'), findsOneWidget);
    expect(find.text('Candidate Portal & Career Management'), findsOneWidget);
  });
}
