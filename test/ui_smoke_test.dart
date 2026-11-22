import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:inventory/auth/auth_session.dart';
import 'package:inventory/data/customer_store.dart';
import 'package:inventory/main.dart';
import 'package:inventory/models/customer.dart';

import 'support/fake_auth_session.dart';

CustomerStore _seedStore() {
  final store = CustomerStore();
  final now = DateTime.now();

  store.addCustomer(
    Customer(
      id: store.generateCustomerId(),
      name: 'Maria Santos',
      address: '12 Mabini Street, Quezon City',
      contactNumber: '09171234567',
      package: 'Fiber Package',
      items: [
        PackageItem(name: 'Router', amount: 1500),
        PackageItem(name: 'Installation', amount: 500),
      ],
      amountPaid: 500,
      dueDate: now.add(const Duration(days: 30)),
    ),
  );

  store.addCustomer(
    Customer(
      id: store.generateCustomerId(),
      name: 'Jose Dela Cruz',
      address: '45 Rizal Avenue, Makati',
      contactNumber: '09181234567',
      package: 'Legacy Package',
      items: [PackageItem(name: 'Modem', amount: 2000)],
      amountPaid: 0,
      dueDate: now.subtract(const Duration(days: 120)),
    ),
  );

  store.addCustomer(
    Customer(
      id: store.generateCustomerId(),
      name: 'Ana Reyes',
      address: '78 Luna Street, Pasig',
      contactNumber: '09191234567',
      package: 'Home Package',
      items: [PackageItem(name: 'Setup', amount: 1000)],
      amountPaid: 1000,
      dueDate: now.subtract(const Duration(days: 5)),
    ),
  );

  return store;
}

Future<void> _pumpApp(
  WidgetTester tester,
  Size size, {
  AuthSession? session,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    CIPMSApp(store: _seedStore(), session: session ?? FakeAuthSession.admin()),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Dashboard renders with seeded data', (tester) async {
    await _pumpApp(tester, const Size(1400, 900));

    expect(find.text('Paradise Funeral Home'), findsWidgets);
    expect(find.text('Active Accounts'), findsOneWidget);
    expect(find.text('Maria Santos'), findsOneWidget);
    expect(find.text('ACTIVE ACCOUNTS'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Sidebar navigation and theme toggle work', (tester) async {
    await _pumpApp(tester, const Size(1400, 900));

    // Wide viewport: the sidebar is hidden until the burger opens it.
    expect(find.byTooltip('Open menu'), findsOneWidget);
    expect(find.text('All Customers'), findsNothing);

    await tester.tap(find.byTooltip('Open menu'));
    await tester.pumpAndSettle();
    expect(find.text('All Customers'), findsOneWidget);

    await tester.tap(find.text('All Customers'));
    await tester.pumpAndSettle();
    expect(find.text('All Customers'), findsWidgets);

    // Navigating from the menu keeps the sidebar open.
    expect(find.text('Dashboard'), findsOneWidget);
    await tester.tap(find.text('Dashboard'));
    await tester.pumpAndSettle();
    expect(find.text('Active Accounts'), findsOneWidget);

    await tester.tap(find.byTooltip('Switch to dark mode'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Switch to light mode'), findsOneWidget);

    final scaffold = tester.element(find.byType(Scaffold).first);
    expect(Theme.of(scaffold).brightness, Brightness.dark);
    expect(tester.takeException(), isNull);
  });

  testWidgets('All routes render without exceptions', (tester) async {
    await _pumpApp(tester, const Size(1400, 900));

    Future<void> openRoute(String label) async {
      final navVisible = find
          .text('Management System')
          .evaluate()
          .isNotEmpty;
      if (!navVisible) {
        final menu = find.byTooltip('Open menu');
        if (menu.evaluate().isNotEmpty) {
          await tester.tap(menu);
          await tester.pumpAndSettle();
        }
      }
      await tester.ensureVisible(find.text(label).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text(label).last);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final back = find.byTooltip('Back');
      if (back.evaluate().isNotEmpty) {
        await tester.tap(back);
      } else {
        await tester.tap(find.text('Dashboard'));
      }
      await tester.pumpAndSettle();
    }

    await openRoute('Staff');
    await openRoute('Discount Approvals');
    await openRoute('Delayed Accounts');
    await openRoute('Completed / Archive');

    await tester.tap(find.byTooltip('Add Customer'));
    await tester.pumpAndSettle();
    expect(find.text('New Customer'), findsWidgets);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Active Accounts'), findsOneWidget);
  });

  testWidgets('Dashboard adapts to a narrow viewport', (tester) async {
    await _pumpApp(tester, const Size(420, 900));

    expect(find.text('Paradise Funeral Home'), findsWidgets);
    expect(find.text('Maria Santos'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('All routes render on a narrow viewport', (tester) async {
    await _pumpApp(tester, const Size(420, 900));

    Future<void> openRoute(String label) async {
      final navVisible = find
          .text('Management System')
          .evaluate()
          .isNotEmpty;
      if (!navVisible) {
        final menu = find.byTooltip('Open menu');
        if (menu.evaluate().isNotEmpty) {
          await tester.tap(menu);
          await tester.pumpAndSettle();
        }
      }
      await tester.ensureVisible(find.text(label).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text(label).last);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final back = find.byTooltip('Back');
      if (back.evaluate().isNotEmpty) {
        await tester.tap(back);
      } else {
        await tester.tap(find.text('Dashboard'));
      }
      await tester.pumpAndSettle();
    }

    await openRoute('All Customers');
    await openRoute('Staff');
    await openRoute('Discount Approvals');
    await openRoute('Delayed Accounts');
    await openRoute('Completed / Archive');

    await tester.tap(find.byTooltip('Add Customer'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
  });

  testWidgets('Profile and payment screens render', (tester) async {
    await _pumpApp(tester, const Size(1400, 900));

    await tester.tap(find.text('Maria Santos'));
    await tester.pumpAndSettle();
    expect(find.text('Customer Profile'), findsOneWidget);
    expect(find.text('Payment Summary'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Record Payment'));
    await tester.pumpAndSettle();
    expect(find.text('Process Payment'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Dashboard renders at 320px without overflow', (tester) async {
    await _pumpApp(tester, const Size(320, 900));

    expect(find.text('Paradise Funeral Home'), findsWidgets);
    expect(find.text('Maria Santos'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('All routes render at 320px without overflow', (tester) async {
    await _pumpApp(tester, const Size(320, 900));

    Future<void> openRoute(String label) async {
      final navVisible = find
          .text('Management System')
          .evaluate()
          .isNotEmpty;
      if (!navVisible) {
        final menu = find.byTooltip('Open menu');
        if (menu.evaluate().isNotEmpty) {
          await tester.tap(menu);
          await tester.pumpAndSettle();
        }
      }
      await tester.ensureVisible(find.text(label).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text(label).last);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final back = find.byTooltip('Back');
      if (back.evaluate().isNotEmpty) {
        await tester.tap(back);
      } else {
        await tester.tap(find.text('Dashboard'));
      }
      await tester.pumpAndSettle();
    }

    await openRoute('All Customers');
    await openRoute('Staff');
    await openRoute('Discount Approvals');
    await openRoute('Delayed Accounts');
    await openRoute('Completed / Archive');

    await tester.tap(find.byTooltip('Add Customer'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
  });

  testWidgets('Dashboard handles a short desktop window', (tester) async {
    await _pumpApp(tester, const Size(1000, 480));

    expect(find.text('ACTIVE ACCOUNTS'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Profile renders at 320px without overflow', (tester) async {
    await _pumpApp(tester, const Size(320, 900));

    await tester.tap(find.text('Maria Santos'));
    await tester.pumpAndSettle();
    expect(find.text('Customer Profile'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.ensureVisible(find.text('Record Payment'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Record Payment'));
    await tester.pumpAndSettle();
    expect(find.text('Process Payment'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
