enum AppRole { admin, staff }

extension AppRoleX on AppRole {
  String get label => this == AppRole.admin ? 'Admin' : 'Staff';

  String get value => this == AppRole.admin ? 'admin' : 'staff';

  bool get isAdmin => this == AppRole.admin;

  static AppRole fromValue(String? value) {
    return value == 'admin' ? AppRole.admin : AppRole.staff;
  }
}

/// Whether an account may sign in and use the system.
enum ApprovalStatus { approved, pending, rejected }

extension ApprovalStatusX on ApprovalStatus {
  String get value => name;

  bool get isApproved => this == ApprovalStatus.approved;

  static ApprovalStatus fromValue(String? value) {
    switch (value) {
      case 'pending':
        return ApprovalStatus.pending;
      case 'rejected':
        return ApprovalStatus.rejected;
      default:
        return ApprovalStatus.approved;
    }
  }
}

class AppUser {
  final String uid;
  final String name;
  final String email;
  final AppRole role;
  final ApprovalStatus approvalStatus;

  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.approvalStatus = ApprovalStatus.approved,
  });

  bool get isAdmin => role.isAdmin;

  bool get isApproved => approvalStatus.isApproved;

  AppUser copyWith({
    String? name,
    String? email,
    AppRole? role,
    ApprovalStatus? approvalStatus,
  }) {
    return AppUser(
      uid: uid,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      approvalStatus: approvalStatus ?? this.approvalStatus,
    );
  }
}
