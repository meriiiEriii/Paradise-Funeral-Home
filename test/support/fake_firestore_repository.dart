import 'dart:async';

import 'package:inventory/auth/app_user.dart';
import 'package:inventory/data/customer_repository.dart';
import 'package:inventory/models/app_notification.dart';
import 'package:inventory/models/customer.dart';
import 'package:inventory/models/discount_request.dart';
import 'package:inventory/models/package_template.dart';
import 'package:inventory/models/payment_entry.dart';
import 'package:inventory/models/payment_request.dart';
import 'package:inventory/models/staff_request.dart';

/// Mimics FirestoreCustomerRepository behaviour: writes do not mutate local
/// state directly, streams re-emit asynchronously with auto-generated IDs.
class FakeFirestoreRepository implements CustomerRepository {
  final List<Customer> customers = [];
  final List<DiscountRequest> discountRequests = [];
  final List<AppNotification> notifications = [];
  final List<StaffRequest> staffRequests = [];
  final List<StaffRequest> staffList = [];
  final List<PackageTemplate> packageTemplates = [];
  final List<PaymentRequest> paymentRequests = [];

  final _customersController = StreamController<List<Customer>>.broadcast();
  final _requestsController =
      StreamController<List<DiscountRequest>>.broadcast();
  final _notificationsController =
      StreamController<List<AppNotification>>.broadcast();
  final _staffRequestsController =
      StreamController<List<StaffRequest>>.broadcast();
  final _staffListController = StreamController<List<StaffRequest>>.broadcast();
  final _paymentRequestsController =
      StreamController<List<PaymentRequest>>.broadcast();
  final _packageTemplatesController =
      StreamController<List<PackageTemplate>>.broadcast();

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
    _packageTemplatesController.close();
    _paymentRequestsController.close();
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
  Future<void> requestPayment(
    String customerId,
    double amount, {
    String? note,
  }) async {
    final request = PaymentRequest(
      id: nextId('PR-'),
      customerId: customerId,
      customerName: customers
          .where((c) => c.id == customerId)
          .map((c) => c.name)
          .first,
      amountCentavos: (amount * 100).round(),
      kind: 'partial',
      note: note ?? '',
      requestedByUid: 'staff-uid',
      requestedByEmail: 'staff@cipms.test',
      requestedAt: DateTime.now(),
    );
    paymentRequests.add(request);
    notifications.insert(
      0,
      AppNotification(
        id: nextId('NT-'),
        type: AppNotificationType.paymentRequested,
        title: 'New payment request',
        message:
            '${request.customerName}: a ${request.kind} payment is awaiting your approval.',
        audienceRole: 'admin',
        customerId: customerId,
        createdAt: DateTime.now(),
      ),
    );
    Future.microtask(() {
      _paymentRequestsController.add([...paymentRequests]);
      _notificationsController.add([...notifications]);
    });
  }

  @override
  Stream<List<PaymentRequest>> watchPaymentRequests() async* {
    yield List.of(paymentRequests);
    yield* _paymentRequestsController.stream.map((list) => List.of(list));
  }

  @override
  Future<void> approvePaymentRequest(String requestId) async {
    final index = paymentRequests.indexWhere((r) => r.id == requestId);
    if (index == -1) return;
    paymentRequests[index] = paymentRequests[index].copyWith(
      status: PaymentRequestStatus.approved,
      reviewedByEmail: 'admin@cipms.test',
      reviewedAt: DateTime.now(),
    );
    Future.microtask(
      () => _paymentRequestsController.add([...paymentRequests]),
    );
  }

  @override
  Future<void> rejectPaymentRequest(String requestId) async {
    final index = paymentRequests.indexWhere((r) => r.id == requestId);
    if (index == -1) return;
    paymentRequests[index] = paymentRequests[index].copyWith(
      status: PaymentRequestStatus.rejected,
      reviewedByEmail: 'admin@cipms.test',
      reviewedAt: DateTime.now(),
    );
    Future.microtask(
      () => _paymentRequestsController.add([...paymentRequests]),
    );
  }

  @override
  Future<void> updatePayment(
    String customerId,
    String paymentId,
    double newAmount,
  ) async {}

  @override
  Future<void> deletePayment(String customerId, String paymentId) async {}

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
  Future<void> deleteNotification(String notificationId) async {
    notifications.removeWhere((n) => n.id == notificationId);
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
  Stream<List<PackageTemplate>> watchPackageTemplates() async* {
    yield List.of(packageTemplates);
    yield* _packageTemplatesController.stream.map((list) => List.of(list));
  }

  @override
  Future<PackageTemplate> savePackageTemplate(
    PackageTemplate template,
  ) async {
    final id = template.id.isEmpty
        ? nextId('PT-')
        : template.id;
    final saved = PackageTemplate(
      id: id,
      name: template.name,
      items: template.items,
      createdAt: template.createdAt,
    );
    final index = packageTemplates.indexWhere((t) => t.id == id);
    if (index == -1) {
      packageTemplates.add(saved);
    } else {
      packageTemplates[index] = saved;
    }
    Future.microtask(
      () => _packageTemplatesController.add([...packageTemplates]),
    );
    return saved;
  }

  @override
  Future<void> deletePackageTemplate(String templateId) async {
    packageTemplates.removeWhere((t) => t.id == templateId);
    Future.microtask(
      () => _packageTemplatesController.add([...packageTemplates]),
    );
  }

  @override
  Stream<List<PaymentEntry>> watchPayments(String customerId) {
    return Stream.value(const <PaymentEntry>[]);
  }

  @override
  Future<void> publishCustomerView(String customerId) async {}
}
