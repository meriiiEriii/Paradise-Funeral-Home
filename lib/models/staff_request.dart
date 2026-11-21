import '../auth/app_user.dart';

/// A staff account that has registered and is waiting for administrator
/// approval before it can sign in.
class StaffRequest {
  final String uid;
  final String name;
  final String email;
  final DateTime requestedAt;

  const StaffRequest({
    required this.uid,
    required this.name,
    required this.email,
    required this.requestedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'requestedAt': requestedAt.toIso8601String(),
    };
  }

  factory StaffRequest.fromJson(Map<String, dynamic> json) {
    return StaffRequest(
      uid: json['uid'] as String? ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      requestedAt:
          DateTime.tryParse(json['requestedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  factory StaffRequest.fromUser(AppUser user, DateTime requestedAt) {
    return StaffRequest(
      uid: user.uid,
      name: user.name,
      email: user.email,
      requestedAt: requestedAt,
    );
  }
}
