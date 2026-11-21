import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/customer_store.dart';
import '../models/customer.dart';
import '../models/discount_request.dart';
import '../theme/app_theme.dart';
import '../widgets/customer_qr_dialog.dart';
import '../widgets/empty_state.dart';
import '../widgets/section_card.dart';
import '../widgets/status_badge.dart';
import 'discount_request_dialog.dart';

class CustomerProfileScreen extends StatefulWidget {
  final CustomerStore store;
  final String customerId;
  final bool canRecordPayment;
  final bool canRequestDiscount;
  final bool canShareQr;

  const CustomerProfileScreen({
    super.key,
    required this.store,
    required this.customerId,
    this.canRecordPayment = false,
    this.canRequestDiscount = false,
    this.canShareQr = false,
  });

  @override
  State<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends State<CustomerProfileScreen> {
  Customer get customer => widget.store.getCustomerById(widget.customerId)!;

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
    final current = widget.store.getCustomerById(widget.customerId);
    if (current == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Customer Profile')),
        body: const EmptyState(
          icon: Icons.person_off_outlined,
          title: 'Customer not found',
          message: 'This account may have been removed from the registry.',
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Profile'),
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
            constraints: const BoxConstraints(maxWidth: 1180),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHero(context),
                const SizedBox(height: 18),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 940;
                    final left = Column(
                      children: [
                        _buildInfoCard(context),
                        const SizedBox(height: 16),
                        _buildItemsCard(context),
                      ],
                    );
                    final right = Column(
                      children: [
                        _buildPaymentCard(context),
                        const SizedBox(height: 16),
                        _buildRemarksCard(context),
                        if (customer.remarks.isNotEmpty)
                          const SizedBox(height: 16),
                        _buildActions(context),
                      ],
                    );
                    if (!wide) {
                      return Column(
                        children: [left, const SizedBox(height: 16), right],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 6, child: left),
                        const SizedBox(width: 18),
                        Expanded(flex: 5, child: right),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHero(BuildContext context) {
    final palette = AppPalette.of(context);

    return Container(
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
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                ),
                child: Center(
                  child: Text(
                    _initials(customer.name),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Bitter',
                        color: Colors.white,
                        fontSize: 23,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      customer.id,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.82),
                        fontSize: 11,
                        letterSpacing: 1.1,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              StatusBadge(status: customer.paymentStatus, onGradient: true),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _heroStat(
                Icons.inventory_2_outlined,
                'PACKAGE',
                customer.package,
              ),
              _heroStat(
                Icons.event_outlined,
                'DUE DATE',
                _formatDate(customer.dueDate),
              ),
              _heroStat(
                Icons.account_balance_wallet_outlined,
                'BALANCE',
                '₱${customer.remainingBalance.toStringAsFixed(2)}',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroStat(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white.withValues(alpha: 0.85)),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.75),
                  fontSize: 9.5,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    final rows = [
      _infoRow(
        context,
        Icons.location_on_outlined,
        'Address',
        customer.address,
      ),
      _infoRow(
        context,
        Icons.phone_outlined,
        'Contact',
        customer.contactNumber,
      ),
      _infoRow(
        context,
        Icons.calendar_today_outlined,
        'Date added',
        _formatDate(customer.dateAdded),
      ),
      _infoRow(
        context,
        Icons.inventory_2_outlined,
        'Package',
        '${customer.package} (${customer.items.length} item${customer.items.length != 1 ? 's' : ''})',
      ),
      _infoRow(
        context,
        Icons.date_range_outlined,
        'Due date',
        _formatDate(customer.dueDate),
      ),
      _infoRow(
        context,
        Icons.timer_outlined,
        'Days remaining',
        customer.daysRemaining >= 0
            ? '${customer.daysRemaining} days left'
            : '${customer.daysRemaining.abs()} days overdue',
      ),
    ];

    return SectionCard(
      title: 'Customer Information',
      icon: Icons.info_outline_rounded,
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 520) {
            return Column(children: rows);
          }
          final width = (constraints.maxWidth - 16) / 2;
          return Wrap(
            spacing: 16,
            runSpacing: 0,
            children: [
              for (final row in rows) SizedBox(width: width, child: row),
            ],
          );
        },
      ),
    );
  }

  Widget _buildItemsCard(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final palette = AppPalette.of(context);

    return SectionCard(
      title: 'Package Items',
      icon: Icons.inventory_2_outlined,
      trailing: Text(
        '${customer.items.length} item${customer.items.length != 1 ? 's' : ''}',
        style: theme.textTheme.labelSmall?.copyWith(
          color: palette.muted,
          fontSize: 10.5,
        ),
      ),
      child: customer.items.isEmpty
          ? Text(
              'No item breakdown recorded for this package.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: palette.muted,
                fontSize: 12,
              ),
            )
          : Column(
              children: [
                ...customer.items.map((item) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: scheme.primary.withValues(alpha: 0.6),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            item.name,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontSize: 13,
                              color: scheme.onSurface.withValues(alpha: 0.85),
                            ),
                          ),
                        ),
                        Text(
                          '₱${item.amount.toStringAsFixed(2)}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                Divider(height: 18, color: palette.border),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Total package cost',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: palette.muted,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        '₱${customer.totalPackageCost.toStringAsFixed(2)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontFamily: 'Bitter',
                          fontWeight: FontWeight.w700,
                          color: scheme.primary,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _buildPaymentCard(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final palette = AppPalette.of(context);

    final total = customer.totalDue;
    final progress = total <= 0
        ? 1.0
        : (customer.amountPaid / total).clamp(0.0, 1.0);
    final fullyPaid = customer.remainingBalance <= 0;

    return SectionCard(
      title: 'Payment Summary',
      icon: Icons.payments_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Payment progress',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: palette.muted,
                  fontSize: 11.5,
                ),
              ),
              const Spacer(),
              Text(
                '${(progress * 100).toStringAsFixed(0)}%',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: fullyPaid ? palette.success : scheme.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: palette.surfaceAlt,
              color: fullyPaid ? palette.success : scheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          _financeRow(
            context,
            'Total package cost',
            customer.totalPackageCost,
            scheme.onSurface,
          ),
          if (customer.approvedDiscount > 0)
            _financeRow(
              context,
              'Approved discount',
              customer.approvedDiscount,
              palette.success,
              prefix: '-',
            ),
          _financeRow(
            context,
            'Total due',
            customer.totalDue,
            scheme.onSurface,
          ),
          _financeRow(
            context,
            'Amount paid',
            customer.amountPaid,
            palette.success,
          ),
          Divider(height: 16, color: palette.border),
          _financeRow(
            context,
            'Remaining balance',
            customer.remainingBalance,
            fullyPaid ? palette.success : palette.danger,
            bold: true,
          ),
          if (customer.lastPaymentDate != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.history_rounded, size: 14, color: palette.muted),
                const SizedBox(width: 7),
                Text(
                  'Last payment: ${_formatDate(customer.lastPaymentDate!)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: palette.muted,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ],
          if (customer.hasPendingDiscountRequest) ...[
            const SizedBox(height: 12),
            _buildPendingDiscountBanner(context),
          ],
        ],
      ),
    );
  }

  Widget _buildPendingDiscountBanner(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppPalette.of(context);

    DiscountRequest? pending;
    for (final request in widget.store.discountRequests) {
      if (request.id == customer.pendingDiscountRequestId) {
        pending = request;
        break;
      }
    }

    final details = pending == null
        ? 'A discount request is awaiting admin approval.'
        : 'Discount request: ₱${pending.amount.toStringAsFixed(2)} — '
            '"${pending.reason}". Awaiting admin approval.';

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: palette.warning.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: palette.warning.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Icon(Icons.hourglass_top_rounded, size: 15, color: palette.warning),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              details,
              style: theme.textTheme.bodySmall?.copyWith(
                color: palette.warning,
                fontSize: 11.5,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRemarksCard(BuildContext context) {
    if (customer.remarks.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return SectionCard(
      title: 'Remarks',
      icon: Icons.notes_outlined,
      child: Text(
        customer.remarks,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.78),
          fontSize: 13,
          height: 1.6,
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    final paymentButton = widget.canRecordPayment
        ? ElevatedButton.icon(
            onPressed: () => context.push('/customer/${customer.id}/payment'),
            icon: const Icon(Icons.payments_rounded, size: 19),
            label: const Text('Record Payment'),
          )
        : null;
    final canRequest =
        widget.canRequestDiscount &&
        !customer.hasPendingDiscountRequest &&
        customer.remainingBalance > 0;
    final discountButton = canRequest
        ? OutlinedButton.icon(
            onPressed: () => _requestDiscount(context),
            icon: const Icon(Icons.percent_rounded, size: 18),
            label: const Text('Request Discount'),
          )
        : null;
    final pendingNotice =
        widget.canRequestDiscount && customer.hasPendingDiscountRequest
        ? OutlinedButton.icon(
            onPressed: null,
            icon: const Icon(Icons.hourglass_top_rounded, size: 18),
            label: const Text('Discount pending'),
          )
        : null;
    final qrButton = widget.canShareQr
        ? OutlinedButton.icon(
            onPressed: () => showCustomerQrDialog(
              context,
              customer: customer,
              store: widget.store,
            ),
            icon: const Icon(Icons.qr_code_2_rounded, size: 18),
            label: const Text('Customer QR'),
          )
        : null;

    final primary = [?paymentButton, ?discountButton, ?pendingNotice, ?qrButton];

    if (primary.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 520) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final button in primary) ...[
                button,
                const SizedBox(height: 10),
              ],
            ],
          );
        }
        return Row(
          children: [
            for (final button in primary) ...[
              Expanded(flex: 3, child: button),
              const SizedBox(width: 10),
            ],
          ],
        );
      },
    );
  }

  Future<void> _requestDiscount(BuildContext context) async {
    final submitted = await showDiscountRequestDialog(
      context,
      customer: customer,
      store: widget.store,
    );
    if (!submitted || !context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Discount request sent for admin approval.'),
      ),
    );
  }

  Widget _infoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    final theme = Theme.of(context);
    final palette = AppPalette.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: palette.muted),
          const SizedBox(width: 9),
          SizedBox(
            width: 98,
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
              value,
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

  Widget _financeRow(
    BuildContext context,
    String label,
    double amount,
    Color color, {
    bool bold = false,
    String prefix = '',
  }) {
    final theme = Theme.of(context);
    final palette = AppPalette.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: palette.muted,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              '$prefix₱${amount.toStringAsFixed(2)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
                fontSize: bold ? 15 : 13,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  String _formatDate(DateTime date) {
    final months = [
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
