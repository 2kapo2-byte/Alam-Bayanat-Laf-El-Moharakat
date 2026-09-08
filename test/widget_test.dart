import 'package:flutter_test/flutter_test.dart';
import 'package:alam_bayanat_laf_el_moharakat/main.dart';

void main() {
  testWidgets('app starts with the configuration screen', (tester) async {
    await tester.pumpWidget(const MotorApp());
    expect(find.text(appName), findsOneWidget);
    expect(find.textContaining('SUPABASE_URL'), findsOneWidget);
  });
}
