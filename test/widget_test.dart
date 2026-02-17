// Basic Flutter widget test for GitSyncMarks app.

import 'package:flutter_test/flutter_test.dart';

import 'package:gitsyncmarks_app/app.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const GitSyncMarksApp());

    expect(find.text('GitSyncMarks'), findsOneWidget);
    expect(find.text('No bookmarks yet'), findsOneWidget);
  });
}
