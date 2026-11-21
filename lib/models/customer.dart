enum PaymentStatus { fullyPaid, partiallyPaid, overdue }

enum AccountStatus { active, delayed, completed }

class PackageItem {
  String name;
  double amount;

  PackageItem({required this.name, required this.amount});

  int get amountCentavos => (amount * 100).round();

  Map<String, dynamic> toJson() => {'name': name, 'amount': amount};

  factory PackageItem.fromJson(Map<String, dynamic> json) {
    return PackageItem(
      name: json['name'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
    );
  }
}

class Customer {
  static const Object _unset = Object();

  final String id;
  final DateTime dateAdded;
  String name;
  String address;
  String contactNumber;
  String package;
  List<PackageItem> items;
  double amountPaid;
  double approvedDiscount;
  String? pendingDiscountRequestId;
  String remarks;
  DateTime dueDate;
  AccountStatus accountStatus;
  DateTime? lastPaymentDate;

  Customer({
    required this.id,
    DateTime? dateAdded,
    required this.name,
    required this.address,
    required this.contactNumber,
    this.package = '',
    this.items = const [],
    this.amountPaid = 0.0,
    this.approvedDiscount = 0.0,
    this.pendingDiscountRequestId,
    this.remarks = '',
    required this.dueDate,
    this.accountStatus = AccountStatus.active,
    this.lastPaymentDate,
  }) : dateAdded = dateAdded ?? DateTime.now();

  double get totalPackageCost =>
      items.fold(0.0, (sum, item) => sum + item.amount);

  double get totalDue =>
      (totalPackageCost - approvedDiscount).clamp(0, double.infinity);

  double get remainingBalance =>
      (totalDue - amountPaid).clamp(0, double.infinity);

  int get totalPackageCostCentavos => (totalPackageCost * 100).round();

  int get totalDueCentavos => (totalDue * 100).round();

  int get amountPaidCentavos => (amountPaid * 100).round();

  int get approvedDiscountCentavos => (approvedDiscount * 100).round();

  int get remainingBalanceCentavos => (remainingBalance * 100).round();

  bool get hasPendingDiscountRequest =>
      pendingDiscountRequestId != null &&
      pendingDiscountRequestId!.isNotEmpty;

  PaymentStatus get paymentStatus {
    if (remainingBalance <= 0) return PaymentStatus.fullyPaid;
    if (DateTime.now().isAfter(dueDate)) return PaymentStatus.overdue;
    return PaymentStatus.partiallyPaid;
  }

  int get daysRemaining => dueDate.difference(DateTime.now()).inDays;

  bool get isOverdueThreeMonths {
    if (accountStatus != AccountStatus.active) return false;
    if (remainingBalance <= 0) return false;
    return daysRemaining < -90;
  }

  Customer copyWith({
    String? id,
    String? name,
    String? address,
    String? contactNumber,
    String? package,
    List<PackageItem>? items,
    double? amountPaid,
    double? approvedDiscount,
    Object? pendingDiscountRequestId = _unset,
    String? remarks,
    DateTime? dueDate,
    AccountStatus? accountStatus,
    DateTime? lastPaymentDate,
  }) {
    return Customer(
      id: id ?? this.id,
      dateAdded: dateAdded,
      name: name ?? this.name,
      address: address ?? this.address,
      contactNumber: contactNumber ?? this.contactNumber,
      package: package ?? this.package,
      items: items ?? this.items,
      amountPaid: amountPaid ?? this.amountPaid,
      approvedDiscount: approvedDiscount ?? this.approvedDiscount,
      pendingDiscountRequestId: identical(
        pendingDiscountRequestId,
        _unset,
      )
          ? this.pendingDiscountRequestId
          : pendingDiscountRequestId as String?,
      remarks: remarks ?? this.remarks,
      dueDate: dueDate ?? this.dueDate,
      accountStatus: accountStatus ?? this.accountStatus,
      lastPaymentDate: lastPaymentDate ?? this.lastPaymentDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dateAdded': dateAdded.toIso8601String(),
      'name': name,
      'address': address,
      'contactNumber': contactNumber,
      'package': package,
      'items': items.map((item) => item.toJson()).toList(),
      'amountPaid': amountPaid,
      'approvedDiscount': approvedDiscount,
      'pendingDiscountRequestId': pendingDiscountRequestId,
      'remarks': remarks,
      'dueDate': dueDate.toIso8601String(),
      'accountStatus': accountStatus.name,
      'lastPaymentDate': lastPaymentDate?.toIso8601String(),
    };
  }

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] as String? ?? '',
      dateAdded: DateTime.tryParse(json['dateAdded'] as String? ?? ''),
      name: json['name'] as String? ?? '',
      address: json['address'] as String? ?? '',
      contactNumber: json['contactNumber'] as String? ?? '',
      package: json['package'] as String? ?? '',
      items:
          (json['items'] as List?)
              ?.map(
                (item) => PackageItem.fromJson(
                  Map<String, dynamic>.from(item as Map),
                ),
              )
              .toList() ??
          const [],
      amountPaid: (json['amountPaid'] as num?)?.toDouble() ?? 0,
      approvedDiscount: (json['approvedDiscount'] as num?)?.toDouble() ?? 0,
      pendingDiscountRequestId: json['pendingDiscountRequestId'] as String?,
      remarks: json['remarks'] as String? ?? '',
      dueDate:
          DateTime.tryParse(json['dueDate'] as String? ?? '') ?? DateTime.now(),
      accountStatus: AccountStatus.values.firstWhere(
        (status) => status.name == json['accountStatus'],
        orElse: () => AccountStatus.active,
      ),
      lastPaymentDate: DateTime.tryParse(
        json['lastPaymentDate'] as String? ?? '',
      ),
    );
  }
}
