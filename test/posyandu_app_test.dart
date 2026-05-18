import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/main.dart';

void main() {
  testWidgets('login screen uses PRD fields and ethical app language', (
    tester,
  ) async {
    await tester.pumpWidget(const PosyanduApp());

    expect(find.text('Posyandu Desa'), findsOneWidget);
    expect(find.text('NIK / NIP'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Masuk'), findsOneWidget);
    expect(find.textContaining('Diagnosis'), findsNothing);
    expect(find.textContaining('Anak stunting'), findsNothing);
  });

  testWidgets(
    'kader shell shows session, measurement, screening, and notification flow',
    (tester) async {
      await tester.pumpWidget(const PosyanduApp(initialRole: UserRole.kader));

      expect(find.text('Sesi hari ini'), findsOneWidget);
      expect(find.text('Input Pengukuran'), findsOneWidget);
      expect(find.text('Simpan & Lanjut'), findsOneWidget);
      expect(find.text('Perlu perhatian'), findsWidgets);
      expect(
        find.text('Pengukuran tersimpan. Prediksi diproses di belakang.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'bidan shell shows referral validation, PMT, and reports without kader-only actions',
    (tester) async {
      await tester.pumpWidget(const PosyanduApp(initialRole: UserRole.bidan));

      expect(find.text('Rujukan masuk'), findsOneWidget);
      expect(find.text('Validasi Medis'), findsOneWidget);
      expect(find.text('PMT'), findsWidgets);
      expect(find.text('Download PDF'), findsOneWidget);
      expect(find.text('Simpan & Lanjut'), findsNothing);
    },
  );

  testWidgets('theme avoids default purple material seed', (tester) async {
    await tester.pumpWidget(const PosyanduApp(initialRole: UserRole.kader));
    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));

    expect(materialApp.theme?.colorScheme.primary, const Color(0xFF4E6F5C));
    expect(materialApp.theme?.scaffoldBackgroundColor, const Color(0xFFF8F4EC));
  });
}
