import 'package:flutter/material.dart';

import '../data/customer_store.dart';
import '../models/payment_request.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/empty_state.dart';
import '../widgets/page_header.dart';

/// Staff payment requests awaiting administrator approval.
class PaymentsScreen extends StatefulWidget {
  final CustomerStore store;

  const PaymentsScreen({super.key, required this.store});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    widget.store.addListener(_onStoreChanged);
  }

  void _onStoreChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.store.removeListener(_onStoreChanged);
    super.dispose();
  }

  String _paymentKindLabel(PaymentRequest request) {
    return request.kind == 'full' ? 'Full payment' : 'Partial payment';
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment request updated.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _approvePayment(PaymentRequest request) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(
          Icons.payments_rounded,
          color: Theme.of(context).colorScheme.primary,
          size: 26,
        ),
        title: const Text('Approve payment'),
        content: Text(
          'Record a ${_paymentKindLabel(request).toLowerCase()} of '
          '${formatPeso(request.amount)} for ${request.customerName} '
          '(${request.customerId})?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Approve'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _run(() => widget.store.approvePaymentRequest(request.id));
  }

  Future<void> _rejectPayment(PaymentRequest request) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(
          Icons.cancel_outlined,
          color: Theme.of(context).colorScheme.error,
          size: 26,
        ),
        title: const Text('Reject payment'),
        content: Text(
          'Reject the ${_paymentKindLabel(request).toLowerCase()} of '
          '${formatPeso(request.amount)} for ${request.customerName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _run(() => widget.store.rejectPaymentRequest(request.id));
  }

  @override
  Widget build(BuildContext context) {
    final requests = widget.store.pendingPaymentRequests;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PageHeader(
                icon: Icons.payments_rounded,
                title: 'Payments',
                subtitle:
                    'Staff-submitted payments awaiting your approval before '
                    'they are applied to an account.',
              ),
              const SizedBox(height: 20),
              if (requests.isEmpty)
                Card(
                  child: EmptyState(
                    icon: Icons.payments_rounded,
                    title: 'No payment requests',
                    message:
                        'When staff record a payment, it will appear here '
                        'for your approval before it is applied.',
                  ),
                )
              else
                for (final request in requests) ...[
                  _buildRequestCard(context, request),
                  const SizedBox(height: 14),
                ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRequestCard(BuildContext context, PaymentRequest request) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final palette = AppPalette.of(context);
    final isFull = request.kind == 'full';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.09),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.payments_rounded,
                    size: 20,
                    color: scheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.customerName.isEmpty
                            ? request.customerId
                            : request.customerName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        request.customerId,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: palette.muted,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: palette.brandSoft,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: scheme.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Text(
                    _paymentKindLabel(request),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              formatPeso(request.amount),
              style: theme.textTheme.headlineSmall?.copyWith(
                fontFamily: 'Lora',
                fontWeight: FontWeight.w700,
                color: scheme.primary,
              ),
            ),
            if (request.note.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                request.note,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: palette.muted,
                  height: 1.4,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.person_outline_rounded,
                  size: 14,
                  color: palette.muted,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    request.requestedByEmail.isEmpty
                        ? 'Requested by staff'
                        : 'Requested by ${request.requestedByEmail}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: palette.muted,
                    ),
                  ),
                ),
                Text(
                  _formatDateTime(request.requestedAt),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: palette.muted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: _busy ? null : () => _rejectPayment(request),
                  icon: const Icon(Icons.close_rounded, size: 17),
                  label: const Text('Reject'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: palette.danger,
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: _busy ? null : () => _approvePayment(request),
                  icon: const Icon(Icons.check_rounded, size: 17),
                  label: Text(isFull ? 'Approve full payment' : 'Approve partial payment'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime date) {
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
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '${months[date.month - 1]} ${date.day}, $hour:$minute $period';
  }
}
