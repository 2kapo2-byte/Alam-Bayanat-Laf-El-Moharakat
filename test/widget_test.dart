import 'package:flutter_test/flutter_test.dart';
import 'package:alam_bayanat_laf_el_moharakat/main.dart';

void main() {
  testWidgets('app starts in Arabic RTL', (tester) async {
    await tester.pumpWidget(const MotorApp());
    expect(find.text(appName), findsOneWidget);
    expect(find.text('الرئيسية'), findsOneWidget);
    expect(find.text('السجل'), findsOneWidget);
    expect(find.text('إضافة'), findsOneWidget);
  });
}
