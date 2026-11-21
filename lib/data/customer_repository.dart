import '../auth/app_user.dart';
import '../models/app_notification.dart';
import '../models/customer.dart';
import '../models/discount_request.dart';
import '../models/staff_request.dart';

class CustomerRepositoryException implements Exception {
  final String message;

  const CustomerRepositoryException(this.message);

  @override
  String toString() => message;
}

abstract class CustomerRepository {
  Stream<List<Customer>> watchCustomers();

  Future<Customer> createCustomer(Customer customer);

  Future<void> updateCustomer(Customer customer);

  Future<void> deleteCustomer(String customerId);

  Future<void> recordPayment(String customerId, double amount, {String? note});

  Future<void> restoreToActive(Customer customer);

  Future<void> markAsCompleted(Customer customer);

  Future<int> importCustomers(List<Customer> customers);

  Stream<List<DiscountRequest>> watchDiscountRequests();

  Future<void> requestDiscount(
    String customerId,
    double amount,
    String reason,
  );

  Future<void> approveDiscountRequest(String requestId, {String? note});

  Future<void> rejectDiscountRequest(String requestId, {String? note});

  Stream<List<AppNotification>> watchNotifications({AppRole? viewAs});

  Future<void> markNotificationRead(String notificationId);

  Future<void> markNotificationUnread(String notificationId);

  /// Writes the public, view-only receipt document that the customer QR
  /// code links to.
  Future<void> publishCustomerView(String customerId);

  Stream<List<StaffRequest>> watchStaffRequests();

  /// Approved staff accounts (the Staff list tab).
  Stream<List<StaffRequest>> watchStaffList();

  Future<void> approveStaff(String uid);

  Future<void> rejectStaff(String uid);
}
