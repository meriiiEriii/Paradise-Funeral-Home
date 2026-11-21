import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inventory/data/customer_store.dart';
import 'package:inventory/main.dart';
import 'package:inventory/models/app_notification.dart';

import 'support/fake_firestore_repository.dart';
import 'support/fake_auth_session.dart';

void main() {
  testWidgets('repo-mode: staff notification tap navigates without error', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repo = FakeFirestoreRepository();
    final store = CustomerStore(repository: repo);
    await store.initialize();

    await tester.pumpWidget(
      CIPMSApp(
        store: store,
        session: FakeAuthSession.admin(),
        initialLocation: '/notifications',
      ),
    );
    await tester.pumpAndSettle();

    // The store may not have re-emitted; the tile comes from the store's
    // notification list. Push a notification through the public test hook.
    store.insertNotification(
      AppNotification(
        id: 'autoIdStaffNotification',
        type: AppNotificationType.staffRegistered,
        title: 'New staff registration',
        message: 'Sam Staff (staff@cipms.test) is awaiting your approval.',
        audienceRole: 'admin',
        customerId: '',
        staffUid: 'staff-uid-1',
        createdAt: DateTime.now(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('New staff registration').first);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    repo.close();
  });

  testWidgets('repo-mode: discount notification tap navigates without error', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repo = FakeFirestoreRepository();
    final store = CustomerStore(repository: repo);
    await store.initialize();

    await tester.pumpWidget(
      CIPMSApp(
        store: store,
        session: FakeAuthSession.admin(),
        initialLocation: '/notifications',
      ),
    );
    await tester.pumpAndSettle();

    store.insertNotification(
      AppNotification(
        id: 'autoIdDiscountNotification',
        type: AppNotificationType.discountRequested,
        title: 'New discount request',
        message:
            'Maria Santos (CUS-0001) requested a ₱200.00 discount.',
        audienceRole: 'admin',
        customerId: 'CUS-0001',
        requestId: 'autoIdRequest',
        createdAt: DateTime.now(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('New discount request').first);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    repo.close();
  });
}
