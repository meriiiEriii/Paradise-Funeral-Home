import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;

import '../models/app_notification.dart';
import 'app_user.dart';
import 'auth_constants.dart';
import 'auth_session.dart';

/// Authentication backed by Firebase Authentication.
///
/// The signed-in user's role and display name live in `users/{uid}` in
/// Firestore. Email/password registration always creates a staff profile;
/// admin accounts are seeded by an administrator.
class FirebaseAuthSession extends AuthSession {
  final fb.FirebaseAuth _auth;
  final FirebaseFirestore _db;

  StreamSubscription<fb.User?>? _authSubscription;
  AppUser? _user;
  bool _isInitializing = true;
  bool _registering = false;
  bool _signingIn = false;
  bool _disposed = false;
  bool _viewAsStaff = false;

  FirebaseAuthSession({
    fb.FirebaseAuth? auth,
    FirebaseFirestore? db,
  }) : _auth = auth ?? fb.FirebaseAuth.instance,
       _db = db ?? FirebaseFirestore.instance;

  @override
  bool get isInitializing => _isInitializing;

  @override
  AppUser? get user {
    final account = _user;
    if (account == null) return null;
    if (_viewAsStaff && account.isAdmin) {
      return account.copyWith(role: AppRole.staff);
    }
    return account;
  }

  @override
  AppUser? get accountUser => _user;

  @override
  bool get isViewingAsStaff => _viewAsStaff && (_user?.isAdmin ?? false);

  @override
  void viewAsStaff() {
    if (!(_user?.isAdmin ?? false) || _viewAsStaff) return;
    _viewAsStaff = true;
    if (!_disposed) notifyListeners();
  }

  @override
  Future<void> initialize() async {
    try {
      final current = _auth.currentUser;
      if (current != null) {
        final profile = await _loadProfile(current).timeout(
          const Duration(seconds: 15),
        );
        if (profile.isApproved) {
          _user = profile;
        } else {
          await _auth.signOut();
          _user = null;
        }
      }
    } catch (_) {
      _user = null;
    } finally {
      _isInitializing = false;
      if (!_disposed) notifyListeners();
    }

    _authSubscription = _auth.authStateChanges().listen(
      (fbUser) async {
        if (_registering || _signingIn) return;
        try {
          if (fbUser == null) {
            _viewAsStaff = false;
            _user = null;
          } else {
            final profile = await _loadProfile(fbUser).timeout(
              const Duration(seconds: 15),
            );
            if (!profile.isApproved) {
              _viewAsStaff = false;
              _user = null;
              if (_auth.currentUser?.uid == fbUser.uid) {
                try {
                  await _auth.signOut();
                } catch (_) {
                  // Ignore: the account is already unusable.
                }
              }
            } else if (_auth.currentUser?.uid == fbUser.uid) {
              if (_user?.uid != profile.uid) _viewAsStaff = false;
              _user = profile;
            }
          }
        } catch (_) {
          if (fbUser == null || _auth.currentUser?.uid != fbUser.uid) {
            _user = null;
          }
        }
        if (!_disposed) notifyListeners();
      },
      onError: (_) {
        _user = null;
        if (!_disposed) notifyListeners();
      },
    );
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    final normalized = _normalizeEmail(email);
    if (normalized.isEmpty || password.isEmpty) {
      throw AuthException('Enter your email and password.');
    }

    _signingIn = true;
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: normalized,
        password: password,
      );
      final fbUser = credential.user;
      if (fbUser == null) {
        throw AuthException('Could not sign in. Please try again.');
      }
      final profile = await _loadProfile(fbUser);
      if (_auth.currentUser?.uid != fbUser.uid) {
        throw AuthException('Could not sign in. Please try again.');
      }
      if (!profile.isApproved) {
        _viewAsStaff = false;
        _user = null;
        await _auth.signOut();
        if (!_disposed) notifyListeners();
        throw AuthException(_approvalMessage(profile));
      }
      _viewAsStaff = false;
      _user = profile;
      if (!_disposed) notifyListeners();
    } on AuthException {
      rethrow;
    } on fb.FirebaseAuthException catch (error) {
      throw AuthException(_messageFor(error));
    } on FirebaseException catch (error) {
      throw AuthException(_firestoreMessage(error));
    } catch (_) {
      throw AuthException('Could not sign in. Please try again.');
    } finally {
      _signingIn = false;
    }
  }

  @override
  Future<void> register({
    String name = '',
    required String email,
    required String password,
    AppRole role = AppRole.staff,
    String? accessCode,
  }) async {
    final isAdmin = role.isAdmin;
    final trimmedName = name.trim();
    final normalized = _normalizeEmail(email);

    if (!isAdmin && trimmedName.isEmpty) {
      throw AuthException('Enter your name.');
    }
    if (!_isValidEmail(normalized)) {
      throw AuthException('That email address is not valid.');
    }
    if (password.length < 6) {
      throw AuthException('Choose a password with at least 6 characters.');
    }
    if (isAdmin) {
      final code = (accessCode ?? '').trim();
      if (code.isEmpty) {
        throw AuthException('Enter the administrator access code.');
      }
      if (code != kAdminAccessCode) {
        throw AuthException('That administrator access code is not valid.');
      }
    }

    final displayName = isAdmin ? _emailName(normalized) : trimmedName;
    final approvalStatus = isAdmin
        ? ApprovalStatus.approved
        : ApprovalStatus.pending;

    _registering = true;
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: normalized,
        password: password,
      );
      final fbUser = credential.user;
      if (fbUser == null) {
        throw AuthException('Could not create the account. Please try again.');
      }

      await fbUser.updateDisplayName(displayName);
      try {
        final batch = _db.batch();
        batch.set(_db.collection(kUsersCollection).doc(fbUser.uid), {
          'name': displayName,
          'email': normalized,
          'role': role.value,
          'approvalStatus': approvalStatus.value,
          'createdAt': FieldValue.serverTimestamp(),
          if (isAdmin) 'accessCode': kAdminAccessCode,
        });
        if (!isAdmin) {
          batch.set(_db.collection(kNotificationsCollection).doc(), {
            'type': AppNotificationType.staffRegistered.value,
            'title': 'New staff registration',
            'message': '$displayName ($normalized) is awaiting your approval.',
            'audienceRole': 'admin',
            'customerId': '',
            'staffUid': fbUser.uid,
            'createdBy': {'uid': fbUser.uid, 'email': normalized},
            'createdAt': FieldValue.serverTimestamp(),
            'readBy': <String>[],
          });
        }
        await batch.commit();
      } catch (_) {
        try {
          await fbUser.delete();
        } catch (_) {
          // The account can still be recovered by signing in later.
        }
        rethrow;
      }

      _viewAsStaff = false;
      if (isAdmin) {
        _user = AppUser(
          uid: fbUser.uid,
          name: displayName,
          email: normalized,
          role: AppRole.admin,
          approvalStatus: ApprovalStatus.approved,
        );
      } else {
        // Staff accounts must be approved before they may sign in.
        _user = null;
        try {
          await _auth.signOut();
        } catch (_) {
          // Ignore: the pending account must not stay signed in.
        }
      }
      if (!_disposed) notifyListeners();
    } on AuthException {
      rethrow;
    } on fb.FirebaseAuthException catch (error) {
      throw AuthException(_messageFor(error));
    } on FirebaseException catch (error) {
      throw AuthException(_firestoreMessage(error));
    } catch (_) {
      throw AuthException('Could not create the account. Please try again.');
    } finally {
      _registering = false;
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } finally {
      _viewAsStaff = false;
      _user = null;
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<AppUser> _loadProfile(fb.User fbUser) async {
    final doc = await _db.collection(kUsersCollection).doc(fbUser.uid).get();
    if (doc.exists) {
      return _userFromDoc(doc, fbUser);
    }

    final email = _normalizeEmail(fbUser.email ?? '');
    final displayName = (fbUser.displayName ?? '').trim();
    final name = displayName.isNotEmpty ? displayName : _emailName(email);

    await _db.collection(kUsersCollection).doc(fbUser.uid).set({
      'name': name,
      'email': email,
      'role': AppRole.staff.value,
      'approvalStatus': ApprovalStatus.approved.value,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return AppUser(
      uid: fbUser.uid,
      name: name,
      email: email,
      role: AppRole.staff,
      approvalStatus: ApprovalStatus.approved,
    );
  }

  AppUser _userFromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
    fb.User fbUser,
  ) {
    final data = doc.data() ?? const <String, dynamic>{};
    final storedEmail = (data['email'] as String?)?.trim() ?? '';
    final email = storedEmail.isNotEmpty
        ? storedEmail
        : _normalizeEmail(fbUser.email ?? '');
    final storedName = (data['name'] as String?)?.trim() ?? '';
    return AppUser(
      uid: doc.id,
      name: storedName.isNotEmpty ? storedName : _emailName(email),
      email: email,
      role: AppRoleX.fromValue(data['role'] as String?),
      approvalStatus: ApprovalStatusX.fromValue(
        data['approvalStatus'] as String?,
      ),
    );
  }

  static String _approvalMessage(AppUser user) {
    if (user.approvalStatus == ApprovalStatus.rejected) {
      return 'This account was rejected by an administrator.';
    }
    return 'Your account is awaiting administrator approval.';
  }

  static String _normalizeEmail(String email) => email.trim().toLowerCase();

  static bool _isValidEmail(String email) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
  }

  static String _emailName(String email) {
    if (email.isEmpty) return 'User';
    return email.split('@').first;
  }

  static String _messageFor(fb.FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-email':
        return 'That email address is not valid.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      case 'weak-password':
        return 'Choose a password with at least 6 characters.';
      case 'operation-not-allowed':
        return 'Email/password sign-in is not enabled for this project.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Check your connection and try again.';
      default:
        return error.message ?? 'Something went wrong. Please try again.';
    }
  }

  static String _firestoreMessage(FirebaseException error) {
    switch (error.code) {
      case 'permission-denied':
        return 'The account database rejected the request. Please check the Firestore rules.';
      case 'unavailable':
      case 'network-request-failed':
        return 'Network error. Check your connection and try again.';
      case 'failed-precondition':
        return 'The account database is not ready yet. Please try again.';
      default:
        return error.message ?? 'Could not reach the account database.';
    }
  }
}
