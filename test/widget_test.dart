import 'package:flutter_test/flutter_test.dart';
import 'package:smart_drop_alarm/main.dart';

void main() {
  testWidgets('App launches successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const SmartDropAlarmApp(onboardingDone: true));
    expect(find.text('Smart Drop Alarm'), findsOneWidget);
  });
}