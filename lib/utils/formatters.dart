import 'package:intl/intl.dart';

final NumberFormat _amountFormat = NumberFormat('#,##0.00');
final NumberFormat _intFormat = NumberFormat('#,##0');

/// "1234567.5" -> "1,234,567.50" with the peso sign.
String formatPeso(num amount) => '₱${_amountFormat.format(amount)}';

/// 1000000 -> "1,000,000".
String formatNumber(num value) => _intFormat.format(value);

/// Capitalizes the first letter of every sentence ("hello there. ok" ->
/// "Hello there. Ok").
String capitalizeSentences(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return trimmed;
  final buffer = StringBuffer();
  var capitalizeNext = true;
  for (final char in trimmed.split('')) {
    if (capitalizeNext && char != ' ') {
      buffer.write(char.toUpperCase());
      capitalizeNext = false;
    } else {
      buffer.write(char);
    }
    if (char == '.' || char == '!' || char == '?') capitalizeNext = true;
  }
  return buffer.toString();
}
