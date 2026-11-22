import 'customer.dart';

/// A pre-made package defined by an administrator and selectable as a
/// template when registering a new customer.
class PackageTemplate {
  final String id;
  final String name;
  final List<PackageItem> items;
  final DateTime createdAt;

  const PackageTemplate({
    required this.id,
    required this.name,
    this.items = const [],
    required this.createdAt,
  });

  double get total => items.fold(0.0, (sum, item) => sum + item.amount);

  PackageTemplate copyWith({
    String? name,
    List<PackageItem>? items,
  }) {
    return PackageTemplate(
      id: id,
      name: name ?? this.name,
      items: items ?? this.items,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'items': items
          .map((item) => {'name': item.name, 'amountCentavos': item.amountCentavos})
          .toList(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory PackageTemplate.fromJson(Map<String, dynamic> json) {
    return PackageTemplate(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      items:
          (json['items'] as List?)
              ?.map((item) {
                final map = Map<String, dynamic>.from(item as Map);
                return PackageItem(
                  name: map['name'] as String? ?? '',
                  amount:
                      ((map['amountCentavos'] as num?)?.toInt() ?? 0) / 100.0,
                );
              })
              .toList() ??
          const [],
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
