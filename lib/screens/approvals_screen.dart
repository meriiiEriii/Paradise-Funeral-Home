import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/customer_store.dart';
import '../models/discount_request.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state.dart';
import '../widgets/page_header.dart';

class ApprovalsScreen extends StatefulWidget {
  final CustomerStore store;

  const ApprovalsScreen({super.key, required this.store});

  @override
  State<ApprovalsScreen> createState() => _ApprovalsScreenState();
}

class _ApprovalsScreenState extends State<ApprovalsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    widget.store.addListener(_onStoreChanged);
  }

  void _onStoreChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.store.removeListener(_onStoreChanged);
    _tabs.dispose();
    super.dispose();
  }

  List<DiscountRequest> get _history {
    final reviewed = widget.store.discountRequests
        .where((request) => !request.isPending)
        .toList();
    reviewed.sort(
      (a, b) => (b.reviewedAt ?? b.requestedAt).compareTo(
        a.reviewedAt ?? a.requestedAt,
      ),
    );
    return reviewed;
  }

  Future<void> _approve(DiscountRequest request) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.verified_outlined, size: 26),
        title: const Text('Approve discount'),
        content: Text(
          'Apply a ₱${request.amount.toStringAsFixed(2)} discount to '
          '${request.customerName} (${request.customerId})?',
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
    await _run(() => widget.store.approveDiscountRequest(request.id));
  }

  Future<void> _reject(DiscountRequest request) async {
    final controller = TextEditingController();
    final note = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.cancel_outlined, size: 26),
        title: const Text('Reject discount'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reject the ₱${request.amount.toStringAsFixed(2)} request for '
              '${request.customerName}?',
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              minLines: 2,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
                hintText: 'Tell the staff why it was rejected',
                alignLabelWithHint: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    if (note == null) return;
    await _run(
      () => widget.store.rejectDiscountRequest(request.id, note: note),
    );
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Discount request updated.')),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppPalette.of(context);
    final requests = widget.store.pendingDiscountRequests;
    final history = _history;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 960),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const PageHeader(
                    icon: Icons.approval_outlined,
                    title: 'Discount Approvals',
                    subtitle:
                        'Review discount requests from staff before they are applied to an account.',
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: palette.surfaceAlt,
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(color: palette.border),
                    ),
                    child: TabBar(
                      controller: _tabs,
                      indicatorSize: TabBarIndicatorSize.tab,
                      indicator: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      labelColor: theme.colorScheme.onPrimary,
                      unselectedLabelColor: theme.colorScheme.onSurface
                          .withValues(alpha: 0.75),
                      dividerColor: Colors.transparent,
                      tabs: [
                        Tab(text: 'Requests (${requests.length})'),
                        Tab(text: 'Discount History (${history.length})'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: [
              _buildRequests(requests),
              _buildHistory(history),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRequests(List<DiscountRequest> requests) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 960),
        child: requests.isEmpty
            ? ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Card(
                    child: EmptyState(
                      icon: Icons.task_alt_rounded,
                      title: 'No pending requests',
                      message:
                          'When staff request a discount, it will appear here for your review.',
                      action: TextButton.icon(
                        onPressed: () => context.go('/dashboard'),
                        icon: const Icon(Icons.arrow_back_rounded, size: 18),
                        label: const Text('Back to dashboard'),
                      ),
                    ),
                  ),
                ],
              )
            : ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: requests.length,
                separatorBuilder: (context, index) => const SizedBox(height: 14),
                itemBuilder: (context, index) =>
                    _buildRequestCard(requests[index]),
              ),
      ),
    );
  }

  Widget _buildHistory(List<DiscountRequest> history) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 960),
        child: history.isEmpty
            ? ListView(
                padding: const EdgeInsets.all(20),
                children: const [
                  Card(
                    child: EmptyState(
                      icon: Icons.history_rounded,
                      title: 'No reviewed requests yet',
                      message:
                          'Approved and rejected discount requests will be kept here with their details.',
                    ),
                  ),
                ],
              )
            : ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: history.length,
                separatorBuilder: (context, index) => const SizedBox(height: 14),
                itemBuilder: (context, index) => _buildHistoryCard(history[index]),
              ),
      ),
    );
  }

  Widget _buildRequestCard(DiscountRequest request) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
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
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.09),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.percent_rounded,
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
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: palette.warning.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(
                      color: palette.warning.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Text(
                    '₱${request.amount.toStringAsFixed(2)}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: palette.warning,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: palette.surfaceAlt,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: palette.border),
              ),
              child: Text(
                request.reason,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 12.5,
                  height: 1.45,
                ),
              ),
            ),
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
                  onPressed: _busy ? null : () => _reject(request),
                  icon: const Icon(Icons.close_rounded, size: 17),
                  label: const Text('Reject'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: palette.danger,
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: _busy ? null : () => _approve(request),
                  icon: const Icon(Icons.check_rounded, size: 17),
                  label: const Text('Approve'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard(DiscountRequest request) {
    final theme = Theme.of(context);
    final palette = AppPalette.of(context);
    final approved = request.status == DiscountRequestStatus.approved;
    final statusColor = approved ? palette.success : palette.danger;

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
                    color: statusColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    approved
                        ? Icons.verified_outlined
                        : Icons.cancel_outlined,
                    size: 20,
                    color: statusColor,
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
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Text(
                    request.status.label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _historyRow(context, 'Amount', '₱${request.amount.toStringAsFixed(2)}'),
            _historyRow(context, 'Reason', request.reason),
            _historyRow(
              context,
              'Date requested',
              _formatDateTime(request.requestedAt),
            ),
            if (request.reviewedAt != null)
              _historyRow(
                context,
                approved ? 'Date approved' : 'Date rejected',
                _formatDateTime(request.reviewedAt!),
              ),
            if (request.requestedByEmail.isNotEmpty)
              _historyRow(
                context,
                'Requested by',
                request.requestedByEmail,
              ),
            if (request.reviewedByEmail != null &&
                request.reviewedByEmail!.isNotEmpty)
              _historyRow(
                context,
                'Reviewed by',
                request.reviewedByEmail!,
              ),
            if (request.reviewNote.isNotEmpty)
              _historyRow(context, 'Note', request.reviewNote),
          ],
        ),
      ),
    );
  }

  Widget _historyRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    final palette = AppPalette.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 118,
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

  String _formatDateTime(DateTime date) {
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
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '${months[date.month - 1]} ${date.day}, $hour:$minute $period';
  }
}
