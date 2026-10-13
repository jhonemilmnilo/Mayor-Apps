import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mayor_apps/main.dart';

void main() {
  testWidgets('MayorApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MayorApp(),
      ),
    );
    expect(find.byType(MayorApp), findsOneWidget);
    await tester.pumpAndSettle();
  });
}
