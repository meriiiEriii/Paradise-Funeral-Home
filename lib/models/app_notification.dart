import '../auth/app_user.dart';

enum AppNotificationType {
  discountRequested,
  discountApproved,
  discountRejected,
  paymentCompleted,
  staffRegistered,
}

extension AppNotificationTypeX on AppNotificationType {
  String get value => name;

  static AppNotificationType fromValue(String? value) {
    return AppNotificationType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => AppNotificationType.paymentCompleted,
    );
  }
}

class AppNotification {
  final String id;
  final AppNotificationType type;
  final String title;
  final String message;
  final String? audienceRole;
  final String? recipientUid;
  final String customerId;
  final String? requestId;
  final String? staffUid;
  final String createdByUid;
  final DateTime createdAt;
  final List<String> readBy;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    this.audienceRole,
    this.recipientUid,
    required this.customerId,
    this.requestId,
    this.staffUid,
    this.createdByUid = '',
    required this.createdAt,
    this.readBy = const [],
  });

  bool get isRead => readBy.isNotEmpty;

  bool isVisibleTo(AppUser user) {
    if (recipientUid != null && recipientUid == user.uid) return true;
    if (audienceRole == 'admin') return user.isAdmin;
    if (audienceRole == 'staff') return !user.isAdmin;
    return false;
  }

  bool isReadBy(AppUser user) => readBy.contains(user.uid);

  AppNotification copyWith({List<String>? readBy}) {
    return AppNotification(
      id: id,
      type: type,
      title: title,
      message: message,
      audienceRole: audienceRole,
      recipientUid: recipientUid,
      customerId: customerId,
      requestId: requestId,
      staffUid: staffUid,
      createdByUid: createdByUid,
      createdAt: createdAt,
      readBy: readBy ?? this.readBy,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.value,
      'title': title,
      'message': message,
      'audienceRole': audienceRole,
      'recipientUid': recipientUid,
      'customerId': customerId,
      'requestId': requestId,
      'staffUid': staffUid,
      'createdByUid': createdByUid,
      'createdAt': createdAt.toIso8601String(),
      'readBy': readBy,
    };
  }

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String? ?? '',
      type: AppNotificationTypeX.fromValue(json['type'] as String?),
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      audienceRole: json['audienceRole'] as String?,
      recipientUid: json['recipientUid'] as String?,
      customerId: json['customerId'] as String? ?? '',
      requestId: json['requestId'] as String?,
      staffUid: json['staffUid'] as String?,
      createdByUid: json['createdByUid'] as String? ?? '',
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      readBy:
          (json['readBy'] as List?)
              ?.map((value) => value.toString())
              .toList() ??
          const [],
    );
  }
}
