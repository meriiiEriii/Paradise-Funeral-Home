/// Validates a Philippine mobile number.
///
/// Accepted: 11 digits starting with "09" (e.g. 09171234567). Spaces and
/// dashes inside the number are ignored.
String? validateContactNumber(String? value) {
  final raw = (value ?? '').trim();
  if (raw.isEmpty) {
    return 'Contact number is required.';
  }
  final digits = raw.replaceAll(RegExp(r'\D'), '');
  if (digits.length != 11) {
    return 'Enter exactly 11 digits (e.g. 09171234567).';
  }
  if (!digits.startsWith('09')) {
    return 'Philippine mobile numbers start with 09 (e.g. 09171234567).';
  }
  return null;
}
