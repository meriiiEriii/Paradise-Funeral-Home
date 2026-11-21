enum DiscountRequestStatus { pending, approved, rejected }

extension DiscountRequestStatusX on DiscountRequestStatus {
  String get value => name;

  String get label {
    switch (this) {
      case DiscountRequestStatus.pending:
        return 'Pending';
      case DiscountRequestStatus.approved:
        return 'Approved';
      case DiscountRequestStatus.rejected:
        return 'Rejected';
    }
  }

  static DiscountRequestStatus fromValue(String? value) {
    return DiscountRequestStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => DiscountRequestStatus.pending,
    );
  }
}

class DiscountRequest {
  final String id;
  final String customerId;
  final String customerName;
  final int amountCentavos;
  final String reason;
  final DiscountRequestStatus status;
  final String requestedByUid;
  final String requestedByEmail;
  final String requestedByName;
  final DateTime requestedAt;
  final String? reviewedByUid;
  final String? reviewedByEmail;
  final DateTime? reviewedAt;
  final String reviewNote;

  const DiscountRequest({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.amountCentavos,
    required this.reason,
    this.status = DiscountRequestStatus.pending,
    required this.requestedByUid,
    this.requestedByEmail = '',
    this.requestedByName = '',
    required this.requestedAt,
    this.reviewedByUid,
    this.reviewedByEmail,
    this.reviewedAt,
    this.reviewNote = '',
  });

  double get amount => amountCentavos / 100.0;

  bool get isPending => status == DiscountRequestStatus.pending;

  DiscountRequest copyWith({
    DiscountRequestStatus? status,
    String? reviewedByUid,
    String? reviewedByEmail,
    DateTime? reviewedAt,
    String? reviewNote,
  }) {
    return DiscountRequest(
      id: id,
      customerId: customerId,
      customerName: customerName,
      amountCentavos: amountCentavos,
      reason: reason,
      status: status ?? this.status,
      requestedByUid: requestedByUid,
      requestedByEmail: requestedByEmail,
      requestedByName: requestedByName,
      requestedAt: requestedAt,
      reviewedByUid: reviewedByUid ?? this.reviewedByUid,
      reviewedByEmail: reviewedByEmail ?? this.reviewedByEmail,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewNote: reviewNote ?? this.reviewNote,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customerId': customerId,
      'customerName': customerName,
      'amountCentavos': amountCentavos,
      'reason': reason,
      'status': status.value,
      'requestedByUid': requestedByUid,
      'requestedByEmail': requestedByEmail,
      'requestedByName': requestedByName,
      'requestedAt': requestedAt.toIso8601String(),
      'reviewedByUid': reviewedByUid,
      'reviewedByEmail': reviewedByEmail,
      'reviewedAt': reviewedAt?.toIso8601String(),
      'reviewNote': reviewNote,
    };
  }

  factory DiscountRequest.fromJson(Map<String, dynamic> json) {
    return DiscountRequest(
      id: json['id'] as String? ?? '',
      customerId: json['customerId'] as String? ?? '',
      customerName: json['customerName'] as String? ?? '',
      amountCentavos: (json['amountCentavos'] as num?)?.toInt() ?? 0,
      reason: json['reason'] as String? ?? '',
      status: DiscountRequestStatusX.fromValue(json['status'] as String?),
      requestedByUid: json['requestedByUid'] as String? ?? '',
      requestedByEmail: json['requestedByEmail'] as String? ?? '',
      requestedByName: json['requestedByName'] as String? ?? '',
      requestedAt:
          DateTime.tryParse(json['requestedAt'] as String? ?? '') ??
          DateTime.now(),
      reviewedByUid: json['reviewedByUid'] as String?,
      reviewedByEmail: json['reviewedByEmail'] as String?,
      reviewedAt: DateTime.tryParse(json['reviewedAt'] as String? ?? ''),
      reviewNote: json['reviewNote'] as String? ?? '',
    );
  }
}
