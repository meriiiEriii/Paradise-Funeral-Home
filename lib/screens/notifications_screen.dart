import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../auth/app_user.dart';
import '../data/customer_store.dart';
import '../models/app_notification.dart';
import '../models/discount_request.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state.dart';

class NotificationsScreen extends StatefulWidget {
  final CustomerStore store;
  final AppUser user;

  const NotificationsScreen({
    super.key,
    required this.store,
    required this.user,
  });

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
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

  List<AppNotification> get _visible =>
      widget.store.notificationsFor(widget.user);

  DiscountRequest? _requestFor(AppNotification notification) {
    final id = notification.requestId;
    if (id == null || id.isEmpty) return null;
    for (final request in widget.store.discountRequests) {
      if (request.id == id) return request;
    }
    return null;
  }

  Future<void> _setRead(AppNotification notification, bool read) async {
    final isRead = notification.isReadBy(widget.user);
    if (read && !isRead) {
      await widget.store.markNotificationRead(
        notification.id,
        widget.user.uid,
      );
    } else if (!read && isRead) {
      await widget.store.markNotificationUnread(
        notification.id,
        widget.user.uid,
      );
    }
  }

  Future<void> _markAllRead() async {
    for (final notification in _visible) {
      if (!notification.isReadBy(widget.user)) {
        await widget.store.markNotificationRead(
          notification.id,
          widget.user.uid,
        );
      }
    }
  }

  Future<void> _run(Future<void> Function() action, String success) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(success)),
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

  Future<void> _approveStaff(AppNotification notification) async {
    final staffUid = notification.staffUid;
    if (staffUid == null || staffUid.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.verified_outlined, size: 26),
        title: const Text('Approve staff account'),
        content: const Text(
          'Allow this staff account to sign in to the system?',
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
    await _run(
      () => widget.store.approveStaff(staffUid),
      'Staff account approved.',
    );
  }

  Future<void> _rejectStaff(AppNotification notification) async {
    final staffUid = notification.staffUid;
    if (staffUid == null || staffUid.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.cancel_outlined, size: 26),
        title: const Text('Reject staff account'),
        content: const Text(
          'Reject this staff registration? They will not be able to sign in.',
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
    await _run(
      () => widget.store.rejectStaff(staffUid),
      'Staff registration rejected.',
    );
  }

  Future<void> _approveDiscount(DiscountRequest request) async {
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
    await _run(
      () => widget.store.approveDiscountRequest(request.id),
      'Discount request approved.',
    );
  }

  Future<void> _rejectDiscount(DiscountRequest request) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.cancel_outlined, size: 26),
        title: const Text('Reject discount'),
        content: Text(
          'Reject the ₱${request.amount.toStringAsFixed(2)} request for '
          '${request.customerName}?',
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
    await _run(
      () => widget.store.rejectDiscountRequest(request.id),
      'Discount request rejected.',
    );
  }

  Future<void> _open(AppNotification notification) async {
    if (!notification.isReadBy(widget.user)) {
      await widget.store.markNotificationRead(
        notification.id,
        widget.user.uid,
      );
    }
    if (!mounted) return;
    if (notification.type == AppNotificationType.staffRegistered) {
      context.push('/staff-requests');
      return;
    }
    if (widget.store.getCustomerById(notification.customerId) != null) {
      context.push('/customer/${notification.customerId}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final unreadList = _visible
        .where((notification) => !notification.isReadBy(widget.user))
        .toList();
    final readList = _visible
        .where((notification) => notification.isReadBy(widget.user))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (unreadList.isNotEmpty)
            TextButton.icon(
              onPressed: _markAllRead,
              icon: const Icon(Icons.done_all_rounded, size: 18),
              label: const Text('Mark all read'),
            ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabs,
          tabs: [
            Tab(text: 'Unread (${unreadList.length})'),
            Tab(text: 'Read (${readList.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _buildList(
            unreadList,
            icon: Icons.notifications_none_rounded,
            title: 'You are all caught up',
            message:
                'New discount requests, staff registrations, and account '
                'updates will appear here.',
          ),
          _buildList(
            readList,
            icon: Icons.done_all_rounded,
            title: 'No read notifications',
            message: 'Notifications you have read will be kept here.',
          ),
        ],
      ),
    );
  }

  Widget _buildList(
    List<AppNotification> notifications, {
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 860),
        child: notifications.isEmpty
            ? Padding(
                padding: const EdgeInsets.all(20),
                child: Card(
                  child: EmptyState(
                    icon: icon,
                    title: title,
                    message: message,
                  ),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                itemCount: notifications.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final notification = notifications[index];
                  return _buildTile(notification);
                },
              ),
      ),
    );
  }

  Widget _buildTile(AppNotification notification) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final palette = AppPalette.of(context);
    final unread = !notification.isReadBy(widget.user);
    final config = _iconConfig(notification.type, palette);
    final request = _requestFor(notification);
    final showStaffActions = widget.user.isAdmin &&
        notification.type == AppNotificationType.staffRegistered &&
        (notification.staffUid?.isNotEmpty ?? false);
    final showDiscountDetails =
        widget.user.isAdmin &&
        notification.type == AppNotificationType.discountRequested &&
        request != null;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _open(notification),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: config.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(config.icon, size: 19, color: config.color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                notification.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: unread
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: scheme.onSurface,
                                ),
                              ),
                            ),
                            if (unread)
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: scheme.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          notification.message,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: palette.muted,
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _formatDateTime(notification.createdAt),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: palette.muted,
                            fontSize: 10.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  PopupMenuButton<String>(
                    tooltip: 'Notification options',
                    padding: EdgeInsets.zero,
                    icon: Icon(
                      Icons.more_vert_rounded,
                      size: 18,
                      color: palette.muted,
                    ),
                    onSelected: (value) {
                      if (value == 'toggle') {
                        _setRead(notification, unread);
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'toggle',
                        child: Row(
                          children: [
                            Icon(
                              unread
                                  ? Icons.done_rounded
                                  : Icons.mark_email_unread_rounded,
                              size: 17,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              unread ? 'Mark as read' : 'Mark as unread',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (showDiscountDetails) ...[
                const SizedBox(height: 12),
                _buildDiscountDetails(request),
              ],
              if (showStaffActions) ...[
                const SizedBox(height: 12),
                _buildStaffActions(notification),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDiscountDetails(DiscountRequest request) {
    final theme = Theme.of(context);
    final palette = AppPalette.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.surfaceAlt,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Discount requested: ₱${request.amount.toStringAsFixed(2)}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: palette.warning,
                  ),
                ),
              ),
              if (!request.isPending)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: request.status == DiscountRequestStatus.approved
                        ? palette.success.withValues(alpha: 0.12)
                        : palette.danger.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(
                      color:
                          request.status == DiscountRequestStatus.approved
                          ? palette.success.withValues(alpha: 0.3)
                          : palette.danger.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    request.status.label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: request.status == DiscountRequestStatus.approved
                          ? palette.success
                          : palette.danger,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Reason: ${request.reason}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: palette.muted,
              fontSize: 12,
              height: 1.4,
            ),
          ),
          if (request.isPending) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: _busy ? null : () => _rejectDiscount(request),
                  icon: const Icon(Icons.close_rounded, size: 17),
                  label: const Text('Reject'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: palette.danger,
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: _busy ? null : () => _approveDiscount(request),
                  icon: const Icon(Icons.check_rounded, size: 17),
                  label: const Text('Approve'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStaffActions(AppNotification notification) {
    final theme = Theme.of(context);
    final palette = AppPalette.of(context);

    return Row(
      children: [
        Expanded(
          child: Text(
            'Awaiting your approval',
            style: theme.textTheme.labelSmall?.copyWith(
              color: palette.muted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        OutlinedButton.icon(
          onPressed: _busy ? null : () => _rejectStaff(notification),
          icon: const Icon(Icons.close_rounded, size: 17),
          label: const Text('Reject'),
          style: OutlinedButton.styleFrom(foregroundColor: palette.danger),
        ),
        const SizedBox(width: 10),
        ElevatedButton.icon(
          onPressed: _busy ? null : () => _approveStaff(notification),
          icon: const Icon(Icons.check_rounded, size: 17),
          label: const Text('Approve'),
        ),
      ],
    );
  }

  _NotificationIcon _iconConfig(
    AppNotificationType type,
    AppPalette palette,
  ) {
    switch (type) {
      case AppNotificationType.discountRequested:
        return _NotificationIcon(Icons.percent_rounded, palette.warning);
      case AppNotificationType.discountApproved:
        return _NotificationIcon(Icons.verified_outlined, palette.success);
      case AppNotificationType.discountRejected:
        return _NotificationIcon(Icons.cancel_outlined, palette.danger);
      case AppNotificationType.paymentCompleted:
        return _NotificationIcon(Icons.task_alt_rounded, palette.success);
      case AppNotificationType.staffRegistered:
        return _NotificationIcon(Icons.person_add_alt_1_rounded, palette.warning);
    }
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

class _NotificationIcon {
  final IconData icon;
  final Color color;

  _NotificationIcon(this.icon, this.color);
}
