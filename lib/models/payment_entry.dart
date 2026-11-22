/// A single recorded payment shown in a customer's payment history.
class PaymentEntry {
  final String id;
  final int amountCentavos;
  final int balanceAfterCentavos;
  final DateTime? recordedAt;
  final String note;
  final String recordedByEmail;

  const PaymentEntry({
    required this.id,
    required this.amountCentavos,
    required this.balanceAfterCentavos,
    this.recordedAt,
    this.note = '',
    this.recordedByEmail = '',
  });

  double get amount => amountCentavos / 100.0;

  double get balanceAfter => balanceAfterCentavos / 100.0;
}
