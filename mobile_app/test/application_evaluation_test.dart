import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/models/application.dart';
import 'package:mobile_app/widgets/application_evaluation_panel.dart';

void main() {
  CandidateApplication application(String status, {bool evaluated = false}) =>
      CandidateApplication.fromJson({
        'id': 1,
        'status': status,
        if (evaluated)
          'evaluation': {
            'matchScore': 0,
            'evidence': {
              'matched_required_skills': <String>[],
              'missing_required_skills': ['React'],
              'reasoning': 'No declared skill overlap',
            }
          },
      });
  testWidgets('Pending application displays saved zero score and evidence',
      (tester) async {
    final app = application('PENDING_RECRUITER_APPROVAL', evaluated: true);
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: ApplicationEvaluationPanel(
                application: app, isEvaluating: false))));
    expect(find.text('Match Score: 0.0%'), findsOneWidget);
    expect(find.text('Missing required skills: React'), findsOneWidget);
    expect(
        find.text('Awaiting recruiter review and approval.'), findsOneWidget);
    expect(find.text('Run Agentic AI Evaluation'), findsNothing);
  });
  testWidgets(
      'Unevaluated submission has action; loading prevents duplicate submissions',
      (tester) async {
    var calls = 0;
    final app = application('SUBMITTED');
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: ApplicationEvaluationPanel(
                application: app,
                isEvaluating: false,
                onEvaluate: () => calls++))));
    expect(find.text('AI evaluation has not been run yet'), findsOneWidget);
    expect(find.textContaining('Match Score:'), findsNothing);
    await tester.tap(find.text('Run Agentic AI Evaluation'));
    expect(calls, 1);
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: ApplicationEvaluationPanel(
                application: app,
                isEvaluating: true,
                onEvaluate: () => calls++))));
    expect(tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
        isNull);
  });
  testWidgets('Withdrawn application retains evaluation with no run action',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: ApplicationEvaluationPanel(
                application: application('WITHDRAWN', evaluated: true),
                isEvaluating: false))));
    expect(find.text('Match Score: 0.0%'), findsOneWidget);
    expect(find.byType(ElevatedButton), findsNothing);
  });
}
