const String kUsersCollection = 'users';

const String kNotificationsCollection = 'notifications';

/// Shared secret required to self-register an administrator account.
///
/// The same literal is enforced server-side in `firestore.rules` so that an
/// account cannot be promoted to admin without it.
const String kAdminAccessCode = 'PARADISE-ADMIN-2026';

/// Thrown for authentication failures that should be shown to the user.
class AuthException implements Exception {
  final String message;

  AuthException(this.message);

  @override
  String toString() => message;
}
