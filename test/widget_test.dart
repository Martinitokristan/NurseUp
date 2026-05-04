import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nurseup/main.dart';

void main() {
  testWidgets('NurseUp app starts', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    expect(find.text('AI-powered nursing study companion'), findsOneWidget);
  });
}
