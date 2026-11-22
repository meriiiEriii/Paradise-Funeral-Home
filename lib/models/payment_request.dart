enum PaymentRequestStatus { pending, approved, rejected }

extension PaymentRequestStatusX on PaymentRequestStatus {
  String get value => name;

  String get label {
    switch (this) {
      case PaymentRequestStatus.pending:
        return 'Pending';
      case PaymentRequestStatus.approved:
        return 'Approved';
      case PaymentRequestStatus.rejected:
        return 'Rejected';
    }
  }

  static PaymentRequestStatus fromValue(String? value) {
    return PaymentRequestStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => PaymentRequestStatus.pending,
    );
  }
}

/// A staff-submitted payment awaiting administrator approval.
class PaymentRequest {
  final String id;
  final String customerId;
  final String customerName;
  final int amountCentavos;

  /// 'partial' or 'full', computed from the customer's balance at request
  /// time.
  final String kind;
  final String note;
  final PaymentRequestStatus status;
  final String requestedByUid;
  final String requestedByEmail;
  final DateTime requestedAt;
  final String? reviewedByEmail;
  final DateTime? reviewedAt;

  const PaymentRequest({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.amountCentavos,
    required this.kind,
    this.note = '',
    this.status = PaymentRequestStatus.pending,
    required this.requestedByUid,
    this.requestedByEmail = '',
    required this.requestedAt,
    this.reviewedByEmail,
    this.reviewedAt,
  });

  double get amount => amountCentavos / 100.0;

  bool get isPending => status == PaymentRequestStatus.pending;

  PaymentRequest copyWith({
    PaymentRequestStatus? status,
    String? reviewedByEmail,
    DateTime? reviewedAt,
  }) {
    return PaymentRequest(
      id: id,
      customerId: customerId,
      customerName: customerName,
      amountCentavos: amountCentavos,
      kind: kind,
      note: note,
      status: status ?? this.status,
      requestedByUid: requestedByUid,
      requestedByEmail: requestedByEmail,
      requestedAt: requestedAt,
      reviewedByEmail: reviewedByEmail ?? this.reviewedByEmail,
      reviewedAt: reviewedAt ?? this.reviewedAt,
    );
  }
}
