import 'dart:async';

import 'package:inventory/auth/app_user.dart';
import 'package:inventory/data/customer_repository.dart';
import 'package:inventory/models/app_notification.dart';
import 'package:inventory/models/customer.dart';
import 'package:inventory/models/discount_request.dart';
import 'package:inventory/models/staff_request.dart';

/// Mimics FirestoreCustomerRepository behaviour: writes do not mutate local
/// state directly, streams re-emit asynchronously with auto-generated IDs.
class FakeFirestoreRepository implements CustomerRepository {
  final List<Customer> customers = [];
  final List<DiscountRequest> discountRequests = [];
  final List<AppNotification> notifications = [];
  final List<StaffRequest> staffRequests = [];
  final List<StaffRequest> staffList = [];

  final _customersController = StreamController<List<Customer>>.broadcast();
  final _requestsController =
      StreamController<List<DiscountRequest>>.broadcast();
  final _notificationsController =
      StreamController<List<AppNotification>>.broadcast();
  final _staffRequestsController =
      StreamController<List<StaffRequest>>.broadcast();
  final _staffListController = StreamController<List<StaffRequest>>.broadcast();

  int _seq = 0;

  String nextId(String prefix) =>
      '$prefix${(++_seq).toString().padLeft(20, 'x')}autoId';

  void _emitCustomers() =>
      _customersController.add([...customers]);
  void _emitRequests() => _requestsController.add([...discountRequests]);
  void _emitNotifications() =>
      _notificationsController.add([...notifications]);
  void _emitStaffRequests() =>
      _staffRequestsController.add([...staffRequests]);
  void _emitStaffList() => _staffListController.add([...staffList]);

  void close() {
    _customersController.close();
    _requestsController.close();
    _notificationsController.close();
    _staffRequestsController.close();
    _staffListController.close();
  }

  @override
  Stream<List<Customer>> watchCustomers() async* {
    yield List.of(customers);
    yield* _customersController.stream.map((list) => List.of(list));
  }

  @override
  Future<Customer> createCustomer(Customer customer) async {
    final created = customer.copyWith(id: nextId('CUS-'));
    customers.add(created);
    Future.microtask(_emitCustomers);
    return created;
  }

  @override
  Future<void> updateCustomer(Customer customer) async {
    final index = customers.indexWhere((c) => c.id == customer.id);
    if (index != -1) customers[index] = customer;
    Future.microtask(_emitCustomers);
  }

  @override
  Future<void> deleteCustomer(String customerId) async {
    customers.removeWhere((c) => c.id == customerId);
    Future.microtask(_emitCustomers);
  }

  @override
  Future<void> recordPayment(
    String customerId,
    double amount, {
    String? note,
  }) async {}

  @override
  Future<void> restoreToActive(Customer customer) async {}

  @override
  Future<void> markAsCompleted(Customer customer) async {}

  @override
  Future<int> importCustomers(List<Customer> customers) async => 0;

  @override
  Stream<List<DiscountRequest>> watchDiscountRequests() async* {
    yield List.of(discountRequests);
    yield* _requestsController.stream.map((list) => List.of(list));
  }

  @override
  Future<void> requestDiscount(
    String customerId,
    double amount,
    String reason,
  ) async {
    final request = DiscountRequest(
      id: nextId('DR-'),
      customerId: customerId,
      customerName: customers
          .firstWhere((c) => c.id == customerId)
          .name,
      amountCentavos: (amount * 100).round(),
      reason: reason,
      requestedByUid: 'staff-uid',
      requestedByEmail: 'staff@cipms.test',
      requestedAt: DateTime.now(),
    );
    discountRequests.add(request);
    notifications.insert(
      0,
      AppNotification(
        id: nextId('NT-'),
        type: AppNotificationType.discountRequested,
        title: 'New discount request',
        message:
            '${request.customerName} ($customerId) requested a '
            '₱${amount.toStringAsFixed(2)} discount.',
        audienceRole: 'admin',
        customerId: customerId,
        requestId: request.id,
        createdAt: DateTime.now(),
      ),
    );
    Future.microtask(() {
      _emitRequests();
      _emitNotifications();
    });
  }

  @override
  Future<void> approveDiscountRequest(
    String requestId, {
    String? note,
  }) async {
    final index =
        discountRequests.indexWhere((r) => r.id == requestId);
    if (index == -1) return;
    discountRequests[index] = discountRequests[index].copyWith(
      status: DiscountRequestStatus.approved,
      reviewedAt: DateTime.now(),
      reviewedByEmail: 'admin@cipms.test',
      reviewNote: note ?? '',
    );
    Future.microtask(_emitRequests);
  }

  @override
  Future<void> rejectDiscountRequest(
    String requestId, {
    String? note,
  }) async {
    final index =
        discountRequests.indexWhere((r) => r.id == requestId);
    if (index == -1) return;
    discountRequests[index] = discountRequests[index].copyWith(
      status: DiscountRequestStatus.rejected,
      reviewedAt: DateTime.now(),
      reviewedByEmail: 'admin@cipms.test',
      reviewNote: note ?? '',
    );
    Future.microtask(_emitRequests);
  }

  @override
  Stream<List<AppNotification>> watchNotifications({AppRole? viewAs}) async* {
    yield List.of(notifications);
    yield* _notificationsController.stream.map((list) => List.of(list));
  }

  @override
  Future<void> markNotificationRead(String notificationId) async {
    final index =
        notifications.indexWhere((n) => n.id == notificationId);
    if (index == -1) return;
    notifications[index] = notifications[index].copyWith(
      readBy: [...notifications[index].readBy, 'admin-uid'],
    );
    Future.microtask(_emitNotifications);
  }

  @override
  Future<void> markNotificationUnread(String notificationId) async {
    final index =
        notifications.indexWhere((n) => n.id == notificationId);
    if (index == -1) return;
    notifications[index] = notifications[index].copyWith(
      readBy:
          notifications[index].readBy.where((id) => id != 'admin-uid').toList(),
    );
    Future.microtask(_emitNotifications);
  }

  @override
  Stream<List<StaffRequest>> watchStaffRequests() async* {
    yield List.of(staffRequests);
    yield* _staffRequestsController.stream.map((list) => List.of(list));
  }

  @override
  Stream<List<StaffRequest>> watchStaffList() async* {
    yield List.of(staffList);
    yield* _staffListController.stream.map((list) => List.of(list));
  }

  @override
  Future<void> approveStaff(String uid) async {
    final index = staffRequests.indexWhere((r) => r.uid == uid);
    if (index == -1) return;
    staffList.add(staffRequests.removeAt(index));
    Future.microtask(() {
      _emitStaffRequests();
      _emitStaffList();
    });
  }

  @override
  Future<void> rejectStaff(String uid) async {
    staffRequests.removeWhere((r) => r.uid == uid);
    Future.microtask(_emitStaffRequests);
  }

  @override
  Future<void> publishCustomerView(String customerId) async {}
}
