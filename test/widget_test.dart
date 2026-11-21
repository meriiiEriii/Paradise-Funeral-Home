// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:inventory/data/customer_store.dart';
import 'package:inventory/main.dart';

import 'support/fake_auth_session.dart';

void main() {
  testWidgets('App loads successfully', (WidgetTester tester) async {
    final store = CustomerStore();
    await tester.pumpWidget(
      CIPMSApp(store: store, session: FakeAuthSession.admin()),
    );
    await tester.pumpAndSettle();
    expect(find.text('Paradise Funeral Home'), findsOneWidget);
  });
}
