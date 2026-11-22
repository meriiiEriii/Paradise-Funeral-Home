import '../utils/formatters.dart';
import 'package:flutter/material.dart';

import '../models/customer.dart';
import '../theme/app_theme.dart';
import 'status_badge.dart';

/// The dashboard-style customer table: sortable columns, zebra rows, hover
/// highlight, and row tap-to-open. Shared by the Dashboard and the
/// All Customers page.
class CustomerTable extends StatelessWidget {
  final List<Customer> customers;
  final int? sortColumnIndex;
  final bool sortAscending;
  final DataColumnSortCallback onSort;
  final ValueChanged<Customer> onRowTap;

  const CustomerTable({
    super.key,
    required this.customers,
    required this.sortColumnIndex,
    required this.sortAscending,
    required this.onSort,
    required this.onRowTap,
  });

  @override
  Widget build(BuildContext context) {
    return DataTable(
      columnSpacing: 14,
      horizontalMargin: 12,
      sortColumnIndex: sortColumnIndex,
      sortAscending: sortAscending,
      showCheckboxColumn: false,
      columns: [
        DataColumn(label: const Text('DATE ADDED'), onSort: onSort),
        const DataColumn(label: Text('CUSTOMER')),
        const DataColumn(label: Text('ADDRESS')),
        const DataColumn(label: Text('CONTACT')),
        const DataColumn(label: Text('PACKAGE')),
        DataColumn(label: const Text('COST'), numeric: true, onSort: onSort),
        DataColumn(label: const Text('PAID'), numeric: true, onSort: onSort),
        DataColumn(
          label: const Text('BALANCE'),
          numeric: true,
          onSort: onSort,
        ),
        DataColumn(label: const Text('STATUS'), onSort: onSort),
        const DataColumn(label: Text('REMARKS')),
        DataColumn(label: const Text('DUE DATE'), onSort: onSort),
        const DataColumn(label: Text('DAYS LEFT')),
      ],
      rows: [
        for (var index = 0; index < customers.length; index++)
          _buildRow(context, customers[index], index),
      ],
    );
  }

  DataRow _buildRow(BuildContext context, Customer c, int index) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final palette = AppPalette.of(context);
    final zebra = palette.surfaceAlt.withValues(alpha: 0.42);

    return DataRow(
      color: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.hovered)) {
          return scheme.primary.withValues(alpha: 0.055);
        }
        return index.isEven ? null : zebra;
      }),
      onSelectChanged: (_) => onRowTap(c),
      cells: [
        DataCell(Text(
          _formatDate(c.dateAdded),
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 12,
            color: palette.muted,
          ),
        )),
        DataCell(
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                c.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 12.5,
                ),
              ),
              Text(
                c.id,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: palette.muted,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
        DataCell(_constrainedText(context, c.address)),
        DataCell(Text(
          c.contactNumber,
          style: theme.textTheme.bodySmall?.copyWith(fontSize: 12),
        )),
        DataCell(_constrainedText(context, c.package)),
        DataCell(Text(
          formatPeso(c.totalPackageCost),
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        )),
        DataCell(Text(
          formatPeso(c.amountPaid),
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: palette.success,
          ),
        )),
        DataCell(Text(
          formatPeso(c.remainingBalance),
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: c.remainingBalance > 0 ? palette.danger : palette.success,
          ),
        )),
        DataCell(StatusBadge(status: c.paymentStatus)),
        DataCell(_constrainedText(context, c.remarks, fallback: '—')),
        DataCell(Text(
          _formatDate(c.dueDate),
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 12,
            color: palette.muted,
          ),
        )),
        DataCell(_daysBadge(context, c)),
      ],
    );
  }

  Widget _constrainedText(
    BuildContext context,
    String value, {
    String fallback = '',
  }) {
    final theme = Theme.of(context);
    final palette = AppPalette.of(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 150),
      child: Text(
        value.isEmpty ? fallback : value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodySmall?.copyWith(
          fontSize: 12,
          color: palette.muted,
        ),
      ),
    );
  }

  Widget _daysBadge(BuildContext context, Customer c) {
    final theme = Theme.of(context);
    final palette = AppPalette.of(context);
    final days = c.daysRemaining;
    final overdue = days < 0 && c.remainingBalance > 0;
    final color = c.remainingBalance <= 0
        ? palette.success
        : overdue
        ? palette.danger
        : palette.muted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        days >= 0 ? '${days}d left' : '${days.abs()}d late',
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 10.5,
        ),
      ),
    );
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
