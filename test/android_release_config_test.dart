import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('release manifest allows network access', () {
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();

    expect(
      manifest,
      contains('android.permission.INTERNET'),
      reason: 'APK rilis harus dapat terhubung ke Laravel API.',
    );
  });

  test('Firebase Android client matches the application id', () {
    final config = jsonDecode(
      File('android/app/google-services.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final clients = config['client'] as List<dynamic>;
    final packageNames = clients
        .map(
          (client) =>
              client['client_info']['android_client_info']['package_name'],
        )
        .toSet();

    expect(packageNames, contains('com.whoisr.posyandu_ml'));
  });
}
