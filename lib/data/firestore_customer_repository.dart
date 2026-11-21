import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../auth/app_user.dart';
import '../auth/auth_constants.dart';
import '../config/app_config.dart';
import '../models/app_notification.dart';
import '../models/customer.dart';
import '../models/discount_request.dart';
import '../models/staff_request.dart';
import 'customer_repository.dart';

class FirestoreCustomerRepository implements CustomerRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  FirestoreCustomerRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _customers =>
      _firestore.collection('customers');

  CollectionReference<Map<String, dynamic>> get _discountRequests =>
      _firestore.collection('discountRequests');

  CollectionReference<Map<String, dynamic>> get _notifications =>
      _firestore.collection('notifications');

  DocumentReference<Map<String, dynamic>> _customerRef(String id) =>
      _customers.doc(id);

  User _requireUser() {
    final user = _auth.currentUser;
    if (user == null) {
      throw const CustomerRepositoryException('You must be signed in.');
    }
    return user;
  }

  @override
  Stream<List<Customer>> watchCustomers() {
    return _auth.authStateChanges().asyncExpand((user) {
      if (user == null) {
        return Stream.value(const <Customer>[]);
      }
      return _customers
          .snapshots()
          .map((snapshot) {
            final customers = <Customer>[];
            for (final doc in snapshot.docs) {
              try {
                customers.add(_fromDocument(doc));
              } catch (_) {
                // Ignore malformed documents so one bad record cannot block
                // the whole customer list.
              }
            }
            return customers;
          });
    });
  }

  @override
  Future<Customer> createCustomer(Customer customer) async {
    final user = _requireUser();
    return _run(() {
      return _firestore.runTransaction((transaction) async {
        final counterRef = _firestore.collection('counters').doc('customers');
        final counterSnapshot = await transaction.get(counterRef);
        var lastId =
            (counterSnapshot.data()?['lastId'] as num?)?.toInt() ?? 0;

        final id = customer.id.isEmpty
            ? 'CUS-${(lastId + 1).toString().padLeft(4, '0')}'
            : customer.id;

        final explicitNumber = int.tryParse(
          RegExp(r'(\d+)$').firstMatch(id)?.group(1) ?? '',
        );
        if (explicitNumber != null && explicitNumber > lastId) {
          lastId = explicitNumber;
        } else if (customer.id.isEmpty) {
          lastId += 1;
        }

        final customerRef = _customerRef(id);
        final existing = await transaction.get(customerRef);
        if (existing.exists) {
          throw const CustomerRepositoryException(
            'A customer with that ID already exists.',
          );
        }

        final created = customer.copyWith(id: id);
        transaction.set(
          customerRef,
          _createData(created, user: user),
        );
        transaction.set(
          counterRef,
          {'lastId': lastId},
          SetOptions(merge: true),
        );
        return created;
      });
    });
  }

  @override
  Future<void> updateCustomer(Customer customer) async {
    final user = _requireUser();
    await _run(() async {
      final data = <String, dynamic>{
        'name': customer.name,
        'address': customer.address,
        'contactNumber': customer.contactNumber,
        'package': customer.package,
        'items': customer.items
            .map(
              (item) => {
                'name': item.name,
                'amountCentavos': item.amountCentavos,
              },
            )
            .toList(),
        'amountPaidCentavos': customer.amountPaidCentavos,
        'approvedDiscountCentavos': customer.approvedDiscountCentavos,
        'packageTotalCentavos': customer.totalPackageCostCentavos,
        'totalDueCentavos': customer.totalDueCentavos,
        'remarks': customer.remarks,
        'dateAdded': Timestamp.fromDate(customer.dateAdded),
        'dueDate': Timestamp.fromDate(customer.dueDate),
        'accountStatus': customer.accountStatus.name,
        'lastPaymentDate': customer.lastPaymentDate == null
            ? null
            : Timestamp.fromDate(customer.lastPaymentDate!),
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': user.uid,
      };
      if (customer.pendingDiscountRequestId == null) {
        data['pendingDiscountRequestId'] = FieldValue.delete();
      } else {
        data['pendingDiscountRequestId'] = customer.pendingDiscountRequestId;
      }
      await _customerRef(customer.id).update(data);
    });
  }

  @override
  Future<void> recordPayment(
    String customerId,
    double amount, {
    String? note,
  }) async {
    final user = _requireUser();
    final amountCentavos = (amount * 100).round();
    if (amountCentavos <= 0) {
      throw const CustomerRepositoryException(
        'Payment must be greater than zero.',
      );
    }

    await _run(() {
      return _firestore.runTransaction((transaction) async {
        final customerRef = _customerRef(customerId);
        final snapshot = await transaction.get(customerRef);
        if (!snapshot.exists) {
          throw const CustomerRepositoryException('Customer not found.');
        }
        final data = snapshot.data()!;
        final currentPaid =
            (data['amountPaidCentavos'] as num?)?.toInt() ?? 0;
        final totalDue =
            (data['totalDueCentavos'] as num?)?.toInt() ??
            ((data['packageTotalCentavos'] as num?)?.toInt() ?? 0) -
                ((data['approvedDiscountCentavos'] as num?)?.toInt() ?? 0);
        final remaining = totalDue - currentPaid;
        if (remaining <= 0) {
          throw const CustomerRepositoryException(
            'This account is already fully paid.',
          );
        }
        if (amountCentavos > remaining) {
          throw const CustomerRepositoryException(
            'Payment exceeds the remaining balance.',
          );
        }

        final balanceAfter = remaining - amountCentavos;
        final paymentRef = customerRef.collection('payments').doc();
        final completed = balanceAfter <= 0;

        transaction.set(paymentRef, {
          'customerId': customerId,
          'amountCentavos': amountCentavos,
          'balanceAfterCentavos': balanceAfter,
          'note': note ?? '',
          'recordedBy': {'uid': user.uid, 'email': user.email ?? ''},
          'recordedAt': FieldValue.serverTimestamp(),
        });
        transaction.update(customerRef, {
          'amountPaidCentavos': currentPaid + amountCentavos,
          'lastPaymentDate': FieldValue.serverTimestamp(),
          'lastPaymentId': paymentRef.id,
          'accountStatus': completed
              ? 'completed'
              : (data['accountStatus'] as String? ?? 'active'),
          'updatedAt': FieldValue.serverTimestamp(),
          'updatedBy': user.uid,
        });
        transaction.set(
          _firestore.collection('auditLogs').doc(),
          _auditData(
            user: user,
            action: 'payment_recorded',
            customerId: customerId,
            extra: {
              'paymentId': paymentRef.id,
              'amountCentavos': amountCentavos,
              'balanceAfterCentavos': balanceAfter,
            },
          ),
        );
        if (completed) {
          final customerName = data['name'] as String? ?? customerId;
          transaction.set(
            _notifications.doc(),
            _notificationData(
              user: user,
              type: AppNotificationType.paymentCompleted,
              title: 'Account fully paid',
              message:
                  '$customerName ($customerId) is now fully paid. The account has been moved to Completed.',
              customerId: customerId,
              audienceRole: 'admin',
            ),
          );
        }
      });
    });
  }

  @override
  Future<void> restoreToActive(Customer customer) async {
    final user = _requireUser();
    final now = DateTime.now();
    final dueDate = customer.dueDate.isBefore(now)
        ? now.add(const Duration(days: 30))
        : customer.dueDate;
    await _run(() async {
      await _customerRef(customer.id).update({
        'accountStatus': 'active',
        'dueDate': Timestamp.fromDate(dueDate),
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': user.uid,
      });
      await _firestore.collection('auditLogs').add(
        _auditData(
          user: user,
          action: 'customer_restored',
          customerId: customer.id,
          extra: {'dueDate': Timestamp.fromDate(dueDate)},
        ),
      );
    });
  }

  @override
  Future<void> markAsCompleted(Customer customer) async {
    final user = _requireUser();
    await _run(() async {
      await _customerRef(customer.id).update({
        'accountStatus': 'completed',
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': user.uid,
      });
      await _firestore.collection('auditLogs').add(
        _auditData(
          user: user,
          action: 'customer_completed',
          customerId: customer.id,
        ),
      );
    });
  }

  @override
  Future<void> deleteCustomer(String customerId) async {
    final user = _requireUser();
    await _run(() async {
      final customerRef = _customerRef(customerId);
      final payments = await customerRef.collection('payments').get();
      final batch = _firestore.batch();
      for (final payment in payments.docs) {
        batch.delete(payment.reference);
      }
      batch.delete(customerRef);
      batch.set(
        _firestore.collection('auditLogs').doc(),
        _auditData(
          user: user,
          action: 'customer_deleted',
          customerId: customerId,
          extra: {'paymentCount': payments.size},
        ),
      );
      await batch.commit();
    });
  }

  @override
  Future<int> importCustomers(List<Customer> customers) async {
    final user = _requireUser();
    if (customers.isEmpty) return 0;

    return _run(() async {
      final existing = await _customers.get();
      final existingIds = existing.docs.map((doc) => doc.id).toSet();
      final seen = <String>{};
      final candidates = customers.where((customer) {
        if (customer.id.isEmpty || existingIds.contains(customer.id)) {
          return false;
        }
        return seen.add(customer.id);
      }).toList();

      var imported = 0;
      for (var start = 0; start < candidates.length; start += 400) {
        final chunk = candidates.skip(start).take(400).toList();
        final batch = _firestore.batch();
        for (final customer in chunk) {
          batch.set(
            _customerRef(customer.id),
            _createData(customer, user: user, imported: true),
          );
        }
        batch.set(
          _firestore.collection('auditLogs').doc(),
          _auditData(
            user: user,
            action: 'customers_imported',
            extra: {'count': chunk.length},
          ),
        );
        await batch.commit();
        imported += chunk.length;
      }

      var highest = 0;
      for (final customer in candidates) {
        final value = int.tryParse(
          RegExp(r'(\d+)$').firstMatch(customer.id)?.group(1) ?? '',
        );
        if (value != null && value > highest) highest = value;
      }
      if (highest > 0) {
        final counterRef = _firestore.collection('counters').doc('customers');
        await _firestore.runTransaction((transaction) async {
          final snapshot = await transaction.get(counterRef);
          final current =
              (snapshot.data()?['lastId'] as num?)?.toInt() ?? 0;
          if (highest > current) {
            transaction.set(
              counterRef,
              {'lastId': highest},
              SetOptions(merge: true),
            );
          }
        });
      }
      return imported;
    });
  }

  @override
  Stream<List<DiscountRequest>> watchDiscountRequests() {
    return _auth.authStateChanges().asyncExpand((user) {
      if (user == null) {
        return Stream.value(const <DiscountRequest>[]);
      }
      return Stream.fromFuture(_roleFor(user.uid)).asyncExpand((role) {
        final query = role == 'admin'
            ? _discountRequests
            : _discountRequests.where('requestedBy.uid', isEqualTo: user.uid);
        return query.snapshots().map((snapshot) {
          final requests = snapshot.docs
              .map(_discountRequestFromDocument)
              .toList();
          requests.sort((a, b) => b.requestedAt.compareTo(a.requestedAt));
          return requests;
        });
      });
    });
  }

  @override
  Future<void> requestDiscount(
    String customerId,
    double amount,
    String reason,
  ) async {
    final user = _requireUser();
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

    await _run(() {
      return _firestore.runTransaction((transaction) async {
        final customerRef = _customerRef(customerId);
        final snapshot = await transaction.get(customerRef);
        if (!snapshot.exists) {
          throw const CustomerRepositoryException('Customer not found.');
        }
        final data = snapshot.data()!;
        final pendingId = data['pendingDiscountRequestId'] as String?;
        if (pendingId != null && pendingId.isNotEmpty) {
          throw const CustomerRepositoryException(
            'A discount request is already pending for this account.',
          );
        }
        final totalDue =
            (data['totalDueCentavos'] as num?)?.toInt() ??
            ((data['packageTotalCentavos'] as num?)?.toInt() ?? 0) -
                ((data['approvedDiscountCentavos'] as num?)?.toInt() ?? 0);
        final paid = (data['amountPaidCentavos'] as num?)?.toInt() ?? 0;
        final remaining = totalDue - paid;
        if (remaining <= 0) {
          throw const CustomerRepositoryException(
            'This account is already fully paid.',
          );
        }
        if (amountCentavos > remaining) {
          throw const CustomerRepositoryException(
            'Discount exceeds the remaining balance.',
          );
        }

        final requestRef = _discountRequests.doc();
        final customerName = data['name'] as String? ?? customerId;
        transaction.set(requestRef, {
          'customerId': customerId,
          'customerName': customerName,
          'amountCentavos': amountCentavos,
          'reason': trimmedReason,
          'status': 'pending',
          'requestedBy': {
            'uid': user.uid,
            'email': user.email ?? '',
            'name': user.displayName ?? '',
          },
          'requestedAt': FieldValue.serverTimestamp(),
        });
        transaction.update(customerRef, {
          'pendingDiscountRequestId': requestRef.id,
          'updatedAt': FieldValue.serverTimestamp(),
          'updatedBy': user.uid,
        });
        transaction.set(
          _notifications.doc(),
          _notificationData(
            user: user,
            type: AppNotificationType.discountRequested,
            title: 'New discount request',
            message:
                '$customerName ($customerId) requested a ₱${(amountCentavos / 100).toStringAsFixed(2)} discount.',
            customerId: customerId,
            requestId: requestRef.id,
            audienceRole: 'admin',
          ),
        );
        transaction.set(
          _firestore.collection('auditLogs').doc(),
          _auditData(
            user: user,
            action: 'discount_requested',
            customerId: customerId,
            extra: {
              'requestId': requestRef.id,
              'amountCentavos': amountCentavos,
              'reason': trimmedReason,
            },
          ),
        );
      });
    });
  }

  @override
  Future<void> approveDiscountRequest(String requestId, {String? note}) async {
    final user = _requireUser();
    await _run(() {
      return _firestore.runTransaction((transaction) async {
        final requestRef = _discountRequests.doc(requestId);
        final requestSnapshot = await transaction.get(requestRef);
        if (!requestSnapshot.exists) {
          throw const CustomerRepositoryException('Discount request not found.');
        }
        final request = requestSnapshot.data()!;
        if ((request['status'] as String?) != 'pending') {
          throw const CustomerRepositoryException(
            'This request has already been reviewed.',
          );
        }

        final customerId = request['customerId'] as String? ?? '';
        final customerRef = _customerRef(customerId);
        final customerSnapshot = await transaction.get(customerRef);
        if (!customerSnapshot.exists) {
          throw const CustomerRepositoryException('Customer not found.');
        }
        final data = customerSnapshot.data()!;
        final amountCentavos =
            (request['amountCentavos'] as num?)?.toInt() ?? 0;
        final packageTotal =
            (data['packageTotalCentavos'] as num?)?.toInt() ?? 0;
        final approvedDiscount =
            (data['approvedDiscountCentavos'] as num?)?.toInt() ?? 0;
        final paid = (data['amountPaidCentavos'] as num?)?.toInt() ?? 0;
        final remaining = packageTotal - approvedDiscount - paid;
        if (amountCentavos > remaining) {
          throw const CustomerRepositoryException(
            'The requested discount now exceeds the remaining balance. Reject it instead.',
          );
        }

        final newDiscount = approvedDiscount + amountCentavos;
        final newTotalDue = (packageTotal - newDiscount).clamp(0, packageTotal);
        final completed = newTotalDue - paid <= 0;
        final customerName = data['name'] as String? ?? customerId;
        final requesterUid = (request['requestedBy'] as Map?)?['uid'] as String?;

        transaction.update(requestRef, {
          'status': 'approved',
          'reviewedBy': {'uid': user.uid, 'email': user.email ?? ''},
          'reviewedAt': FieldValue.serverTimestamp(),
          'reviewNote': (note ?? '').trim(),
        });
        transaction.update(customerRef, {
          'approvedDiscountCentavos': newDiscount,
          'totalDueCentavos': newTotalDue,
          'pendingDiscountRequestId': FieldValue.delete(),
          'accountStatus': completed
              ? 'completed'
              : (data['accountStatus'] as String? ?? 'active'),
          'updatedAt': FieldValue.serverTimestamp(),
          'updatedBy': user.uid,
        });
        if (requesterUid != null && requesterUid.isNotEmpty) {
          transaction.set(
            _notifications.doc(),
            _notificationData(
              user: user,
              type: AppNotificationType.discountApproved,
              title: 'Discount approved',
              message:
                  'Your ₱${(amountCentavos / 100).toStringAsFixed(2)} discount request for $customerName ($customerId) was approved.',
              customerId: customerId,
              requestId: requestId,
              recipientUid: requesterUid,
            ),
          );
        }
        transaction.set(
          _firestore.collection('auditLogs').doc(),
          _auditData(
            user: user,
            action: 'discount_approved',
            customerId: customerId,
            extra: {
              'requestId': requestId,
              'amountCentavos': amountCentavos,
            },
          ),
        );
      });
    });
  }

  @override
  Future<void> rejectDiscountRequest(String requestId, {String? note}) async {
    final user = _requireUser();
    await _run(() {
      return _firestore.runTransaction((transaction) async {
        final requestRef = _discountRequests.doc(requestId);
        final requestSnapshot = await transaction.get(requestRef);
        if (!requestSnapshot.exists) {
          throw const CustomerRepositoryException('Discount request not found.');
        }
        final request = requestSnapshot.data()!;
        if ((request['status'] as String?) != 'pending') {
          throw const CustomerRepositoryException(
            'This request has already been reviewed.',
          );
        }

        final customerId = request['customerId'] as String? ?? '';
        final customerRef = _customerRef(customerId);
        final customerSnapshot = await transaction.get(customerRef);
        if (!customerSnapshot.exists) {
          throw const CustomerRepositoryException('Customer not found.');
        }
        final data = customerSnapshot.data()!;
        final amountCentavos =
            (request['amountCentavos'] as num?)?.toInt() ?? 0;
        final customerName = data['name'] as String? ?? customerId;
        final requesterUid = (request['requestedBy'] as Map?)?['uid'] as String?;

        transaction.update(requestRef, {
          'status': 'rejected',
          'reviewedBy': {'uid': user.uid, 'email': user.email ?? ''},
          'reviewedAt': FieldValue.serverTimestamp(),
          'reviewNote': (note ?? '').trim(),
        });
        transaction.update(customerRef, {
          'pendingDiscountRequestId': FieldValue.delete(),
          'updatedAt': FieldValue.serverTimestamp(),
          'updatedBy': user.uid,
        });
        if (requesterUid != null && requesterUid.isNotEmpty) {
          transaction.set(
            _notifications.doc(),
            _notificationData(
              user: user,
              type: AppNotificationType.discountRejected,
              title: 'Discount request rejected',
              message:
                  'Your ₱${(amountCentavos / 100).toStringAsFixed(2)} discount request for $customerName ($customerId) was rejected.',
              customerId: customerId,
              requestId: requestId,
              recipientUid: requesterUid,
            ),
          );
        }
        transaction.set(
          _firestore.collection('auditLogs').doc(),
          _auditData(
            user: user,
            action: 'discount_rejected',
            customerId: customerId,
            extra: {
              'requestId': requestId,
              'amountCentavos': amountCentavos,
            },
          ),
        );
      });
    });
  }

  @override
  Stream<List<AppNotification>> watchNotifications({AppRole? viewAs}) {
    return _auth.authStateChanges().asyncExpand((user) {
      if (user == null) {
        return Stream.value(const <AppNotification>[]);
      }
      final roleFuture = viewAs != null
          ? Future.value(viewAs.value)
          : _roleFor(user.uid);
      return Stream.fromFuture(roleFuture).asyncExpand((role) {
        final query = role == 'admin'
            ? _notifications.where('audienceRole', isEqualTo: 'admin')
            : _notifications.where('recipientUid', isEqualTo: user.uid);
        return query.snapshots().map((snapshot) {
          final notifications = snapshot.docs
              .map(_notificationFromDocument)
              .toList();
          notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return notifications;
        });
      });
    });
  }

  @override
  Future<void> markNotificationRead(String notificationId) async {
    final user = _requireUser();
    await _run(() async {
      await _notifications.doc(notificationId).update({
        'readBy': FieldValue.arrayUnion([user.uid]),
      });
    });
  }

  @override
  Future<void> markNotificationUnread(String notificationId) async {
    final user = _requireUser();
    await _run(() async {
      await _notifications.doc(notificationId).update({
        'readBy': FieldValue.arrayRemove([user.uid]),
      });
    });
  }

  @override
  Future<void> publishCustomerView(String customerId) async {
    final user = _requireUser();
    await _run(() async {
      final customerSnapshot = await _customerRef(customerId).get();
      if (!customerSnapshot.exists) {
        throw const CustomerRepositoryException('Customer not found.');
      }
      final data = customerSnapshot.data()!;

      final paymentsSnapshot =
          await _customerRef(customerId).collection('payments').get();
      final payments = paymentsSnapshot.docs
          .map((doc) {
            final payment = doc.data();
            final recordedAt = payment['recordedAt'];
            return {
              'amountCentavos':
                  (payment['amountCentavos'] as num?)?.toInt() ?? 0,
              'balanceAfterCentavos':
                  (payment['balanceAfterCentavos'] as num?)?.toInt() ?? 0,
              'recordedAt':
                  recordedAt is Timestamp ? recordedAt.toDate() : null,
            };
          })
          .toList()
        ..sort((a, b) {
          final aDate = a['recordedAt'] as DateTime?;
          final bDate = b['recordedAt'] as DateTime?;
          if (aDate == null || bDate == null) return 0;
          return bDate.compareTo(aDate);
        });

      final viewKey = customerViewKey(customerId);
      await _firestore.collection('customerViews').doc('$customerId-$viewKey').set({
        'customerId': customerId,
        'name': data['name'] ?? '',
        'package': data['package'] ?? '',
        'items': data['items'] ?? const [],
        'packageTotalCentavos':
            (data['packageTotalCentavos'] as num?)?.toInt() ?? 0,
        'approvedDiscountCentavos':
            (data['approvedDiscountCentavos'] as num?)?.toInt() ?? 0,
        'amountPaidCentavos': (data['amountPaidCentavos'] as num?)?.toInt() ?? 0,
        'totalDueCentavos': (data['totalDueCentavos'] as num?)?.toInt() ?? 0,
        'dateAdded': data['dateAdded'],
        'dueDate': data['dueDate'],
        'accountStatus': data['accountStatus'] ?? 'active',
        'payments': payments.take(12).toList(),
        'publishedAt': FieldValue.serverTimestamp(),
        'publishedBy': user.uid,
      });
    });
  }

  @override
  Stream<List<StaffRequest>> watchStaffRequests() {
    return _auth.authStateChanges().asyncExpand((user) {
      if (user == null) return Stream.value(const <StaffRequest>[]);
      return Stream.fromFuture(_roleFor(user.uid)).asyncExpand((role) {
        if (role != 'admin') return Stream.value(const <StaffRequest>[]);
        return _firestore
            .collection(kUsersCollection)
            .where('approvalStatus', isEqualTo: 'pending')
            .snapshots()
            .map((snapshot) {
              final requests =
                  snapshot.docs
                      .where((doc) => (doc.data()['role'] as String?) == 'staff')
                      .map(_staffRequestFromDocument)
                      .toList()
                    ..sort(
                      (a, b) => b.requestedAt.compareTo(a.requestedAt),
                    );
              return requests;
            });
      });
    });
  }

  @override
  Stream<List<StaffRequest>> watchStaffList() {
    return _auth.authStateChanges().asyncExpand((user) {
      if (user == null) return Stream.value(const <StaffRequest>[]);
      return Stream.fromFuture(_roleFor(user.uid)).asyncExpand((role) {
        if (role != 'admin') return Stream.value(const <StaffRequest>[]);
        return _firestore
            .collection(kUsersCollection)
            .where('role', isEqualTo: 'staff')
            .where('approvalStatus', isEqualTo: 'approved')
            .snapshots()
            .map((snapshot) {
              final staff =
                  snapshot.docs.map(_staffRequestFromDocument).toList()
                    ..sort(
                      (a, b) => a.name.toLowerCase().compareTo(
                        b.name.toLowerCase(),
                      ),
                    );
              return staff;
            });
      });
    });
  }

  @override
  Future<void> approveStaff(String uid) => _reviewStaff(uid, 'approved');

  @override
  Future<void> rejectStaff(String uid) => _reviewStaff(uid, 'rejected');

  Future<void> _reviewStaff(String uid, String status) async {
    final user = _requireUser();
    await _run(() async {
      await _firestore.collection(kUsersCollection).doc(uid).update({
        'approvalStatus': status,
        'reviewedAt': FieldValue.serverTimestamp(),
        'reviewedBy': user.uid,
      });
    });
  }

  Future<String> _roleFor(String uid) async {
    try {
      final snapshot = await _firestore.collection('users').doc(uid).get();
      return snapshot.data()?['role'] as String? ?? 'staff';
    } catch (_) {
      return 'staff';
    }
  }

  Map<String, dynamic> _notificationData({
    required User user,
    required AppNotificationType type,
    required String title,
    required String message,
    required String customerId,
    String? requestId,
    String? audienceRole,
    String? recipientUid,
  }) {
    final data = <String, dynamic>{
      'type': type.value,
      'title': title,
      'message': message,
      'customerId': customerId,
      'createdBy': {'uid': user.uid, 'email': user.email ?? ''},
      'createdAt': FieldValue.serverTimestamp(),
      'readBy': <String>[],
    };
    if (requestId != null) data['requestId'] = requestId;
    if (audienceRole != null) data['audienceRole'] = audienceRole;
    if (recipientUid != null) data['recipientUid'] = recipientUid;
    return data;
  }

  StaffRequest _staffRequestFromDocument(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const <String, dynamic>{};
    final createdAt = data['createdAt'];
    return StaffRequest(
      uid: doc.id,
      name: (data['name'] as String?)?.trim() ?? '',
      email: (data['email'] as String?)?.trim() ?? '',
      requestedAt: createdAt is Timestamp ? createdAt.toDate() : DateTime.now(),
    );
  }

  DiscountRequest _discountRequestFromDocument(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const <String, dynamic>{};
    final requestedBy = Map<String, dynamic>.from(
      data['requestedBy'] as Map? ?? const {},
    );
    final reviewedBy = data['reviewedBy'] is Map
        ? Map<String, dynamic>.from(data['reviewedBy'] as Map)
        : const <String, dynamic>{};
    return DiscountRequest(
      id: doc.id,
      customerId: data['customerId'] as String? ?? '',
      customerName: data['customerName'] as String? ?? '',
      amountCentavos: (data['amountCentavos'] as num?)?.toInt() ?? 0,
      reason: data['reason'] as String? ?? '',
      status: DiscountRequestStatusX.fromValue(data['status'] as String?),
      requestedByUid: requestedBy['uid'] as String? ?? '',
      requestedByEmail: requestedBy['email'] as String? ?? '',
      requestedByName: requestedBy['name'] as String? ?? '',
      requestedAt: _date(data['requestedAt']) ?? DateTime.now(),
      reviewedByUid: reviewedBy['uid'] as String?,
      reviewedByEmail: reviewedBy['email'] as String?,
      reviewedAt: _date(data['reviewedAt']),
      reviewNote: data['reviewNote'] as String? ?? '',
    );
  }

  AppNotification _notificationFromDocument(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const <String, dynamic>{};
    final createdBy = Map<String, dynamic>.from(
      data['createdBy'] as Map? ?? const {},
    );
    return AppNotification(
      id: doc.id,
      type: AppNotificationTypeX.fromValue(data['type'] as String?),
      title: data['title'] as String? ?? '',
      message: data['message'] as String? ?? '',
      audienceRole: data['audienceRole'] as String?,
      recipientUid: data['recipientUid'] as String?,
      customerId: data['customerId'] as String? ?? '',
      requestId: data['requestId'] as String?,
      staffUid: data['staffUid'] as String?,
      createdByUid: createdBy['uid'] as String? ?? '',
      createdAt: _date(data['createdAt']) ?? DateTime.now(),
      readBy:
          (data['readBy'] as List?)
              ?.map((value) => value.toString())
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> _createData(
    Customer customer, {
    required User user,
    bool imported = false,
  }) {
    final data = <String, dynamic>{
      'name': customer.name,
      'address': customer.address,
      'contactNumber': customer.contactNumber,
      'package': customer.package,
      'items': customer.items
          .map(
            (item) => {
              'name': item.name,
              'amountCentavos': item.amountCentavos,
            },
          )
          .toList(),
      'amountPaidCentavos': customer.amountPaidCentavos,
      'approvedDiscountCentavos': customer.approvedDiscountCentavos,
      'packageTotalCentavos': customer.totalPackageCostCentavos,
      'totalDueCentavos': customer.totalDueCentavos,
      'remarks': customer.remarks,
      'dateAdded': Timestamp.fromDate(customer.dateAdded),
      'dueDate': Timestamp.fromDate(customer.dueDate),
      'accountStatus': customer.accountStatus.name,
      'lastPaymentDate': customer.lastPaymentDate == null
          ? null
          : Timestamp.fromDate(customer.lastPaymentDate!),
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': user.uid,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': user.uid,
    };
    if (customer.pendingDiscountRequestId != null) {
      data['pendingDiscountRequestId'] = customer.pendingDiscountRequestId;
    }
    if (imported) {
      data['importedAt'] = FieldValue.serverTimestamp();
      data['importedBy'] = user.uid;
    }
    return data;
  }

  Map<String, dynamic> _auditData({
    required User user,
    required String action,
    String? customerId,
    Map<String, dynamic>? extra,
  }) {
    final data = <String, dynamic>{
      'action': action,
      'actorUid': user.uid,
      'actorEmail': user.email ?? '',
      'createdAt': FieldValue.serverTimestamp(),
    };
    if (customerId != null) {
      data['customerId'] = customerId;
    }
    if (extra != null) {
      data.addAll(extra);
    }
    return data;
  }

  Customer _fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    return Customer(
      id: doc.id,
      dateAdded: _date(data['dateAdded']) ?? DateTime.now(),
      name: data['name'] as String? ?? '',
      address: data['address'] as String? ?? '',
      contactNumber: data['contactNumber'] as String? ?? '',
      package: data['package'] as String? ?? '',
      items:
          (data['items'] as List?)
              ?.map((item) {
                final map = Map<String, dynamic>.from(item as Map);
                return PackageItem(
                  name: map['name'] as String? ?? '',
                  amount:
                      ((map['amountCentavos'] as num?)?.toInt() ?? 0) /
                      100.0,
                );
              })
              .toList() ??
          const [],
      amountPaid:
          ((data['amountPaidCentavos'] as num?)?.toInt() ?? 0) / 100.0,
      approvedDiscount:
          ((data['approvedDiscountCentavos'] as num?)?.toInt() ?? 0) /
          100.0,
      pendingDiscountRequestId:
          data['pendingDiscountRequestId'] as String?,
      remarks: data['remarks'] as String? ?? '',
      dueDate: _date(data['dueDate']) ?? DateTime.now(),
      accountStatus: AccountStatus.values.firstWhere(
        (status) => status.name == data['accountStatus'],
        orElse: () => AccountStatus.active,
      ),
      lastPaymentDate: _date(data['lastPaymentDate']),
    );
  }

  DateTime? _date(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  Future<T> _run<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on CustomerRepositoryException {
      rethrow;
    } on FirebaseException catch (error) {
      throw CustomerRepositoryException(_messageFor(error));
    }
  }

  String _messageFor(FirebaseException error) {
    switch (error.code) {
      case 'permission-denied':
        return 'You do not have permission to do that.';
      case 'unavailable':
      case 'network-request-failed':
        return 'Network error. Please try again.';
      case 'not-found':
        return 'That record no longer exists.';
      case 'aborted':
        return 'The data changed. Please try again.';
      default:
        return error.message ?? 'Something went wrong. Please try again.';
    }
  }
}
