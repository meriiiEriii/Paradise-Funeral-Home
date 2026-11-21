import 'package:inventory/auth/app_user.dart';
import 'package:inventory/auth/auth_session.dart';

const adminUser = AppUser(
  uid: 'admin-uid',
  name: 'Alex Admin',
  email: 'admin@cipms.test',
  role: AppRole.admin,
);

const staffUser = AppUser(
  uid: 'staff-uid',
  name: 'Sam Staff',
  email: 'staff@cipms.test',
  role: AppRole.staff,
);

class FakeAuthSession extends AuthSession {
  AppUser? _user;
  bool _isInitializing;
  bool _viewAsStaff = false;

  FakeAuthSession({AppUser? user, bool isInitializing = false})
    : _user = user,
      _isInitializing = isInitializing;

  FakeAuthSession.admin() : this(user: adminUser);

  FakeAuthSession.staff() : this(user: staffUser);

  FakeAuthSession.signedOut() : this(user: null);

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
    notifyListeners();
  }

  @override
  Future<void> initialize() async {
    _isInitializing = false;
    notifyListeners();
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    _viewAsStaff = false;
    _user = adminUser;
    notifyListeners();
  }

  @override
  Future<void> register({
    String name = '',
    required String email,
    required String password,
    AppRole role = AppRole.staff,
    String? accessCode,
  }) async {
    _viewAsStaff = false;
    if (role.isAdmin) {
      _user = AppUser(
        uid: 'new-admin-uid',
        name: name.isEmpty ? 'Admin' : name,
        email: email,
        role: AppRole.admin,
      );
    } else {
      // Staff accounts stay signed out until an administrator approves them.
      _user = null;
    }
    notifyListeners();
  }

  @override
  Future<void> signOut() async {
    _viewAsStaff = false;
    _user = null;
    notifyListeners();
  }
}
