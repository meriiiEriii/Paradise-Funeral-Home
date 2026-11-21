import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/customer.dart';
import '../data/customer_store.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state.dart';
import '../widgets/status_badge.dart';

class CompletedArchiveScreen extends StatefulWidget {
  final CustomerStore store;
  final bool canEdit;

  const CompletedArchiveScreen({
    super.key,
    required this.store,
    this.canEdit = false,
  });

  @override
  State<CompletedArchiveScreen> createState() => _CompletedArchiveScreenState();
}

class _CompletedArchiveScreenState extends State<CompletedArchiveScreen> {
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
    final completed = widget.store.completedCustomers;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1120),
              child: _buildBanner(completed.length),
            ),
          ),
        ),
        Expanded(
          child: completed.isEmpty
              ? const EmptyState(
                  icon: Icons.inventory_2_outlined,
                  title: 'No archived records',
                  message:
                      'Accounts are archived automatically once their balance reaches zero. Completed clients will appear here.',
                )
              : _buildList(completed),
        ),
      ],
    );
  }

  Widget _buildBanner(int count) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF14532D), Color(0xFF1E8E5A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 520;
          final heading = Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.18),
                  ),
                ),
                child: const Icon(
                  Icons.inventory_2_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$count archived record${count != 1 ? 's' : ''}',
                      style: const TextStyle(
                        fontFamily: 'Bitter',
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Completed or fully paid accounts, kept for reference and history.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.82),
                        fontSize: 11.5,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );

          if (compact) return heading;

          return Row(
            children: [
              Expanded(child: heading),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Settled',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontSize: 10,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildList(List<Customer> completed) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final twoColumns = constraints.maxWidth >= 980;
              final width = twoColumns
                  ? (constraints.maxWidth - 16) / 2
                  : constraints.maxWidth;
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  for (final customer in completed)
                    SizedBox(
                      width: width,
                      child: _buildCompletedCard(customer),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCompletedCard(Customer customer) {
    final theme = Theme.of(context);
    final palette = AppPalette.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: palette.successSoft,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: palette.success.withValues(alpha: 0.18),
                    ),
                  ),
                  child: Icon(
                    Icons.person_rounded,
                    color: palette.success,
                    size: 21,
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
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        customer.id,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: palette.muted,
                          fontSize: 10.5,
                          letterSpacing: 0.6,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                StatusBadge(status: customer.paymentStatus),
              ],
            ),
            const SizedBox(height: 14),
            Divider(height: 1, color: palette.border),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _detail('Contact', customer.contactNumber),
                      const SizedBox(height: 6),
                      _detail('Package', customer.package),
                      const SizedBox(height: 6),
                      _detail(
                        'Date completed',
                        _formatDate(
                          customer.lastPaymentDate ?? customer.dueDate,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _detail(
                        'Total due',
                        '₱${customer.totalDue.toStringAsFixed(2)}',
                        alignEnd: true,
                      ),
                      const SizedBox(height: 6),
                      _detail(
                        'Amount paid',
                        '₱${customer.amountPaid.toStringAsFixed(2)}',
                        color: palette.success,
                        bold: true,
                        alignEnd: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (customer.remarks.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: palette.surfaceAlt,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: palette.border),
                ),
                child: Text(
                  customer.remarks,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: palette.muted,
                    fontSize: 11.5,
                    fontStyle: FontStyle.italic,
                    height: 1.4,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (context, constraints) {
                final viewDetails = OutlinedButton.icon(
                  onPressed: () => context.push('/customer/${customer.id}'),
                  icon: const Icon(Icons.open_in_new_rounded, size: 16),
                  label: const Text('View Details'),
                );
                final restore = widget.canEdit
                    ? OutlinedButton.icon(
                        onPressed: () async {
                          try {
                            await widget.store.restoreToActive(customer);
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '${customer.name} restored to active accounts',
                                ),
                                backgroundColor: const Color(0xFF1565C0),
                              ),
                            );
                          } catch (error) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(error.toString())),
                            );
                          }
                        },
                        icon: const Icon(Icons.restore_rounded, size: 16),
                        label: const Text('Restore'),
                      )
                    : null;

                if (restore == null) {
                  return SizedBox(width: double.infinity, child: viewDetails);
                }
                if (constraints.maxWidth < 340) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [viewDetails, const SizedBox(height: 8), restore],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: viewDetails),
                    const SizedBox(width: 8),
                    Expanded(child: restore),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _detail(
    String label,
    String value, {
    Color? color,
    bool bold = false,
    bool alignEnd = false,
  }) {
    final theme = Theme.of(context);
    final palette = AppPalette.of(context);

    return Column(
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            color: palette.muted,
            fontSize: 9.5,
            letterSpacing: 0.7,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 12,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            color: color ?? theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
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
