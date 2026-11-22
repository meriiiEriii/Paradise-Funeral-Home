import 'customer.dart';

/// An unfinished New Customer form saved by the user so they can come back
/// and finalize it later.
class CustomerDraft {
  final String id;
  final String firstName;
  final String middleName;
  final String lastName;
  final String suffix;
  final String address;
  final String contactNumber;
  final String remarks;
  final String packageName;
  final List<PackageItem> items;
  final DateTime dueDate;
  final DateTime savedAt;

  const CustomerDraft({
    required this.id,
    this.firstName = '',
    this.middleName = '',
    this.lastName = '',
    this.suffix = '',
    this.address = '',
    this.contactNumber = '',
    this.remarks = '',
    this.packageName = '',
    this.items = const [],
    required this.dueDate,
    required this.savedAt,
  });

  String get displayName {
    final name = [
      firstName,
      middleName,
      lastName,
    ].where((part) => part.trim().isNotEmpty).join(' ');
    return name.isEmpty ? 'Untitled draft' : name;
  }

  bool get isEmpty =>
      firstName.trim().isEmpty &&
      middleName.trim().isEmpty &&
      lastName.trim().isEmpty &&
      suffix.trim().isEmpty &&
      address.trim().isEmpty &&
      contactNumber.trim().isEmpty &&
      remarks.trim().isEmpty &&
      packageName.trim().isEmpty &&
      items.isEmpty;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'middleName': middleName,
      'lastName': lastName,
      'suffix': suffix,
      'address': address,
      'contactNumber': contactNumber,
      'remarks': remarks,
      'packageName': packageName,
      'items': items
          .map(
            (item) => {'name': item.name, 'amountCentavos': item.amountCentavos},
          )
          .toList(),
      'dueDate': dueDate.toIso8601String(),
      'savedAt': savedAt.toIso8601String(),
    };
  }

  factory CustomerDraft.fromJson(Map<String, dynamic> json) {
    return CustomerDraft(
      id: json['id'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      middleName: json['middleName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      suffix: json['suffix'] as String? ?? '',
      address: json['address'] as String? ?? '',
      contactNumber: json['contactNumber'] as String? ?? '',
      remarks: json['remarks'] as String? ?? '',
      packageName: json['packageName'] as String? ?? '',
      items: (json['items'] as List?)
          ?.map((item) {
            final map = Map<String, dynamic>.from(item as Map);
            return PackageItem(
              name: map['name'] as String? ?? '',
              amount: ((map['amountCentavos'] as num?)?.toInt() ?? 0) / 100.0,
            );
          })
          .toList() ??
      const [],
      dueDate:
          DateTime.tryParse(json['dueDate'] as String? ?? '') ??
          DateTime.now().add(const Duration(days: 10)),
      savedAt:
          DateTime.tryParse(json['savedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
