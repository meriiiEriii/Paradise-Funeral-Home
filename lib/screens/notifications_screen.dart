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

class _NotificationsScreenState extends State<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  String? _expandedId;

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

  Future<void> _setRead(AppNotification notification, bool read) async {
    final isRead = notification.isReadBy(widget.user);
    try {
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
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update the notification: $error')),
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

  void _markReadQuietly(AppNotification notification) {
    if (!notification.isReadBy(widget.user)) {
      widget.store
          .markNotificationRead(notification.id, widget.user.uid)
          .catchError((_) {});
    }
  }

  /// Navigates to [location] unless a page for it is already on the
  /// navigation stack.
  ///
  /// go_router derives every page key from the matched path, so pushing a
  /// route that is already open (for example tapping a staff notification
  /// while the Staff page sits beneath the Notifications screen) crashes with
  /// "keyReservation.contains(key)". In that case the Notifications screen is
  /// simply popped, revealing the page that is already open.
  void _pushUnique(String location) {
    final config = GoRouter.of(context).routerDelegate.currentConfiguration;
    final alreadyOpen = config.matches.any(
      (match) => match.matchedLocation == location,
    );
    if (alreadyOpen) {
      if (context.canPop()) context.pop();
      return;
    }
    context.push(location);
  }

  /// Staff registration notifications go straight to the Staff page.
  void _openStaffRequest(AppNotification notification) {
    _markReadQuietly(notification);
    _pushUnique('/staff-requests');
  }

  /// Discount request notifications go straight to the Discount Approvals
  /// page, where the request can be reviewed and approved or rejected.
  void _openApprovals(AppNotification notification) {
    _markReadQuietly(notification);
    _pushUnique('/approvals');
  }

  /// Expands or collapses a plain notification. Read state is left untouched
  /// so the tile does not jump between the Unread/Read tabs.
  void _toggle(AppNotification notification) {
    final wasExpanded = _expandedId == notification.id;
    setState(() {
      _expandedId = wasExpanded ? null : notification.id;
    });
  }

  void _openLinked(AppNotification notification) {
    _markReadQuietly(notification);
    if (widget.store.getCustomerById(notification.customerId) != null) {
      _pushUnique('/customer/${notification.customerId}');
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
    final isStaffRequest =
        notification.type == AppNotificationType.staffRegistered;
    final isDiscountRequest =
        notification.type == AppNotificationType.discountRequested;
    final expanded =
        !isStaffRequest && !isDiscountRequest && _expandedId == notification.id;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: isStaffRequest
            ? () => _openStaffRequest(notification)
            : isDiscountRequest
            ? () => _openApprovals(notification)
            : () => _toggle(notification),
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
              if (expanded) ...[
                const SizedBox(height: 12),
                _buildExpandedInfo(notification),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => _openLinked(notification),
                    icon: const Icon(Icons.open_in_new_rounded, size: 15),
                    label: const Text('View customer'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedInfo(AppNotification notification) {
    final theme = Theme.of(context);
    final palette = AppPalette.of(context);
    return Text(
      'Tap "View customer" to review the account this notification is about.',
      style: theme.textTheme.bodySmall?.copyWith(
        color: palette.muted,
        fontSize: 11.5,
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
