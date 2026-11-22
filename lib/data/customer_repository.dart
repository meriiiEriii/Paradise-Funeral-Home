import '../auth/app_user.dart';
import '../models/app_notification.dart';
import '../models/customer.dart';
import '../models/discount_request.dart';
import '../models/package_template.dart';
import '../models/payment_entry.dart';
import '../models/payment_request.dart';
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

  /// Staff-submitted payment awaiting admin approval.
  Future<void> requestPayment(
    String customerId,
    double amount, {
    String? note,
  });

  Stream<List<PaymentRequest>> watchPaymentRequests();

  Future<void> approvePaymentRequest(String requestId);

  Future<void> rejectPaymentRequest(String requestId);

  /// Admin corrections: edit a recorded payment's amount or delete it.
  /// Customer totals and payment balances are recomputed automatically.
  Future<void> updatePayment(
    String customerId,
    String paymentId,
    double newAmount,
  );

  Future<void> deletePayment(String customerId, String paymentId);

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

  Future<void> deleteNotification(String notificationId);

  /// Writes the public, view-only receipt document that the customer QR
  /// code links to.
  Future<void> publishCustomerView(String customerId);

  Stream<List<StaffRequest>> watchStaffRequests();

  /// Approved staff accounts (the Staff list tab).
  Stream<List<StaffRequest>> watchStaffList();

  /// Admin-defined pre-made packages, selectable in the New Customer form.
  Stream<List<PackageTemplate>> watchPackageTemplates();

  /// Full payment history of a customer, newest first.
  Stream<List<PaymentEntry>> watchPayments(String customerId);

  /// Creates or updates a package template (admin only). Returns the saved
  /// template with its document id.
  Future<PackageTemplate> savePackageTemplate(PackageTemplate template);

  Future<void> deletePackageTemplate(String templateId);

  Future<void> approveStaff(String uid);

  Future<void> rejectStaff(String uid);
}
