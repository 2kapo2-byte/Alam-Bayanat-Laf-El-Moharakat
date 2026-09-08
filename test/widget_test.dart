import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:alam_bayanat_laf_el_moharakat/main.dart';

void main() {
  testWidgets('configuration screen renders', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ConfigPage()));
    expect(find.text(appName), findsOneWidget);
    expect(find.textContaining('SUPABASE_URL'), findsOneWidget);
  });
}
