import '../utils/formatters.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../auth/app_user.dart';
import '../data/customer_store.dart';
import '../models/customer.dart';
import '../models/payment_entry.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state.dart';
import '../widgets/page_header.dart';
import '../widgets/status_badge.dart';

/// Fully paid accounts awaiting an administrator's approval before they are
/// moved to the Completed / Archive tab.
class PaidAccountsScreen extends StatefulWidget {
  final CustomerStore store;
  final AppUser user;

  const PaidAccountsScreen({
    super.key,
    required this.store,
    required this.user,
  });

  @override
  State<PaidAccountsScreen> createState() => _PaidAccountsScreenState();
}

class _PaidAccountsScreenState extends State<PaidAccountsScreen> {
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

  @override
  Widget build(BuildContext context) {
    final paid = widget.store.paidCustomers;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PageHeader(
                icon: Icons.task_alt_outlined,
                title: 'Paid Accounts',
                subtitle:
                    'Fully paid accounts awaiting approval before they are '
                    'archived.',
              ),
              const SizedBox(height: 20),
              if (paid.isEmpty)
                Card(
                  child: EmptyState(
                    icon: Icons.task_alt_rounded,
                    title: 'No paid accounts to review',
                    message:
                        'When a customer finishes paying, the account moves '
                        'here for your final check before archiving.',
                  ),
                )
              else
                for (final customer in paid) ...[
                  _buildPaidCard(customer),
                  const SizedBox(height: 14),
                ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaidCard(Customer customer) {
    final theme = Theme.of(context);
    final palette = AppPalette.of(context);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => context.push('/paid/${customer.id}'),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: palette.warning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.hourglass_top_rounded,
                  size: 21,
                  color: palette.warning,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      customer.id,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: palette.muted,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'formatPeso(customer.amountPaid) paid',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: palette.success,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Awaiting approval',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: palette.muted,
                      fontSize: 10.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded, color: palette.muted),
            ],
          ),
        ),
      ),
    );
  }
}

/// Detail review page for one paid account: full information, complete
/// payment history, and the admin's Approve action.
class PaidAccountDetailScreen extends StatefulWidget {
  final CustomerStore store;
  final AppUser user;
  final String customerId;

  const PaidAccountDetailScreen({
    super.key,
    required this.store,
    required this.user,
    required this.customerId,
  });

  @override
  State<PaidAccountDetailScreen> createState() =>
      _PaidAccountDetailScreenState();
}

class _PaidAccountDetailScreenState extends State<PaidAccountDetailScreen> {
  bool _approving = false;

  Customer? get _customer => widget.store.getCustomerById(widget.customerId);

  @override
  Widget build(BuildContext context) {
    final customer = _customer;
    if (customer == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Paid Account')),
        body: const EmptyState(
          icon: Icons.person_off_outlined,
          title: 'Account not found',
          message: 'This account may have been archived already.',
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Paid Account Review'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: AccountStatusBadge(status: customer.accountStatus),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSummary(context, customer),
                const SizedBox(height: 16),
                _buildInfo(context, customer),
                const SizedBox(height: 16),
                _buildPaymentHistory(context, customer),
                if (widget.user.isAdmin) ...[
                  const SizedBox(height: 20),
                  _buildApproveAction(context, customer),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummary(BuildContext context, Customer customer) {
    final palette = AppPalette.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [palette.heroStart, palette.heroEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            customer.name,
            style: const TextStyle(
              fontFamily: 'Lora',
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            customer.id,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.82),
              fontSize: 11,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 18,
            runSpacing: 10,
            children: [
              _summaryStat(
                context,
                'TOTAL PAID',
                formatPeso(customer.amountPaid),
              ),
              _summaryStat(
                context,
                'TOTAL DUE',
                formatPeso(customer.totalDue),
              ),
              _summaryStat(
                context,
                'BALANCE',
                formatPeso(customer.remainingBalance),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.verified_outlined,
                size: 16,
                color: Colors.white.withValues(alpha: 0.9),
              ),
              const SizedBox(width: 7),
              Text(
                'Fully paid — verify the details below before approving.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryStat(BuildContext context, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.72),
            fontSize: 9.5,
            letterSpacing: 0.8,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildInfo(BuildContext context, Customer customer) {
    final theme = Theme.of(context);
    final palette = AppPalette.of(context);

    Widget row(String label, String value) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 120,
              child: Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: palette.muted,
                  fontSize: 11.5,
                ),
              ),
            ),
            Expanded(
              child: Text(
                value.isEmpty ? '—' : value,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Account details',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            row('Address', customer.address),
            row('Contact', customer.contactNumber),
            row('Package', customer.package),
            row(
              'Package cost',
              formatPeso(customer.totalPackageCost),
            ),
            if (customer.approvedDiscount > 0)
              row(
                'Discount',
                '-formatPeso(customer.approvedDiscount)',
              ),
            row(
              'Due date',
              _formatDate(customer.dueDate),
            ),
            if (customer.remarks.isNotEmpty) row('Remarks', customer.remarks),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentHistory(BuildContext context, Customer customer) {
    final theme = Theme.of(context);
    final palette = AppPalette.of(context);

    return Card(
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
            const SizedBox(height: 12),
            StreamBuilder<List<PaymentEntry>>(
              stream: widget.store.watchPayments(customer.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  );
                }
                final payments = snapshot.data ?? const <PaymentEntry>[];
                if (payments.isEmpty) {
                  return Text(
                    'No payment records found for this account.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: palette.muted,
                    ),
                  );
                }
                return Column(
                  children: [
                    for (final payment in payments)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: palette.success.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: Icon(
                                Icons.payments_rounded,
                                size: 15,
                                color: palette.success,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    formatPeso(payment.amount),
                                    style: theme.textTheme.bodyMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13,
                                        ),
                                  ),
                                  const SizedBox(height: 1),
                                  Text(
                                    [
                                      if (payment.recordedAt != null)
                                        _formatDateTime(payment.recordedAt!),
                                      if (payment.note.isNotEmpty) payment.note,
                                      if (payment.recordedByEmail.isNotEmpty)
                                        'by ${payment.recordedByEmail}',
                                    ].join(' · '),
                                    style: theme.textTheme.labelSmall
                                        ?.copyWith(
                                          color: palette.muted,
                                          fontSize: 10.5,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Balance after',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: palette.muted,
                                    fontSize: 9.5,
                                  ),
                                ),
                                Text(
                                  formatPeso(payment.balanceAfter),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApproveAction(BuildContext context, Customer customer) {
    return SizedBox(
      height: 50,
      child: ElevatedButton.icon(
        onPressed: _approving ? null : () => _approve(customer),
        icon: _approving
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.archive_rounded, size: 19),
        label: Text(
          _approving ? 'Archiving...' : 'Approve & move to Completed / Archive',
        ),
      ),
    );
  }

  Future<void> _approve(Customer customer) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.archive_rounded, size: 26),
        title: const Text('Approve & archive'),
        content: Text(
          'Confirm that ${customer.name} (${customer.id}) is fully paid? '
          'The account will be moved to Completed / Archive.',
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

    setState(() => _approving = true);
    try {
      await widget.store.markAsCompleted(customer);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${customer.name} approved and moved to Completed / Archive.',
          ),
        ),
      );
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/paid');
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) setState(() => _approving = false);
    }
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

  String _formatDateTime(DateTime date) {
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '${_formatDate(date)} · $hour:$minute $period';
  }
}
