import 'package:flutter/material.dart';

import '../auth/app_user.dart';
import '../theme/app_theme.dart';

class AppDrawer extends StatelessWidget {
  final AppUser user;
  final String currentRoute;
  final Function(String) onNavigate;
  final ValueChanged<AppRole> onSelectRole;
  final bool isDark;
  final VoidCallback onToggleTheme;

  const AppDrawer({
    super.key,
    required this.user,
    required this.currentRoute,
    required this.onNavigate,
    required this.onSelectRole,
    required this.isDark,
    required this.onToggleTheme,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppPalette.of(context);

    return Drawer(
      width: 306,
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 18, 14, 8),
                children: [
                  _sectionLabel(context, 'Role'),
                  _roleSwitcher(context),
                  const SizedBox(height: 10),
                  _sectionLabel(context, 'Workspace'),
                  _drawerItem(
                    context,
                    Icons.space_dashboard_outlined,
                    'Dashboard',
                    'dashboard',
                  ),
                  _drawerItem(
                    context,
                    Icons.manage_search_rounded,
                    'All Customers',
                    'search',
                  ),
                  _drawerItem(
                    context,
                    Icons.account_balance_wallet_outlined,
                    'Payment',
                    'payment',
                  ),
                  const SizedBox(height: 10),
                  _sectionLabel(context, 'Monitoring'),
                  if (user.isAdmin)
                    _drawerItem(
                      context,
                      Icons.badge_outlined,
                      'Staff',
                      'staff-requests',
                    ),
                  if (user.isAdmin)
                    _drawerItem(
                      context,
                      Icons.approval_outlined,
                      'Discount Approvals',
                      'approvals',
                    ),
                  _drawerItem(
                    context,
                    Icons.warning_amber_rounded,
                    'Delayed Accounts',
                    'delayed',
                  ),
                  _drawerItem(
                    context,
                    Icons.inventory_2_outlined,
                    'Completed / Archive',
                    'completed',
                  ),
                  const SizedBox(height: 10),
                  _sectionLabel(context, 'System'),
                  _drawerItem(
                    context,
                    Icons.settings_outlined,
                    'Settings',
                    'settings',
                  ),
                  _drawerItem(
                    context,
                    Icons.logout_rounded,
                    'Logout',
                    'logout',
                    danger: true,
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: palette.border),
            _buildThemeTile(context, theme),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 18),
              child: Row(
                children: [
                  Icon(Icons.verified_outlined, size: 13, color: palette.muted),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Paradise Funeral Home · v1.0.0',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: palette.muted,
                        fontSize: 10.5,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final palette = AppPalette.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [palette.heroStart, palette.heroEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.18),
                  ),
                ),
                child: const Icon(
                  Icons.local_florist_rounded,
                  color: Colors.white,
                  size: 25,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Paradise Funeral Home',
                      style: TextStyle(
                        fontFamily: 'Bitter',
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                      ),
                    ),
                    Text(
                      'Management System',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10.5,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.white.withValues(alpha: 0.16),
                child: Text(
                  _initial(user.name),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      user.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ),
              _roleBadge(),
            ],
          ),
        ],
      ),
    );
  }

  String _initial(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'U';
    return trimmed[0].toUpperCase();
  }

  Widget _roleBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Text(
        user.role.label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  Widget _sectionLabel(BuildContext context, String label) {
    final theme = Theme.of(context);
    final palette = AppPalette.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
      child: Text(
        label.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: palette.muted,
          fontSize: 10,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _drawerItem(
    BuildContext context,
    IconData icon,
    String title,
    String route, {
    bool danger = false,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final palette = AppPalette.of(context);
    final isSelected = currentRoute == route && !danger;
    final accent = danger ? palette.danger : scheme.primary;
    final foreground = danger
        ? palette.danger
        : isSelected
        ? scheme.primary
        : scheme.onSurface.withValues(alpha: 0.82);

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => onNavigate(route),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              color: isSelected
                  ? scheme.primary.withValues(alpha: 0.09)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? scheme.primary.withValues(alpha: 0.16)
                    : Colors.transparent,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isSelected
                      ? scheme.primary
                      : danger
                      ? palette.danger
                      : palette.muted,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: foreground,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                      fontSize: 13.5,
                    ),
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: accent,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _roleSwitcher(BuildContext context) {
    final palette = AppPalette.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: palette.surfaceAlt,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        children: [
          _roleChip(context, AppRole.admin, Icons.shield_outlined),
          _roleChip(context, AppRole.staff, Icons.badge_outlined),
        ],
      ),
    );
  }

  Widget _roleChip(BuildContext context, AppRole role, IconData icon) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final palette = AppPalette.of(context);
    final isActive = user.role == role;
    final requiresLogin = role == AppRole.admin && !isActive;
    final label = role == AppRole.admin ? 'Administrator' : 'Staff';

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => onSelectRole(role),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
            decoration: BoxDecoration(
              color: isActive ? scheme.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 15,
                  color: isActive ? scheme.onPrimary : palette.muted,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: isActive
                          ? scheme.onPrimary
                          : scheme.onSurface.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
                if (requiresLogin)
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Icon(
                      Icons.lock_outline_rounded,
                      size: 12,
                      color: palette.muted,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThemeTile(BuildContext context, ThemeData theme) {
    final palette = AppPalette.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onToggleTheme,
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
            decoration: BoxDecoration(
              color: palette.surfaceAlt,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: palette.border),
            ),
            child: Row(
              children: [
                Icon(
                  isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                  size: 19,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Dark mode',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Switch.adaptive(
                  value: isDark,
                  onChanged: (_) => onToggleTheme(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
