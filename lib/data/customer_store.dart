import 'dart:async';

import 'package:flutter/foundation.dart';

import '../auth/app_user.dart';
import '../models/app_notification.dart';
import '../models/customer.dart';
import '../models/discount_request.dart';
import '../models/staff_request.dart';
import 'customer_repository.dart';

class CustomerStore extends ChangeNotifier {
  final CustomerRepository? _repository;
  final List<Customer> _customers = [];
  final List<DiscountRequest> _discountRequests = [];
  final List<AppNotification> _notifications = [];
  final List<StaffRequest> _staffRequests = [];
  StreamSubscription<List<Customer>>? _subscription;
  StreamSubscription<List<DiscountRequest>>? _requestSubscription;
  StreamSubscription<List<AppNotification>>? _notificationSubscription;
  StreamSubscription<List<StaffRequest>>? _staffRequestSubscription;
  Completer<void>? _firstLoad;
  bool _isLoading = false;
  String? _error;
  AppRole? _notificationRole;

  CustomerStore({CustomerRepository? repository}) : _repository = repository;

  bool get isLoading => _isLoading;

  String? get error => _error;

  bool get isShared => _repository != null;

  static int _newestFirst(Customer a, Customer b) =>
      b.dateAdded.compareTo(a.dateAdded);

  List<Customer> get allCustomers {
    final list = [..._customers]..sort(_newestFirst);
    return List.unmodifiable(list);
  }

  List<Customer> get activeCustomers => _customers
      .where((c) => c.accountStatus == AccountStatus.active)
      .toList()
    ..sort(_newestFirst);

  List<Customer> get delayedCustomers => _customers
      .where((c) => c.accountStatus == AccountStatus.delayed)
      .toList()
    ..sort(_newestFirst);

  List<Customer> get completedCustomers => _customers
      .where((c) => c.accountStatus == AccountStatus.completed)
      .toList()
    ..sort(_newestFirst);

  List<DiscountRequest> get discountRequests =>
      List.unmodifiable(_discountRequests);

  List<DiscountRequest> get pendingDiscountRequests => _discountRequests
      .where((request) => request.isPending)
      .toList();

  int get pendingDiscountRequestCount => pendingDiscountRequests.length;

  List<StaffRequest> get staffRequests => List.unmodifiable(_staffRequests);

  int get pendingStaffRequestCount => _staffRequests.length;

  List<AppNotification> get notifications => List.unmodifiable(_notifications);

  List<AppNotification> notificationsFor(AppUser user) {
    return _notifications
        .where((notification) => notification.isVisibleTo(user))
        .toList();
  }

  int unreadNotificationCount(AppUser user) {
    return _notifications
        .where(
          (notification) =>
              notification.isVisibleTo(user) &&
              !notification.isReadBy(user),
        )
        .length;
  }

  int get totalActiveCustomers => activeCustomers.length;
  int get totalDelayedCustomers => delayedCustomers.length;
  int get totalCompletedCustomers => completedCustomers.length;

  double get totalRevenue =>
      activeCustomers.fold(0.0, (sum, c) => sum + c.totalDue);

  int get overdueCount => activeCustomers
      .where((c) => c.paymentStatus == PaymentStatus.overdue)
      .length;

  int get fullyPaidCount => activeCustomers
      .where((c) => c.paymentStatus == PaymentStatus.fullyPaid)
      .length;

  Future<void> initialize() async {
    if (_repository == null || _subscription != null) return;

    _isLoading = true;
    _error = null;
    _firstLoad = Completer<void>();
    notifyListeners();

    _subscription = _repository.watchCustomers().listen(
      (customers) {
        _customers
          ..clear()
          ..addAll(customers);
        applyBusinessRules();
        _isLoading = false;
        _error = null;
        notifyListeners();
        _completeFirstLoad();
      },
      onError: (Object error, StackTrace stackTrace) {
        _isLoading = false;
        _error = error is CustomerRepositoryException
            ? error.message
            : 'Could not load customers. Please try again.';
        notifyListeners();
        _completeFirstLoad();
      },
      cancelOnError: false,
    );

    _requestSubscription = _repository.watchDiscountRequests().listen(
      (requests) {
        _discountRequests
          ..clear()
          ..addAll(requests);
        notifyListeners();
      },
      onError: (Object error, StackTrace stackTrace) {},
      cancelOnError: false,
    );

    _notificationSubscription = _repository
        .watchNotifications(viewAs: _notificationRole)
        .listen(
          (notifications) {
            _notifications
              ..clear()
              ..addAll(notifications);
            notifyListeners();
          },
          onError: (Object error, StackTrace stackTrace) {},
          cancelOnError: false,
        );

    _staffRequestSubscription = _repository.watchStaffRequests().listen(
      (requests) {
        _staffRequests
          ..clear()
          ..addAll(requests);
        notifyListeners();
      },
      onError: (Object error, StackTrace stackTrace) {},
      cancelOnError: false,
    );

    await _firstLoad!.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        _isLoading = false;
        _error ??= 'Timed out while loading customers.';
        notifyListeners();
      },
    );
  }

  void _completeFirstLoad() {
    final completer = _firstLoad;
    if (completer != null && !completer.isCompleted) {
      completer.complete();
    }
  }

  /// Points the notification stream at the given interface role so the bell
  /// matches what the user is currently viewing.
  void setNotificationRole(AppRole? role) {
    if (_notificationRole == role) return;
    _notificationRole = role;
    _notificationSubscription?.cancel();
    _notificationSubscription = null;
    final repository = _repository;
    if (repository == null) return;
    _notificationSubscription = repository
        .watchNotifications(viewAs: role)
        .listen(
          (notifications) {
            _notifications
              ..clear()
              ..addAll(notifications);
            notifyListeners();
          },
          onError: (Object error, StackTrace stackTrace) {},
          cancelOnError: false,
        );
  }

  Future<void> reload() async {
    if (_repository == null) return;
    await _subscription?.cancel();
    await _requestSubscription?.cancel();
    await _notificationSubscription?.cancel();
    await _staffRequestSubscription?.cancel();
    _subscription = null;
    _requestSubscription = null;
    _notificationSubscription = null;
    _staffRequestSubscription = null;
    _firstLoad = null;
    await initialize();
  }

  Customer? getCustomerById(String id) {
    try {
      return _customers.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  List<Customer> searchActiveCustomers(String query) {
    final base = activeCustomers;
    if (query.isEmpty) return base;
    final q = query.toLowerCase();
    return base
        .where(
          (c) =>
              c.name.toLowerCase().contains(q) ||
              c.contactNumber.contains(q) ||
              c.id.toLowerCase().contains(q),
        )
        .toList();
  }

  List<Customer> searchAllCustomers(String query) {
    final base = allCustomers;
    if (query.isEmpty) return base;
    final q = query.toLowerCase();
    return base
        .where(
          (c) =>
              c.name.toLowerCase().contains(q) ||
              c.contactNumber.contains(q) ||
              c.id.toLowerCase().contains(q),
        )
        .toList();
  }

  Future<Customer> addCustomer(Customer customer) async {
    if (_repository != null) {
      final created = await _repository.createCustomer(customer);
      if (getCustomerById(created.id) == null) {
        _customers.add(created);
        applyBusinessRules();
        notifyListeners();
      }
      return created;
    }

    final created = customer.id.isEmpty
        ? customer.copyWith(id: generateCustomerId())
        : customer;
    _customers.add(created);
    applyBusinessRules();
    notifyListeners();
    return created;
  }

  Future<void> updateCustomer(Customer updated) async {
    if (_repository != null) {
      await _repository.updateCustomer(updated);
      return;
    }
    final index = _customers.indexWhere((c) => c.id == updated.id);
    if (index != -1) {
      _customers[index] = updated;
      applyBusinessRules();
      notifyListeners();
    }
  }

  Future<void> recordPayment(String customerId, double amount) async {
    if (_repository != null) {
      await _repository.recordPayment(customerId, amount);
      await _republishCustomerViewQuietly(customerId);
      return;
    }
    final index = _customers.indexWhere((c) => c.id == customerId);
    if (index != -1) {
      final customer = _customers[index];
      final updated = customer.copyWith(
        amountPaid: customer.amountPaid + amount,
        lastPaymentDate: DateTime.now(),
      );
      _customers[index] = updated.remainingBalance <= 0
          ? updated.copyWith(accountStatus: AccountStatus.completed)
          : updated;
      if (updated.remainingBalance <= 0) {
        _notifications.insert(
          0,
          AppNotification(
            id: _nextNotificationId(),
            type: AppNotificationType.paymentCompleted,
            title: 'Account fully paid',
            message:
                '${customer.name} ($customerId) is now fully paid. The account has been moved to Completed.',
            audienceRole: 'admin',
            customerId: customerId,
            createdAt: DateTime.now(),
            createdByUid: 'local-user',
          ),
        );
      }
      applyBusinessRules();
      notifyListeners();
    }
  }

  Future<void> deleteCustomer(String customerId) async {
    if (_repository != null) {
      await _repository.deleteCustomer(customerId);
      return;
    }
    _customers.removeWhere((c) => c.id == customerId);
    notifyListeners();
  }

  Future<void> restoreToActive(Customer customer) async {
    if (_repository != null) {
      await _repository.restoreToActive(customer);
      return;
    }
    final index = _customers.indexWhere((c) => c.id == customer.id);
    if (index != -1) {
      final now = DateTime.now();
      _customers[index] = customer.copyWith(
        accountStatus: AccountStatus.active,
        dueDate: customer.dueDate.isBefore(now)
            ? now.add(const Duration(days: 30))
            : customer.dueDate,
      );
      notifyListeners();
    }
  }

  Future<void> markAsCompleted(Customer customer) async {
    if (_repository != null) {
      await _repository.markAsCompleted(customer);
      return;
    }
    final index = _customers.indexWhere((c) => c.id == customer.id);
    if (index != -1) {
      _customers[index] = customer.copyWith(
        accountStatus: AccountStatus.completed,
      );
      notifyListeners();
    }
  }

  Future<int> importCustomers(List<Customer> customers) async {
    if (_repository != null) {
      return _repository.importCustomers(customers);
    }
    var imported = 0;
    for (final customer in customers) {
      if (customer.id.isEmpty || getCustomerById(customer.id) != null) {
        continue;
      }
      _customers.add(customer);
      imported += 1;
    }
    if (imported > 0) {
      applyBusinessRules();
      notifyListeners();
    }
    return imported;
  }

  Future<void> requestDiscount(
    String customerId,
    double amount,
    String reason,
  ) async {
    if (_repository != null) {
      await _repository.requestDiscount(customerId, amount, reason);
      return;
    }
    final amountCentavos = (amount * 100).round();
    final trimmedReason = reason.trim();
    if (amountCentavos <= 0) {
      throw const CustomerRepositoryException(
        'Discount must be greater than zero.',
      );
    }
    if (trimmedReason.isEmpty) {
      throw const CustomerRepositoryException(
        'Please provide a reason for the discount request.',
      );
    }
    final index = _customers.indexWhere((c) => c.id == customerId);
    if (index == -1) {
      throw const CustomerRepositoryException('Customer not found.');
    }
    final customer = _customers[index];
    if (customer.hasPendingDiscountRequest) {
      throw const CustomerRepositoryException(
        'A discount request is already pending for this account.',
      );
    }
    if (customer.remainingBalanceCentavos <= 0) {
      throw const CustomerRepositoryException(
        'This account is already fully paid.',
      );
    }
    if (amountCentavos > customer.remainingBalanceCentavos) {
      throw const CustomerRepositoryException(
        'Discount exceeds the remaining balance.',
      );
    }

    final request = DiscountRequest(
      id: _nextDiscountRequestId(),
      customerId: customerId,
      customerName: customer.name,
      amountCentavos: amountCentavos,
      reason: trimmedReason,
      requestedByUid: 'local-user',
      requestedAt: DateTime.now(),
    );
    _discountRequests.insert(0, request);
    _customers[index] = customer.copyWith(
      pendingDiscountRequestId: request.id,
    );
    _notifications.insert(
      0,
      AppNotification(
        id: _nextNotificationId(),
        type: AppNotificationType.discountRequested,
        title: 'New discount request',
        message:
            '${customer.name} ($customerId) requested a ₱${amount.toStringAsFixed(2)} discount.',
        audienceRole: 'admin',
        customerId: customerId,
        requestId: request.id,
        createdAt: DateTime.now(),
        createdByUid: 'local-user',
      ),
    );
    notifyListeners();
  }

  Future<void> approveDiscountRequest(String requestId, {String? note}) async {
    if (_repository != null) {
      await _repository.approveDiscountRequest(requestId, note: note);
      DiscountRequest? reviewed;
      for (final r in _discountRequests) {
        if (r.id == requestId) {
          reviewed = r;
          break;
        }
      }
      await _republishCustomerViewQuietly(reviewed?.customerId ?? '');
      return;
    }
    final requestIndex = _discountRequests.indexWhere(
      (request) => request.id == requestId,
    );
    if (requestIndex == -1) {
      throw const CustomerRepositoryException('Discount request not found.');
    }
    final request = _discountRequests[requestIndex];
    if (!request.isPending) {
      throw const CustomerRepositoryException(
        'This request has already been reviewed.',
      );
    }
    final customerIndex = _customers.indexWhere(
      (customer) => customer.id == request.customerId,
    );
    if (customerIndex == -1) {
      throw const CustomerRepositoryException('Customer not found.');
    }
    final customer = _customers[customerIndex];
    if (request.amountCentavos > customer.remainingBalanceCentavos) {
      throw const CustomerRepositoryException(
        'The requested discount now exceeds the remaining balance. Reject it instead.',
      );
    }

    final newDiscount = customer.approvedDiscountCentavos + request.amountCentavos;
    final newTotalDue = (customer.totalPackageCostCentavos - newDiscount).clamp(
      0,
      customer.totalPackageCostCentavos,
    );
    final completed = newTotalDue - customer.amountPaidCentavos <= 0;
    _discountRequests[requestIndex] = request.copyWith(
      status: DiscountRequestStatus.approved,
      reviewedAt: DateTime.now(),
      reviewNote: note ?? '',
    );
    _customers[customerIndex] = customer.copyWith(
      approvedDiscount: newDiscount / 100.0,
      pendingDiscountRequestId: null,
      accountStatus: completed
          ? AccountStatus.completed
          : customer.accountStatus,
    );
    _notifications.insert(
      0,
      AppNotification(
        id: _nextNotificationId(),
        type: AppNotificationType.discountApproved,
        title: 'Discount approved',
        message:
            'Your ₱${request.amount.toStringAsFixed(2)} discount request for ${customer.name} (${customer.id}) was approved.',
        recipientUid: request.requestedByUid,
        customerId: customer.id,
        requestId: request.id,
        createdAt: DateTime.now(),
        createdByUid: 'local-user',
      ),
    );
    applyBusinessRules();
    notifyListeners();
  }

  Future<void> rejectDiscountRequest(String requestId, {String? note}) async {
    if (_repository != null) {
      await _repository.rejectDiscountRequest(requestId, note: note);
      return;
    }
    final requestIndex = _discountRequests.indexWhere(
      (request) => request.id == requestId,
    );
    if (requestIndex == -1) {
      throw const CustomerRepositoryException('Discount request not found.');
    }
    final request = _discountRequests[requestIndex];
    if (!request.isPending) {
      throw const CustomerRepositoryException(
        'This request has already been reviewed.',
      );
    }
    final customerIndex = _customers.indexWhere(
      (customer) => customer.id == request.customerId,
    );
    if (customerIndex == -1) {
      throw const CustomerRepositoryException('Customer not found.');
    }
    final customer = _customers[customerIndex];
    _discountRequests[requestIndex] = request.copyWith(
      status: DiscountRequestStatus.rejected,
      reviewedAt: DateTime.now(),
      reviewNote: note ?? '',
    );
    _customers[customerIndex] = customer.copyWith(
      pendingDiscountRequestId: null,
    );
    _notifications.insert(
      0,
      AppNotification(
        id: _nextNotificationId(),
        type: AppNotificationType.discountRejected,
        title: 'Discount request rejected',
        message:
            'Your ₱${request.amount.toStringAsFixed(2)} discount request for ${customer.name} (${customer.id}) was rejected.',
        recipientUid: request.requestedByUid,
        customerId: customer.id,
        requestId: request.id,
        createdAt: DateTime.now(),
        createdByUid: 'local-user',
      ),
    );
    notifyListeners();
  }

  Future<void> markNotificationRead(String notificationId, String uid) async {
    if (_repository != null) {
      await _repository.markNotificationRead(notificationId);
      return;
    }
    final index = _notifications.indexWhere(
      (notification) => notification.id == notificationId,
    );
    if (index == -1) return;
    final notification = _notifications[index];
    if (notification.readBy.contains(uid)) return;
    _notifications[index] = notification.copyWith(
      readBy: [...notification.readBy, uid],
    );
    notifyListeners();
  }

  Future<void> markNotificationUnread(
    String notificationId,
    String uid,
  ) async {
    if (_repository != null) {
      await _repository.markNotificationUnread(notificationId);
      return;
    }
    final index = _notifications.indexWhere(
      (notification) => notification.id == notificationId,
    );
    if (index == -1) return;
    final notification = _notifications[index];
    if (!notification.readBy.contains(uid)) return;
    _notifications[index] = notification.copyWith(
      readBy: notification.readBy.where((id) => id != uid).toList(),
    );
    notifyListeners();
  }

  /// Publishes (or refreshes) the public, view-only receipt page that the
  /// customer's QR code links to.
  Future<void> publishCustomerView(String customerId) async {
    if (_repository == null) return;
    await _repository.publishCustomerView(customerId);
  }

  Future<void> _republishCustomerViewQuietly(String customerId) async {
    if (customerId.isEmpty) return;
    try {
      await publishCustomerView(customerId);
    } catch (_) {
      // The receipt page stays stale until the QR is shown again; payments
      // must not fail because of this.
    }
  }

  String _nextDiscountRequestId() {
    var next = _discountRequests.length + 1;
    while (_discountRequests.any(
      (request) => request.id == 'DR-${next.toString().padLeft(4, '0')}',
    )) {
      next += 1;
    }
    return 'DR-${next.toString().padLeft(4, '0')}';
  }

  String _nextNotificationId() {
    var next = _notifications.length + 1;
    while (_notifications.any(
      (notification) => notification.id == 'NT-${next.toString().padLeft(4, '0')}',
    )) {
      next += 1;
    }
    return 'NT-${next.toString().padLeft(4, '0')}';
  }

  void applyBusinessRules() {
    for (int i = 0; i < _customers.length; i++) {
      final c = _customers[i];

      if (c.accountStatus == AccountStatus.active &&
          c.remainingBalance > 0 &&
          c.isOverdueThreeMonths) {
        _customers[i] = c.copyWith(accountStatus: AccountStatus.delayed);
      }
    }
  }

  String generateCustomerId() {
    var highest = 0;
    for (final customer in _customers) {
      final match = RegExp(r'(\d+)$').firstMatch(customer.id);
      final value = int.tryParse(match?.group(1) ?? '');
      if (value != null && value > highest) highest = value;
    }
    return 'CUS-${(highest + 1).toString().padLeft(4, '0')}';
  }

  List<Map<String, dynamic>> toJson() {
    return _customers.map((customer) => customer.toJson()).toList();
  }

  void loadFromJson(Iterable<dynamic> data) {
    final customers = data
        .map(
          (item) => Customer.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
    _customers
      ..clear()
      ..addAll(customers);
    notifyListeners();
  }

  Future<void> approveStaff(String uid) async {
    if (_repository != null) {
      await _repository.approveStaff(uid);
      return;
    }
    _staffRequests.removeWhere((request) => request.uid == uid);
    notifyListeners();
  }

  Future<void> rejectStaff(String uid) async {
    if (_repository != null) {
      await _repository.rejectStaff(uid);
      return;
    }
    _staffRequests.removeWhere((request) => request.uid == uid);
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _requestSubscription?.cancel();
    _notificationSubscription?.cancel();
    _staffRequestSubscription?.cancel();
    super.dispose();
  }
}
