/// Public base URL where the customer receipt portal is hosted.
///
/// This is the Firebase Hosting URL of the deployed Flutter web build.
/// Update it if you deploy the portal under a custom domain.
const String kCustomerPortalBaseUrl =
    'https://management-system-6aefa.web.app';

/// Secret mixed into the customer view key so that people who only know a
/// customer ID cannot guess the receipt link.
const String _kCustomerViewSalt = 'PFH-VIEW-KEY-2026';

/// Deterministic key embedded in the QR link. The same customer always gets
/// the same key so previously printed QR codes keep working.
String customerViewKey(String customerId) {
  var hash = 0x811c9dc5;
  final input = '$_kCustomerViewSalt:$customerId';
  for (final codeUnit in input.codeUnits) {
    hash ^= codeUnit & 0xff;
    hash = (hash * 0x01000193) & 0xFFFFFFFF;
    hash ^= (codeUnit >> 8) & 0xff;
    hash = (hash * 0x01000193) & 0xFFFFFFFF;
  }
  return hash.toRadixString(36).padLeft(7, '0');
}

/// The full URL encoded into the customer's QR code.
String customerViewUrl(String customerId) =>
    '$kCustomerPortalBaseUrl/view/$customerId?k=${customerViewKey(customerId)}';
