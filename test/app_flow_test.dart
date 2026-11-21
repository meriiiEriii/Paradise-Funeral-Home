import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:inventory/auth/auth_session.dart';
import 'package:inventory/data/app_preferences.dart';
import 'package:inventory/data/customer_store.dart';
import 'package:inventory/main.dart';
import 'package:inventory/models/app_notification.dart';
import 'package:inventory/models/customer.dart';
import 'package:inventory/utils/validators.dart';

import 'support/fake_auth_session.dart';

Customer _customer({
  required String id,
  String name = 'Test Customer',
  double cost = 1000,
  double paid = 0,
  DateTime? dueDate,
  AccountStatus status = AccountStatus.active,
}) {
  return Customer(
    id: id,
    name: name,
    address: 'Test Address',
    contactNumber: '09170000000',
    package: 'Test Package',
    items: [PackageItem(name: 'Item', amount: cost)],
    amountPaid: paid,
    dueDate: dueDate ?? DateTime.now().add(const Duration(days: 30)),
    accountStatus: status,
  );
}

CustomerStore _seedStore() {
  final store = CustomerStore();
  final now = DateTime.now();

  store.addCustomer(
    _customer(
      id: 'CUS-0001',
      name: 'Maria Santos',
      cost: 2000,
      paid: 500,
      dueDate: now.add(const Duration(days: 30)),
    ),
  );
  store.addCustomer(
    _customer(
      id: 'CUS-0002',
      name: 'Jose Dela Cruz',
      cost: 2000,
      dueDate: now.subtract(const Duration(days: 120)),
    ),
  );
  store.addCustomer(
    _customer(
      id: 'CUS-0003',
      name: 'Ana Reyes',
      cost: 1000,
      paid: 1000,
      dueDate: now.subtract(const Duration(days: 5)),
    ),
  );

  return store;
}

Future<void> _pumpApp(
  WidgetTester tester,
  CustomerStore store, {
  String initialLocation = '/dashboard',
  ValueChanged<ThemeMode>? onThemeChanged,
  AuthSession? session,
}) async {
  tester.view.physicalSize = const Size(1400, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    CIPMSApp(
      store: store,
      session: session ?? FakeAuthSession.admin(),
      initialLocation: initialLocation,
      onThemeChanged: onThemeChanged,
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('CustomerStore', () {
    test('serializes and restores customers', () {
      final store = _seedStore();
      final restored = CustomerStore();
      restored.loadFromJson(store.toJson());

      expect(restored.allCustomers.length, 3);
      final maria = restored.getCustomerById('CUS-0001')!;
      expect(maria.name, 'Maria Santos');
      expect(maria.items.length, 1);
      expect(maria.amountPaid, 500);
      expect(maria.accountStatus, AccountStatus.active);
      expect(
        restored.getCustomerById('CUS-0002')!.accountStatus,
        AccountStatus.delayed,
      );
      expect(
        restored.getCustomerById('CUS-0003')!.accountStatus,
        AccountStatus.active,
      );
      expect(
        maria.dueDate.millisecondsSinceEpoch,
        store.getCustomerById('CUS-0001')!.dueDate.millisecondsSinceEpoch,
      );
    });

    test('generates unique ids after deletions', () {
      final store = CustomerStore();
      store.addCustomer(_customer(id: store.generateCustomerId()));
      store.addCustomer(_customer(id: store.generateCustomerId()));
      store.deleteCustomer('CUS-0001');

      expect(store.generateCustomerId(), 'CUS-0003');
    });

    test('final payment archives the account', () {
      final store = CustomerStore();
      store.addCustomer(_customer(id: 'CUS-0001'));

      store.recordPayment('CUS-0001', 400);
      final partial = store.getCustomerById('CUS-0001')!;
      expect(partial.accountStatus, AccountStatus.active);
      expect(partial.amountPaid, 400);
      expect(partial.lastPaymentDate, isNotNull);

      store.recordPayment('CUS-0001', 600);
      final paid = store.getCustomerById('CUS-0001')!;
      expect(paid.accountStatus, AccountStatus.completed);
      expect(paid.remainingBalance, 0);
    });

    test('restore keeps delayed accounts active with a future due date', () {
      final now = DateTime.now();
      final store = CustomerStore();
      store.addCustomer(
        _customer(
          id: 'CUS-0001',
          dueDate: now.subtract(const Duration(days: 120)),
          status: AccountStatus.delayed,
        ),
      );

      store.restoreToActive(store.getCustomerById('CUS-0001')!);
      final restored = store.getCustomerById('CUS-0001')!;
      expect(restored.accountStatus, AccountStatus.active);
      expect(restored.dueDate.isAfter(now), isTrue);

      store.applyBusinessRules();
      expect(
        store.getCustomerById('CUS-0001')!.accountStatus,
        AccountStatus.active,
      );
    });

    test('restore keeps a fully paid account active', () {
      final store = CustomerStore();
      store.addCustomer(
        _customer(
          id: 'CUS-0001',
          cost: 1000,
          paid: 1000,
          status: AccountStatus.completed,
        ),
      );

      store.restoreToActive(store.getCustomerById('CUS-0001')!);
      store.applyBusinessRules();

      expect(
        store.getCustomerById('CUS-0001')!.accountStatus,
        AccountStatus.active,
      );
    });

    test('applies approved discount to total due and balance', () {
      final customer = Customer(
        id: 'CUS-0099',
        name: 'Discounted',
        address: 'Test Address',
        contactNumber: '09170000000',
        package: 'Test Package',
        items: [PackageItem(name: 'Item', amount: 1000)],
        approvedDiscount: 250,
        amountPaid: 300,
        dueDate: DateTime.now().add(const Duration(days: 30)),
      );

      expect(customer.totalPackageCost, 1000);
      expect(customer.totalDue, 750);
      expect(customer.remainingBalance, 450);
      expect(customer.totalDueCentavos, 75000);
      expect(customer.remainingBalanceCentavos, 45000);
      expect(customer.hasPendingDiscountRequest, isFalse);

      final pending = customer.copyWith(pendingDiscountRequestId: 'DR-0001');
      expect(pending.hasPendingDiscountRequest, isTrue);
      expect(
        pending
            .copyWith(pendingDiscountRequestId: null)
            .hasPendingDiscountRequest,
        isFalse,
      );
    });

    test('importCustomers skips duplicate ids', () async {
      final store = _seedStore();
      final imported = await store.importCustomers([
        _customer(id: 'CUS-0001', name: 'Duplicate'),
        _customer(id: 'CUS-0100', name: 'Imported Customer'),
      ]);

      expect(imported, 1);
      expect(store.getCustomerById('CUS-0100')?.name, 'Imported Customer');
    });

    test('discount request applies on approval and clears the pending flag', () async {
      final store = CustomerStore();
      await store.addCustomer(_customer(id: 'CUS-0001', cost: 1000, paid: 200));

      await store.requestDiscount('CUS-0001', 100, 'Loyal client');
      final pending = store.getCustomerById('CUS-0001')!;
      expect(pending.hasPendingDiscountRequest, isTrue);
      expect(store.pendingDiscountRequestCount, 1);
      expect(store.unreadNotificationCount(adminUser), 1);

      await store.approveDiscountRequest(
        store.pendingDiscountRequests.first.id,
      );

      final approved = store.getCustomerById('CUS-0001')!;
      expect(approved.approvedDiscount, 100);
      expect(approved.totalDue, 900);
      expect(approved.remainingBalance, 700);
      expect(approved.hasPendingDiscountRequest, isFalse);
      expect(store.pendingDiscountRequestCount, 0);
      expect(
        store.notifications.any(
          (notification) =>
              notification.type == AppNotificationType.discountApproved &&
              notification.recipientUid == 'local-user',
        ),
        isTrue,
      );
      expect(store.unreadNotificationCount(adminUser), 1);
    });

    test('rejected discount clears pending and allows a new request', () async {
      final store = CustomerStore();
      await store.addCustomer(_customer(id: 'CUS-0001', cost: 1000));

      await store.requestDiscount('CUS-0001', 150, 'First attempt');
      await store.rejectDiscountRequest(
        store.pendingDiscountRequests.first.id,
        note: 'Not eligible',
      );

      final rejected = store.getCustomerById('CUS-0001')!;
      expect(rejected.hasPendingDiscountRequest, isFalse);
      expect(rejected.approvedDiscount, 0);
      expect(store.pendingDiscountRequestCount, 0);

      await store.requestDiscount('CUS-0001', 80, 'Second attempt');
      expect(store.pendingDiscountRequestCount, 1);
      expect(
        store.getCustomerById('CUS-0001')!.hasPendingDiscountRequest,
        isTrue,
      );
    });

    test('notifications can be marked read per user', () async {
      final store = CustomerStore();
      await store.addCustomer(_customer(id: 'CUS-0001', cost: 1000));

      await store.requestDiscount('CUS-0001', 100, 'Loyal client');
      final notification = store.notifications.first;
      expect(store.unreadNotificationCount(adminUser), 1);

      await store.markNotificationRead(notification.id, adminUser.uid);
      expect(store.unreadNotificationCount(adminUser), 0);
    });

    test('notifications can be marked unread per user', () async {
      final store = CustomerStore();
      await store.addCustomer(_customer(id: 'CUS-0001', cost: 1000));

      await store.requestDiscount('CUS-0001', 100, 'Loyal client');
      final notification = store.notifications.first;
      await store.markNotificationRead(notification.id, adminUser.uid);
      expect(store.unreadNotificationCount(adminUser), 0);

      await store.markNotificationUnread(notification.id, adminUser.uid);
      expect(store.unreadNotificationCount(adminUser), 1);
    });

    test('unpaid accounts show Unpaid instead of Partial', () {
      final unpaid = _customer(id: 'CUS-0001');
      expect(unpaid.paymentStatus, PaymentStatus.unpaid);

      final partial = _customer(id: 'CUS-0002', paid: 500);
      expect(partial.paymentStatus, PaymentStatus.partiallyPaid);

      final fullyPaid = _customer(id: 'CUS-0003', cost: 1000, paid: 1000);
      expect(fullyPaid.paymentStatus, PaymentStatus.fullyPaid);

      final overdue = _customer(
        id: 'CUS-0004',
        paid: 300,
        dueDate: DateTime.now().subtract(const Duration(days: 10)),
      );
      expect(overdue.paymentStatus, PaymentStatus.overdue);
    });

    test('customer lists show the newest customers first', () async {
      final store = CustomerStore();
      await store.addCustomer(
        Customer(
          id: 'CUS-0001',
          name: 'Older Customer',
          address: 'Test Address',
          contactNumber: '09170000001',
          package: 'Test Package',
          items: [PackageItem(name: 'Item', amount: 100)],
          dateAdded: DateTime(2026, 1, 1),
          dueDate: DateTime(2027, 2, 1),
        ),
      );
      await store.addCustomer(
        Customer(
          id: 'CUS-0002',
          name: 'Newest Customer',
          address: 'Test Address',
          contactNumber: '09170000002',
          package: 'Test Package',
          items: [PackageItem(name: 'Item', amount: 100)],
          dateAdded: DateTime(2026, 3, 1),
          dueDate: DateTime(2027, 3, 15),
        ),
      );

      expect(store.allCustomers.first.id, 'CUS-0002');
      expect(store.activeCustomers.first.id, 'CUS-0002');
      expect(store.searchActiveCustomers('').first.id, 'CUS-0002');
      expect(store.searchAllCustomers('').first.id, 'CUS-0002');
    });
  });

  group('validateContactNumber', () {
    test('accepts 11-digit Philippine numbers', () {
      expect(validateContactNumber('09171234567'), isNull);
      expect(validateContactNumber('0917-123-4567'), isNull);
      expect(validateContactNumber('0917 123 4567'), isNull);
    });

    test('rejects malformed numbers with clear messages', () {
      expect(validateContactNumber(''), 'Contact number is required.');
      expect(validateContactNumber('0917123456'), contains('11 digits'));
      expect(validateContactNumber('639171234567'), contains('11 digits'));
      expect(validateContactNumber('02123456789'), contains('start with 09'));
    });
  });

  group('AppPreferences', () {
    test('persists and reloads customers', () async {
      final prefs = await AppPreferences.load();
      await prefs.saveStore(_seedStore());

      final restored = CustomerStore();
      prefs.loadStore(restored);

      expect(restored.allCustomers.length, 3);
      expect(restored.getCustomerById('CUS-0001')!.name, 'Maria Santos');
    });

    test('persists the selected theme', () async {
      final prefs = await AppPreferences.load();
      expect(prefs.loadThemeMode(), ThemeMode.light);

      await prefs.saveThemeMode(ThemeMode.dark);
      expect(prefs.loadThemeMode(), ThemeMode.dark);
    });

    test('ignores malformed stored data', () async {
      SharedPreferences.setMockInitialValues({
        'cipms.customers.v1': '[{"items": [1]}]',
      });
      final prefs = await AppPreferences.load();
      final store = CustomerStore();

      expect(() => prefs.loadStore(store), returnsNormally);
      expect(store.allCustomers, isEmpty);
    });

    test('ignores stored values of the wrong type', () async {
      SharedPreferences.setMockInitialValues({
        'cipms.customers.v1': 42,
        'cipms.theme.v1': 7,
      });
      final prefs = await AppPreferences.load();
      final store = CustomerStore();

      expect(() => prefs.loadStore(store), returnsNormally);
      expect(store.allCustomers, isEmpty);
      expect(prefs.loadThemeMode(), ThemeMode.light);
    });
  });

  group('Routing', () {
    testWidgets('deep links open the requested route', (tester) async {
      await _pumpApp(tester, _seedStore(), initialLocation: '/search');
      expect(find.text('Customer Registry'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('deep links open a customer profile', (tester) async {
      await _pumpApp(
        tester,
        _seedStore(),
        initialLocation: '/customer/CUS-0001',
      );
      expect(find.text('Customer Profile'), findsOneWidget);
      expect(find.text('Maria Santos'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('unknown customer ids show the not-found state', (
      tester,
    ) async {
      await _pumpApp(
        tester,
        _seedStore(),
        initialLocation: '/customer/missing',
      );
      expect(find.text('Customer not found'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('theme changes are reported to the persistence callback', (
      tester,
    ) async {
      ThemeMode? changed;
      await _pumpApp(
        tester,
        _seedStore(),
        onThemeChanged: (mode) => changed = mode,
      );

      await tester.tap(find.byTooltip('Switch to dark mode'));
      await tester.pumpAndSettle();

      expect(changed, ThemeMode.dark);
    });

    testWidgets('payment from a profile updates the shared store', (
      tester,
    ) async {
      final store = _seedStore();
      await _pumpApp(tester, store, initialLocation: '/customer/CUS-0001');

      await tester.tap(find.text('Record Payment'));
      await tester.pumpAndSettle();
      expect(find.text('Process Payment'), findsOneWidget);

      await tester.enterText(find.byType(TextField), '1500');
      await tester.tap(find.text('Record Payment').last);
      await tester.pumpAndSettle();

      final maria = store.getCustomerById('CUS-0001')!;
      expect(maria.amountPaid, 2000);
      expect(maria.accountStatus, AccountStatus.completed);
      expect(find.textContaining('Payment of'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('admin approves a discount request from approvals', (
      tester,
    ) async {
      final store = _seedStore();
      await store.requestDiscount('CUS-0001', 200, 'Goodwill discount');

      await _pumpApp(tester, store, initialLocation: '/approvals');
      expect(find.text('Discount Approvals'), findsWidgets);
      expect(find.textContaining('200.00'), findsWidgets);

      await tester.tap(find.text('Approve').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Approve').last);
      await tester.pumpAndSettle();

      expect(store.getCustomerById('CUS-0001')!.approvedDiscount, 200);
      expect(store.pendingDiscountRequestCount, 0);
      expect(tester.takeException(), isNull);
    });

    testWidgets('notification details and actions only show when opened', (
      tester,
    ) async {
      final store = _seedStore();
      await store.requestDiscount('CUS-0001', 200, 'Goodwill discount');

      await _pumpApp(tester, store, initialLocation: '/notifications');

      // Collapsed: no approve/reject actions or details visible.
      expect(find.text('Approve'), findsNothing);
      expect(find.textContaining('Goodwill discount'), findsNothing);

      // Opening the notification reveals the details and actions.
      await tester.tap(find.text('New discount request'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Goodwill discount'), findsWidgets);
      expect(find.text('Approve'), findsOneWidget);
      expect(find.text('Reject'), findsOneWidget);

      // Approving works from the notification itself.
      await tester.tap(find.text('Approve'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Approve').last);
      await tester.pumpAndSettle();

      expect(store.getCustomerById('CUS-0001')!.approvedDiscount, 200);
      expect(tester.takeException(), isNull);
    });

    testWidgets('read notifications can be marked unread', (tester) async {
      final store = _seedStore();
      await store.requestDiscount('CUS-0001', 100, 'Loyal client');
      final notification = store.notifications.first;
      await store.markNotificationRead(notification.id, adminUser.uid);
      expect(store.unreadNotificationCount(adminUser), 0);

      await _pumpApp(tester, store, initialLocation: '/notifications');
      expect(find.text('Read (1)'), findsOneWidget);

      await tester.tap(find.text('Read (1)'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Notification options'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mark as unread'));
      await tester.pumpAndSettle();

      expect(store.unreadNotificationCount(adminUser), 1);
      expect(tester.takeException(), isNull);
    });

    testWidgets('staff submits a discount request from the profile', (
      tester,
    ) async {
      final store = _seedStore();
      await _pumpApp(
        tester,
        store,
        initialLocation: '/customer/CUS-0001',
        session: FakeAuthSession.staff(),
      );

      await tester.tap(find.text('Request Discount'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), '100');
      await tester.enterText(find.byType(TextField).at(1), 'Goodwill');
      await tester.tap(find.text('Send request'));
      await tester.pumpAndSettle();

      expect(store.pendingDiscountRequestCount, 1);
      expect(
        store.getCustomerById('CUS-0001')!.hasPendingDiscountRequest,
        isTrue,
      );
      expect(find.text('Discount pending'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Authentication and roles', () {
    testWidgets('signed-out users land on the login screen', (tester) async {
      await _pumpApp(
        tester,
        _seedStore(),
        initialLocation: '/login',
        session: FakeAuthSession.signedOut(),
      );

      expect(find.text('Welcome back'), findsOneWidget);

      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text('Sign In'), findsOneWidget);

      await tester.tap(find.text('New here? Create an account'));
      await tester.pumpAndSettle();
      expect(find.text('Create your account'), findsOneWidget);
      expect(find.text('Create staff account'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('login asks for the account type before credentials', (
      tester,
    ) async {
      await _pumpApp(
        tester,
        _seedStore(),
        initialLocation: '/login',
        session: FakeAuthSession.signedOut(),
      );

      expect(find.text('Staff'), findsOneWidget);
      expect(find.text('Admin'), findsOneWidget);
      expect(find.text('Email'), findsNothing);

      await tester.tap(find.text('Admin'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(find.text('Sign in as Admin'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('register screen offers staff and admin roles', (
      tester,
    ) async {
      await _pumpApp(
        tester,
        _seedStore(),
        initialLocation: '/register',
        session: FakeAuthSession.signedOut(),
      );

      expect(find.text('Staff'), findsOneWidget);
      expect(find.text('Admin'), findsOneWidget);
      expect(find.text('Full name'), findsOneWidget);
      expect(find.text('Administrator access code'), findsNothing);

      await tester.tap(find.text('Admin'));
      await tester.pumpAndSettle();
      expect(find.text('Administrator access code'), findsOneWidget);
      expect(find.text('Full name'), findsNothing);
      expect(find.text('Create admin account'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('protected routes redirect signed-out users to login', (
      tester,
    ) async {
      await _pumpApp(
        tester,
        _seedStore(),
        session: FakeAuthSession.signedOut(),
      );

      expect(find.text('Welcome back'), findsOneWidget);
      expect(find.text('Active Accounts'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('staff sees payment access but not admin-only navigation', (
      tester,
    ) async {
      await _pumpApp(tester, _seedStore(), session: FakeAuthSession.staff());

      expect(find.byTooltip('Add Customer'), findsNothing);

      await tester.tap(find.byTooltip('Open menu'));
      await tester.pumpAndSettle();
      expect(find.text('Search Customer'), findsOneWidget);
      expect(find.text('Payment'), findsOneWidget);
      expect(find.text('Discount Approvals'), findsNothing);
      expect(find.text('Staff'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('staff is redirected away from admin-only routes', (
      tester,
    ) async {
      await _pumpApp(
        tester,
        _seedStore(),
        initialLocation: '/add',
        session: FakeAuthSession.staff(),
      );

      expect(find.text('Active Accounts'), findsOneWidget);
      expect(find.text('New Customer'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('staff profile can record payments and request discounts', (
      tester,
    ) async {
      await _pumpApp(
        tester,
        _seedStore(),
        initialLocation: '/customer/CUS-0001',
        session: FakeAuthSession.staff(),
      );

      expect(find.text('Customer Profile'), findsOneWidget);
      expect(find.text('Record Payment'), findsOneWidget);
      expect(find.text('Request Discount'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('staff page shows requests and staff list tabs', (tester) async {
      await _pumpApp(tester, _seedStore(), initialLocation: '/staff-requests');

      expect(find.text('Staff'), findsWidgets);
      expect(find.text('Staff Requests (0)'), findsOneWidget);
      expect(find.text('Staff List (0)'), findsOneWidget);
      expect(find.text('No pending staff accounts'), findsOneWidget);

      await tester.tap(find.text('Staff List (0)'));
      await tester.pumpAndSettle();
      expect(find.text('No staff yet'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('staff registration notifications navigate to the staff page', (
      tester,
    ) async {
      final store = CustomerStore();
      store.insertNotification(
        AppNotification(
          id: 'NT-0001',
          type: AppNotificationType.staffRegistered,
          title: 'New staff registration',
          message: 'Sam Staff (staff@cipms.test) is awaiting your approval.',
          audienceRole: 'admin',
          customerId: '',
          staffUid: 'staff-uid',
          createdAt: DateTime.now(),
        ),
      );

      await _pumpApp(tester, store, initialLocation: '/notifications');

      expect(find.text('Approve'), findsNothing);
      expect(find.text('Reject'), findsNothing);

      await tester.tap(find.text('New staff registration'));
      await tester.pumpAndSettle();

      expect(find.text('Staff Requests (0)'), findsOneWidget);
      expect(find.text('Staff List (0)'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('staff delayed accounts hide the restore action', (
      tester,
    ) async {
      await _pumpApp(
        tester,
        _seedStore(),
        initialLocation: '/delayed',
        session: FakeAuthSession.staff(),
      );

      expect(find.text('Restore'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('admin profile shows the record payment action', (
      tester,
    ) async {
      await _pumpApp(
        tester,
        _seedStore(),
        initialLocation: '/customer/CUS-0001',
      );

      expect(find.text('Record Payment'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('logout returns the user to the login screen', (tester) async {
      await _pumpApp(tester, _seedStore());

      await tester.tap(find.byTooltip('Open menu'));
      await tester.pumpAndSettle();
      final drawerScroll = find.descendant(
        of: find.byType(Drawer),
        matching: find.byType(Scrollable),
      );
      await tester.dragUntilVisible(
        find.text('Logout'),
        drawerScroll,
        const Offset(0, -120),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Logout'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Logout'));
      await tester.pumpAndSettle();

      expect(find.text('Welcome back'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('admin switches to the staff view without a password', (
      tester,
    ) async {
      final session = FakeAuthSession.admin();
      await _pumpApp(tester, _seedStore(), session: session);

      await tester.tap(find.byTooltip('Open menu'));
      await tester.pumpAndSettle();
      expect(find.text('Administrator'), findsOneWidget);
      expect(find.text('Discount Approvals'), findsOneWidget);

      // The role chip "Staff" sits above the "Staff" navigation item.
      await tester.tap(find.text('Staff').first);
      await tester.pumpAndSettle();
      expect(session.isViewingAsStaff, isTrue);

      await tester.tap(find.byTooltip('Open menu'));
      await tester.pumpAndSettle();
      expect(find.text('Discount Approvals'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('switching back to admin requires the login dialog', (
      tester,
    ) async {
      final session = FakeAuthSession.admin();
      await _pumpApp(tester, _seedStore(), session: session);

      await tester.tap(find.byTooltip('Open menu'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Staff').first);
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Open menu'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Administrator'));
      await tester.pumpAndSettle();

      expect(find.text('Administrator access'), findsOneWidget);

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'admin@cipms.test');
      await tester.enterText(fields.at(1), 'Admin12345!');
      await tester.tap(find.text('Unlock admin'));
      await tester.pumpAndSettle();

      expect(session.isViewingAsStaff, isFalse);
      await tester.tap(find.byTooltip('Open menu'));
      await tester.pumpAndSettle();
      expect(find.text('Discount Approvals'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('staff must sign in to reach the admin view', (tester) async {
      await _pumpApp(tester, _seedStore(), session: FakeAuthSession.staff());

      await tester.tap(find.byTooltip('Open menu'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Administrator'));
      await tester.pumpAndSettle();

      expect(find.text('Administrator access'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
