import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'auth/app_user.dart';
import 'auth/auth_session.dart';
import 'auth/firebase_auth_session.dart';
import 'data/app_preferences.dart';
import 'data/customer_store.dart';
import 'data/firestore_customer_repository.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'widgets/app_drawer.dart';
import 'screens/add_customer_screen.dart';
import 'screens/approvals_screen.dart';
import 'screens/auth_screens.dart';
import 'screens/completed_archive_screen.dart';
import 'screens/customer_profile_screen.dart';
import 'screens/customer_view_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/delayed_accounts_screen.dart';
import 'screens/admin_login_dialog.dart';
import 'screens/notifications_screen.dart';
import 'screens/payment_screen.dart';
import 'screens/search_customer_screen.dart';
import 'screens/staff_requests_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final preferences = await AppPreferences.load();
  final store = CustomerStore(repository: FirestoreCustomerRepository());
  await store.initialize();

  final session = FirebaseAuthSession();
  await session.initialize();

  runApp(
    CIPMSApp(
      store: store,
      session: session,
      preferences: preferences,
      initialThemeMode: preferences.loadThemeMode(),
      onThemeChanged: preferences.saveThemeMode,
    ),
  );
}

class CIPMSApp extends StatefulWidget {
  final CustomerStore store;
  final AuthSession session;
  final AppPreferences? preferences;
  final ThemeMode initialThemeMode;
  final ValueChanged<ThemeMode>? onThemeChanged;
  final String initialLocation;

  const CIPMSApp({
    super.key,
    required this.store,
    required this.session,
    this.preferences,
    this.initialThemeMode = ThemeMode.light,
    this.onThemeChanged,
    this.initialLocation = '/dashboard',
  });

  @override
  State<CIPMSApp> createState() => _CIPMSAppState();
}

class _CIPMSAppState extends State<CIPMSApp> {
  late ThemeMode _themeMode;
  late final GoRouter _router;

  bool get _isDark => _themeMode == ThemeMode.dark;

  @override
  void initState() {
    super.initState();
    _themeMode = widget.initialThemeMode;
    _router = _buildRouter();
    _lastAccountUid = widget.session.accountUser?.uid;
    widget.session.addListener(_onSessionChanged);
  }

  @override
  void dispose() {
    widget.session.removeListener(_onSessionChanged);
    super.dispose();
  }

  String? _lastAccountUid;

  void _onSessionChanged() {
    widget.store.setNotificationRole(widget.session.user?.role);
    final uid = widget.session.accountUser?.uid;
    if (uid != _lastAccountUid) {
      _lastAccountUid = uid;
      if (uid != null) {
        widget.store.reload();
      }
    }
  }

  void _toggleTheme() {
    setState(() {
      _themeMode = _isDark ? ThemeMode.light : ThemeMode.dark;
    });
    widget.onThemeChanged?.call(_themeMode);
  }

  GoRouter _buildRouter() {
    final store = widget.store;
    final session = widget.session;

    return GoRouter(
      initialLocation: widget.initialLocation,
      refreshListenable: session,
      redirect: (context, state) {
        final location = state.matchedLocation;
        final atAuth = location == '/login' || location == '/register';

        // The public customer receipt portal must be reachable without
        // signing in, straight from a QR scan.
        if (location.startsWith('/view')) return null;

        if (session.isInitializing) {
          return location == '/splash' ? null : '/splash';
        }

        final user = session.user;
        if (user == null) {
          return atAuth ? null : '/login';
        }

        if (atAuth || location == '/splash') {
          return '/dashboard';
        }

        final adminOnly =
            location == '/add' ||
            location == '/approvals' ||
            location == '/staff-requests';
        if (adminOnly && !user.isAdmin) {
          return '/dashboard';
        }

        return null;
      },
      routes: [
        GoRoute(
          path: '/splash',
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => LoginScreen(session: session),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) => RegisterScreen(session: session),
        ),
        ShellRoute(
          builder: (context, state, child) {
            final user = session.user;
            if (user == null) return const SizedBox.shrink();
            return HomeScreen(
              store: store,
              session: session,
              user: user,
              currentRoute: _routeName(state.uri.path),
              onToggleTheme: _toggleTheme,
              onSignOut: session.signOut,
              child: child,
            );
          },
          routes: [
            GoRoute(
              path: '/dashboard',
              pageBuilder: (context, state) => _shellPage(
                state,
                DashboardScreen(
                  store: store,
                  preferences: widget.preferences,
                  isAdmin: session.user?.isAdmin ?? false,
                ),
              ),
            ),
            GoRoute(
              path: '/search',
              pageBuilder: (context, state) =>
                  _shellPage(state, SearchCustomerScreen(store: store)),
            ),
            GoRoute(
              path: '/add',
              pageBuilder: (context, state) => _shellPage(
                state,
                AddCustomerScreen(
                  store: store,
                  onBack: () => context.go('/dashboard'),
                ),
              ),
            ),
            GoRoute(
              path: '/payment',
              pageBuilder: (context, state) => _shellPage(
                state,
                PaymentScreen(store: store, embedded: true),
              ),
            ),
            GoRoute(
              path: '/delayed',
              pageBuilder: (context, state) => _shellPage(
                state,
                DelayedAccountsScreen(
                  store: store,
                  canEdit: session.user?.isAdmin ?? false,
                ),
              ),
            ),
            GoRoute(
              path: '/approvals',
              pageBuilder: (context, state) =>
                  _shellPage(state, ApprovalsScreen(store: store)),
            ),
            GoRoute(
              path: '/staff-requests',
              pageBuilder: (context, state) =>
                  _shellPage(state, StaffRequestsScreen(store: store)),
            ),
            GoRoute(
              path: '/completed',
              pageBuilder: (context, state) => _shellPage(
                state,
                CompletedArchiveScreen(
                  store: store,
                  canEdit: session.user?.isAdmin ?? false,
                ),
              ),
            ),
          ],
        ),
        GoRoute(
          path: '/customer/:id',
          builder: (context, state) => CustomerProfileScreen(
            store: store,
            customerId: state.pathParameters['id'] ?? '',
            canRecordPayment: session.user != null,
            canRequestDiscount: session.user != null && !session.user!.isAdmin,
            canShareQr: session.user != null,
          ),
        ),
        GoRoute(
          path: '/view/:id',
          builder: (context, state) => CustomerViewScreen(
            customerId: state.pathParameters['id'] ?? '',
            viewKey: state.uri.queryParameters['k'] ?? '',
          ),
        ),
        GoRoute(
          path: '/notifications',
          builder: (context, state) {
            final user = session.user;
            if (user == null) return const SizedBox.shrink();
            return NotificationsScreen(store: store, user: user);
          },
        ),
        GoRoute(
          path: '/customer/:id/payment',
          builder: (context, state) {
            final id = state.pathParameters['id'] ?? '';
            return PaymentScreen(
              store: store,
              customer: store.getCustomerById(id),
            );
          },
        ),
        GoRoute(path: '/', redirect: (context, state) => '/dashboard'),
      ],
    );
  }

  String _routeName(String path) {
    if (path == '/' || path.isEmpty) return 'dashboard';
    return path.replaceFirst('/', '');
  }

  Page<void> _shellPage(GoRouterState state, Widget child) {
    return CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 220),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.015),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Paradise Funeral Home: Management System',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: _themeMode,
      routerConfig: _router,
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [palette.heroStart, palette.heroEnd],
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 34,
                backgroundColor: Colors.white24,
                child: Icon(
                  Icons.local_florist_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              SizedBox(height: 18),
              Text(
                'Paradise Funeral Home',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Bitter',
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Management System',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  letterSpacing: 0.8,
                ),
              ),
              SizedBox(height: 20),
              SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final CustomerStore store;
  final AuthSession session;
  final AppUser user;
  final String currentRoute;
  final VoidCallback onToggleTheme;
  final Future<void> Function() onSignOut;
  final Widget child;

  const HomeScreen({
    super.key,
    required this.store,
    required this.session,
    required this.user,
    required this.currentRoute,
    required this.onToggleTheme,
    required this.onSignOut,
    required this.child,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  AppUser get _user => widget.session.user ?? widget.user;

  @override
  void initState() {
    super.initState();
    widget.store.addListener(_onStoreChanged);
    widget.session.addListener(_onSessionChanged);
  }

  void _onStoreChanged() {
    if (mounted) setState(() {});
  }

  void _onSessionChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.store.removeListener(_onStoreChanged);
    widget.session.removeListener(_onSessionChanged);
    super.dispose();
  }

  void _navigate(String route) {
    if (route == 'logout') {
      _scaffoldKey.currentState?.closeDrawer();
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: Icon(
            Icons.logout_rounded,
            color: Theme.of(ctx).colorScheme.error,
            size: 28,
          ),
          title: const Text('Logout'),
          content: const Text(
            'Are you sure you want to logout of the management console?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                widget.onSignOut();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(ctx).colorScheme.error,
                foregroundColor: Theme.of(ctx).colorScheme.onError,
              ),
              child: const Text('Logout'),
            ),
          ],
        ),
      );
      return;
    }

    if (route == 'settings') {
      _scaffoldKey.currentState?.closeDrawer();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings page coming soon')),
      );
      return;
    }

    _scaffoldKey.currentState?.closeDrawer();
    context.go(_pathFor(route));
  }

  Future<void> _selectRole(AppRole role) async {
    if (role == _user.role) {
      _scaffoldKey.currentState?.closeDrawer();
      return;
    }

    if (role == AppRole.staff) {
      _scaffoldKey.currentState?.closeDrawer();
      widget.session.viewAsStaff();
      widget.store.setNotificationRole(AppRole.staff);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Switched to the staff view.')),
        );
      }
      return;
    }

    _scaffoldKey.currentState?.closeDrawer();
    final unlocked = await showAdminLoginDialog(context, widget.session);
    if (!mounted || !unlocked) return;
    widget.store.setNotificationRole(widget.session.user?.role);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Administrator access granted.')),
    );
  }

  String _pathFor(String route) {
    switch (route) {
      case 'search':
        return '/search';
      case 'payment':
        return '/payment';
      case 'delayed':
        return '/delayed';
      case 'completed':
        return '/completed';
      case 'approvals':
        return '/approvals';
      case 'staff-requests':
        return '/staff-requests';
      default:
        return '/dashboard';
    }
  }

  String get _title {
    switch (widget.currentRoute) {
      case 'dashboard':
        return 'Dashboard';
      case 'search':
        return 'Search Customer';
      case 'add':
        return 'Add New Customer';
      case 'payment':
        return 'Payment';
      case 'delayed':
        return 'Delayed Accounts';
      case 'completed':
        return 'Completed / Archive';
      case 'approvals':
        return 'Discount Approvals';
      case 'staff-requests':
        return 'Staff';
      default:
        return 'Paradise Funeral Home: Management System';
    }
  }

  bool get _showFab =>
      widget.currentRoute == 'dashboard' && _user.isAdmin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppPalette.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        leading: IconButton(
          tooltip: widget.currentRoute == 'dashboard' ? 'Open menu' : 'Back',
          icon: Icon(
            widget.currentRoute == 'dashboard'
                ? Icons.menu_rounded
                : Icons.arrow_back_rounded,
          ),
          onPressed: widget.currentRoute == 'dashboard'
              ? () => _scaffoldKey.currentState?.openDrawer()
              : () => context.go('/dashboard'),
        ),
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [palette.heroStart, palette.heroEnd],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Icon(
                Icons.local_florist_rounded,
                color: Colors.white,
                size: 17,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Paradise Funeral Home',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      letterSpacing: 0.6,
                    ),
                  ),
                  Text(
                    _title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: palette.muted,
                      fontWeight: FontWeight.w500,
                      fontSize: 10.5,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (widget.currentRoute == 'dashboard')
            IconButton(
              tooltip: 'Search',
              icon: const Icon(Icons.search_rounded),
              onPressed: () => context.go('/search'),
            ),
          IconButton(
            tooltip: 'Notifications',
            onPressed: () => context.push('/notifications'),
            icon: Badge(
              isLabelVisible:
                  widget.store.unreadNotificationCount(widget.user) > 0,
              label: Text(
                '${widget.store.unreadNotificationCount(widget.user)}',
              ),
              child: const Icon(Icons.notifications_none_rounded),
            ),
          ),
          IconButton(
            tooltip: isDark ? 'Switch to light mode' : 'Switch to dark mode',
            icon: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            ),
            onPressed: widget.onToggleTheme,
          ),
          const SizedBox(width: 6),
        ],
      ),
      drawer: AppDrawer(
        user: _user,
        currentRoute: widget.currentRoute,
        onNavigate: _navigate,
        onSelectRole: _selectRole,
        isDark: isDark,
        onToggleTheme: widget.onToggleTheme,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.primary.withValues(alpha: 0.05),
              Colors.transparent,
            ],
            stops: const [0, 0.3],
          ),
        ),
        child: widget.child,
      ),
      floatingActionButton: _showFab
          ? FloatingActionButton.extended(
              onPressed: () => context.go('/add'),
              tooltip: 'Add Customer',
              icon: const Icon(Icons.add_rounded, size: 22),
              label: const Text('New Customer'),
            )
          : null,
    );
  }
}
