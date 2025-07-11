import 'package:cloud_firestore/cloud_firestore.dart';

class AppSettingsService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Fetches the QR scan cooldown in minutes from Firestore app_settings/app_settings.
  /// Returns [defaultValue] if not set or on error.
  static Future<int> getQrScanCooldownMinutes({int defaultValue = 240}) async {
    try {
      final doc = await _firestore.collection('Settings').doc('app_settings').get();
      if (doc.exists && doc.data() != null && doc.data()!.containsKey('qr_scan_cooldown_minutes')) {
        return doc.data()!['qr_scan_cooldown_minutes'] as int;
      }
    } catch (_) {}
    return defaultValue;
  }
} 