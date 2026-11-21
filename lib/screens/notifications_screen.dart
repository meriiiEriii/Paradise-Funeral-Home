import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../auth/app_user.dart';
import '../data/customer_store.dart';
import '../models/app_notification.dart';
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

class _NotificationsScreenState extends State<NotificationsScreen> {
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

  Future<void> _markAllRead(List<AppNotification> notifications) async {
    for (final notification in notifications) {
      if (!notification.isReadBy(widget.user)) {
        await widget.store.markNotificationRead(
          notification.id,
          widget.user.uid,
        );
      }
    }
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
    final notifications = widget.store.notificationsFor(widget.user);
    final unread = notifications
        .where((notification) => !notification.isReadBy(widget.user))
        .length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (unread > 0)
            TextButton.icon(
              onPressed: () => _markAllRead(notifications),
              icon: const Icon(Icons.done_all_rounded, size: 18),
              label: const Text('Mark all read'),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: notifications.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(20),
                  child: Card(
                    child: EmptyState(
                      icon: Icons.notifications_none_rounded,
                      title: 'No notifications yet',
                      message:
                          'Discount requests and account updates will appear here.',
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
      ),
    );
  }

  Widget _buildTile(AppNotification notification) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final palette = AppPalette.of(context);
    final unread = !notification.isReadBy(widget.user);
    final config = _iconConfig(notification.type, palette);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _open(notification),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
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
            ],
          ),
        ),
      ),
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
