import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Public, read-only receipt page that customers reach by scanning the QR
/// code given to them by an admin or staff member.
///
/// It is intentionally reachable without signing in. Access is gated by the
/// unguessable document id `<customerId>-<viewKey>` that is embedded in the
/// QR link, and the document only ever contains receipt-safe fields.
class CustomerViewScreen extends StatefulWidget {
  final String customerId;
  final String viewKey;

  const CustomerViewScreen({
    super.key,
    required this.customerId,
    required this.viewKey,
  });

  @override
  State<CustomerViewScreen> createState() => _CustomerViewScreenState();
}

class _CustomerViewScreenState extends State<CustomerViewScreen> {
  late final Future<Map<String, dynamic>?> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<Map<String, dynamic>?> _load() async {
    final id = widget.customerId.trim();
    final key = widget.viewKey.trim();
    if (id.isEmpty || key.length < 4 || !RegExp(r'^[a-z0-9]+$').hasMatch(key)) {
      return null;
    }
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('customerViews')
          .doc('$id-$key')
          .get();
      return snapshot.data();
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Receipt'),
        automaticallyImplyLeading: false,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.primary.withValues(alpha: 0.06),
              Colors.transparent,
            ],
            stops: const [0, 0.3],
          ),
        ),
        child: FutureBuilder<Map<String, dynamic>?>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final data = snapshot.data;
            if (data == null || data.isEmpty) {
              return _buildInvalid(context);
            }
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 620),
                  child: _buildReceipt(context, data),
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Text(
            'Paradise Funeral Home · Management System',
            textAlign: TextAlign.center,
            style: theme.textTheme.labelSmall?.copyWith(
              color: palette.muted,
              letterSpacing: 0.6,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInvalid(BuildContext context) {
    final palette = AppPalette.of(context);
    return Center(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.link_off_rounded,
                size: 40,
                color: palette.muted,
              ),
              const SizedBox(height: 14),
              const Text(
                'Receipt link is invalid',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
              const SizedBox(height: 6),
              const Text(
                'This link may be incomplete or no longer available. '
                'Please ask Paradise Funeral Home staff for a new QR code.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReceipt(BuildContext context, Map<String, dynamic> data) {
    final theme = Theme.of(context);
    final palette = AppPalette.of(context);

    final name = data['name'] as String? ?? '';
    final customerId = data['customerId'] as String? ?? '';
    final packageName = data['package'] as String? ?? '';
    final packageTotal = _centavos(data['packageTotalCentavos']);
    final discount = _centavos(data['approvedDiscountCentavos']);
    final amountPaid = _centavos(data['amountPaidCentavos']);
    final totalDue = _centavos(data['totalDueCentavos']);
    final balance = (totalDue - amountPaid).clamp(0, totalDue);
    final status = data['accountStatus'] as String? ?? 'active';
    final dueDate = _date(data['dueDate']);
    final items = (data['items'] as List?)
            ?.map((item) => Map<String, dynamic>.from(item as Map))
            .toList() ??
        const <Map<String, dynamic>>[];
    final payments = (data['payments'] as List?)
            ?.map((item) => Map<String, dynamic>.from(item as Map))
            .toList() ??
        const <Map<String, dynamic>>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [palette.heroStart, palette.heroEnd],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.local_florist_rounded, color: Colors.white),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Paradise Funeral Home',
                      style: TextStyle(
                        fontFamily: 'Bitter',
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Official account receipt · view only',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 11,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                customerId,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.82),
                  fontSize: 11,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _row(context, 'Status', _statusLabel(status)),
                _row(context, 'Package', packageName),
                if (dueDate != null)
                  _row(context, 'Due date', _formatDate(dueDate)),
                const Divider(height: 22),
                Text(
                  'Package items',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                if (items.isEmpty)
                  Text(
                    'No item breakdown recorded.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: palette.muted,
                    ),
                  )
                else
                  for (final item in items)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              item['name'] as String? ?? '',
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                          Text(
                            _peso(_centavos(item['amountCentavos'])),
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                const Divider(height: 22),
                _row(context, 'Package total', _peso(packageTotal)),
                if (discount > 0)
                  _row(context, 'Approved discount', '-${_peso(discount)}'),
                _row(context, 'Total due', _peso(totalDue)),
                _row(context, 'Amount paid', _peso(amountPaid)),
                _row(
                  context,
                  'Remaining balance',
                  _peso(balance),
                  valueColor: balance <= 0 ? palette.success : palette.danger,
                  bold: true,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Payment history',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                if (payments.isEmpty)
                  Text(
                    'No payments recorded yet.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: palette.muted,
                    ),
                  )
                else
                  for (final payment in payments)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Icon(
                            Icons.payments_rounded,
                            size: 15,
                            color: palette.success,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _paymentDate(payment['recordedAt']),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: palette.muted,
                              ),
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                _peso(_centavos(payment['amountCentavos'])),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                'Balance: '
                                '${_peso(_centavos(payment['balanceAfterCentavos']))}',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: palette.muted,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'This page is read-only. For changes, please contact '
          'Paradise Funeral Home staff.',
          textAlign: TextAlign.center,
          style: theme.textTheme.labelSmall?.copyWith(
            color: palette.muted,
            fontSize: 10.5,
          ),
        ),
      ],
    );
  }

  Widget _row(
    BuildContext context,
    String label,
    String value, {
    Color? valueColor,
    bool bold = false,
  }) {
    final theme = Theme.of(context);
    final palette = AppPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: palette.muted,
              ),
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  int _centavos(Object? value) => (value as num?)?.toInt() ?? 0;

  DateTime? _date(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  String _peso(int centavos) =>
      '₱${(centavos / 100).toStringAsFixed(2)}';

  String _statusLabel(String status) {
    switch (status) {
      case 'delayed':
        return 'Delayed';
      case 'completed':
        return 'Completed';
      default:
        return 'Active';
    }
  }

  String _paymentDate(Object? value) {
    final date = _date(value);
    if (date == null) return 'Payment';
    return _formatDate(date);
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
