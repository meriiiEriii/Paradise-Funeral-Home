import 'package:flutter/foundation.dart';

import 'app_user.dart';

/// Abstraction over the authentication backend so screens and tests can work
/// with a fake implementation.
abstract class AuthSession extends ChangeNotifier {
  /// True until the first authentication state has been resolved.
  bool get isInitializing;

  /// The user whose role the interface should use. This mirrors the signed-in
  /// account unless an administrator has temporarily switched to the staff
  /// view from the sidebar.
  AppUser? get user;

  /// The actual signed-in account, unaffected by any staff-view override.
  AppUser? get accountUser;

  /// True when an administrator is previewing the staff view.
  bool get isViewingAsStaff;

  /// Lowers the interface to the staff role. Only an administrator account
  /// may do this, and it never needs a password.
  void viewAsStaff();

  /// Starts listening to authentication state changes.
  Future<void> initialize();

  Future<void> signIn({required String email, required String password});

  /// Creates a new account.
  ///
  /// Staff accounts are created in a pending state and cannot sign in until an
  /// administrator approves them. Admin accounts require [accessCode].
  Future<void> register({
    String name = '',
    required String email,
    required String password,
    AppRole role = AppRole.staff,
    String? accessCode,
  });

  Future<void> signOut();
}
