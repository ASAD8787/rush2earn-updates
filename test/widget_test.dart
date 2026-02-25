import 'package:flutter_test/flutter_test.dart';
import 'package:rush2earn/app.dart';

void main() {
  testWidgets('Splash screen renders brand text', (WidgetTester tester) async {
    await tester.pumpWidget(const Rush2EarnApp());
    expect(find.text('rush2earn'), findsOneWidget);
  });
}
