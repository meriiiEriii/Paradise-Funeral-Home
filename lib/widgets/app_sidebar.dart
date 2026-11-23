import 'package:flutter/material.dart';

import '../auth/app_user.dart';
import '../theme/app_theme.dart';
import 'app_logo.dart';

/// Permanent navigation sidebar shown on wide (desktop/web) layouts.
/// Mirrors the mobile drawer's structure in a full-height, deep-navy
/// admin-console panel.
class AppSidebar extends StatelessWidget {
  final AppUser user;
  final String currentRoute;
  final Function(String) onNavigate;
  final ValueChanged<AppRole> onSelectRole;
  final bool isDark;
  final VoidCallback onToggleTheme;

  const AppSidebar({
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
    final palette = AppPalette.of(context);

    return Material(
      color: palette.navSurface,
      child: SizedBox(
        width: 264,
        child: SafeArea(
          right: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(context),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _sectionLabel(context, 'Role'),
                      _roleSwitcher(context),
                      const SizedBox(height: 12),
                      _sectionLabel(context, 'Workspace'),
                      _navItem(
                        context,
                        Icons.space_dashboard_outlined,
                        'Dashboard',
                        'dashboard',
                      ),
                      _navItem(
                        context,
                        Icons.manage_search_rounded,
                        'All Customers',
                        'search',
                      ),
                      _navItem(
                        context,
                        Icons.inventory_outlined,
                        'Drafts',
                        'drafts',
                      ),
                      const SizedBox(height: 12),
                      _sectionLabel(context, 'Monitoring'),
                      if (user.isAdmin)
                        _navItem(
                          context,
                          Icons.badge_outlined,
                          'Staff',
                          'staff-requests',
                        ),
                      if (user.isAdmin)
                        _navItem(
                          context,
                          Icons.approval_outlined,
                          'Discount Approvals',
                          'approvals',
                        ),
                      if (user.isAdmin)
                        _navItem(
                          context,
                          Icons.payments_rounded,
                          'Payments',
                          'payments',
                        ),
                      _navItem(
                        context,
                        Icons.warning_amber_rounded,
                        'Delayed Accounts',
                        'delayed',
                      ),
                      _navItem(
                        context,
                        Icons.task_alt_outlined,
                        'Paid',
                        'paid',
                      ),
                      _navItem(
                        context,
                        Icons.inventory_2_outlined,
                        'Completed / Archive',
                        'completed',
                      ),
                      const SizedBox(height: 12),
                      _sectionLabel(context, 'System'),
                      _navItem(
                        context,
                        Icons.settings_outlined,
                        'Settings',
                        'settings',
                      ),
                      _navItem(
                        context,
                        Icons.logout_rounded,
                        'Logout',
                        'logout',
                        danger: true,
                      ),
                    ],
                  ),
                ),
              ),
              Divider(
                height: 1,
                color: Colors.white.withValues(alpha: 0.08),
              ),
              _buildFooter(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final palette = AppPalette.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
      child: Row(
        children: [
          const AppLogo(size: 40),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Paradise Funeral Home',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Lora',
                    color: palette.navText,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  'Management System',
                  style: TextStyle(
                    color: palette.navMuted,
                    fontSize: 9.5,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _userRow(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppPalette.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 0, 6, 10),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: Colors.white.withValues(alpha: 0.14),
            child: Text(
              _initial(user.name),
              style: TextStyle(
                color: palette.navText,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: palette.navText,
                  ),
                ),
                Text(
                  user.role.label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: palette.navMuted,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
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

  Widget _sectionLabel(BuildContext context, String label) {
    final theme = Theme.of(context);
    final palette = AppPalette.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
      child: Text(
        label.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: palette.navMuted,
          fontSize: 9.5,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _navItem(
    BuildContext context,
    IconData icon,
    String title,
    String route, {
    bool danger = false,
  }) {
    final theme = Theme.of(context);
    final palette = AppPalette.of(context);
    final isSelected = currentRoute == route && !danger;
    final foreground = danger
        ? const Color(0xFFF0A9A2)
        : isSelected
        ? Colors.white
        : palette.navText;

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => onNavigate(route),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.white.withValues(alpha: 0.10)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: isSelected
                  ? Border.all(
                      color: palette.navActive.withValues(alpha: 0.45),
                    )
                  : Border.all(color: Colors.transparent),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 19,
                  color: isSelected
                      ? palette.navActive
                      : danger
                      ? const Color(0xFFF0A9A2)
                      : palette.navMuted,
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: foreground,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: palette.navActive,
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
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
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
    final palette = AppPalette.of(context);
    final isActive = user.role == role;
    final requiresLogin = role == AppRole.admin && !isActive;
    final label = role == AppRole.admin ? 'Administrator' : 'Staff';

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => onSelectRole(role),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            decoration: BoxDecoration(
              color: isActive ? palette.navActive : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 14,
                  color: isActive ? Colors.white : palette.navMuted,
                ),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: isActive
                          ? Colors.white
                          : palette.navText.withValues(alpha: 0.85),
                      fontWeight: FontWeight.w600,
                      fontSize: 11.5,
                    ),
                  ),
                ),
                if (requiresLogin)
                  Padding(
                    padding: const EdgeInsets.only(left: 3),
                    child: Icon(
                      Icons.lock_outline_rounded,
                      size: 11,
                      color: palette.navMuted,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppPalette.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
          child: _userRow(context),
        ),
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: onToggleTheme,
            child: Container(
              margin: const EdgeInsets.fromLTRB(14, 4, 14, 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
              ),
              child: Row(
                children: [
                  Icon(
                    isDark
                        ? Icons.dark_mode_rounded
                        : Icons.light_mode_rounded,
                    size: 17,
                    color: palette.navActive,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      'Dark mode',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: palette.navText,
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
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 2, 16, 12),
          child: Row(
            children: [
              Icon(Icons.verified_outlined, size: 12, color: palette.navMuted),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  'Paradise Funeral Home · v1.0.0',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: palette.navMuted,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
