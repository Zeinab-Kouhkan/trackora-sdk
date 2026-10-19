import 'package:flutter_test/flutter_test.dart';
import 'package:trackora/trackora.dart';
import 'package:trackora_example/main.dart';

void main() {
  setUp(() async {
    Trackora.resetForTesting();
    await Trackora.initialize();
  });

  tearDown(() {
    Trackora.resetForTesting();
  });

  testWidgets('TrackoraExampleApp renders dashboard and elements',
      (WidgetTester tester) async {
    await tester.pumpWidget(const TrackoraExampleApp());
    await tester.pumpAndSettle();

    expect(find.text('Trackora Attribution SDK'), findsOneWidget);
    expect(find.text('Runtime Environment'), findsOneWidget);
    expect(find.text('Campaign URL & Deep Link Simulator'), findsOneWidget);
    expect(find.text('Parse Campaign URL'), findsOneWidget);
  });
}
