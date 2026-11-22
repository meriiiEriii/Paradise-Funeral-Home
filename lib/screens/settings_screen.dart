import 'package:flutter/material.dart';

import '../auth/app_user.dart';
import '../theme/app_theme.dart';
import '../widgets/app_logo.dart';
import '../widgets/page_header.dart';

/// Working settings page: account details, appearance, about, sign out.
class SettingsScreen extends StatefulWidget {
  final AppUser user;
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onSetThemeMode;
  final VoidCallback onSignOut;

  const SettingsScreen({
    super.key,
    required this.user,
    required this.themeMode,
    required this.onSetThemeMode,
    required this.onSignOut,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Future<void> _confirmSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(
          Icons.logout_rounded,
          color: Theme.of(context).colorScheme.error,
          size: 28,
        ),
        title: const Text('Logout'),
        content: const Text(
          'Are you sure you want to logout of the management console?',
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
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    if (confirmed == true) widget.onSignOut();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppPalette.of(context);
    final scheme = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PageHeader(
                icon: Icons.settings_outlined,
                title: 'Settings',
                subtitle: 'Manage your account, appearance, and system information.',
              ),
              const SizedBox(height: 20),
              _sectionCard(
                context,
                icon: Icons.person_outline_rounded,
                title: 'Account',
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: palette.brandSoft,
                      child: Text(
                        _initial(widget.user.name),
                        style: TextStyle(
                          color: scheme.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.user.name,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.user.email,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: palette.muted,
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
                        color: palette.brandSoft,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: scheme.primary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Text(
                        widget.user.role.label,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: scheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _sectionCard(
                context,
                icon: Icons.dark_mode_outlined,
                title: 'Appearance',
                child: Row(
                  children: [
                    Expanded(child: _themeOption(context, ThemeMode.light)),
                    const SizedBox(width: 10),
                    Expanded(child: _themeOption(context, ThemeMode.dark)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _sectionCard(
                context,
                icon: Icons.info_outline_rounded,
                title: 'About',
                child: Column(
                  children: [
                    Row(
                      children: [
                        const AppLogo(size: 52),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Paradise Funeral Home',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontFamily: 'Lora',
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                'Management System · Version 1.0.0',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: palette.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Customer registry, payments, discount approvals, staff '
                      'administration, and QR receipts for Paradise Funeral '
                      'Home.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: palette.muted,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: palette.danger,
                        side: BorderSide(
                          color: palette.danger.withValues(alpha: 0.4),
                        ),
                      ),
                      onPressed: _confirmSignOut,
                      icon: const Icon(Icons.logout_rounded, size: 18),
                      label: const Text('Sign out'),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _themeOption(BuildContext context, ThemeMode mode) {
    final theme = Theme.of(context);
    final palette = AppPalette.of(context);
    final selected = widget.themeMode == mode;
    final isDark = mode == ThemeMode.dark;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => widget.onSetThemeMode(mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? palette.brandSoft : palette.surfaceAlt,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? Theme.of(context).colorScheme.primary
                : palette.border,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
              size: 20,
              color: selected
                  ? Theme.of(context).colorScheme.primary
                  : palette.muted,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isDark ? 'Dark' : 'Light',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
            if (selected)
              Icon(
                Icons.check_circle_rounded,
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 17, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }

  String _initial(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'U';
    return trimmed[0].toUpperCase();
  }
}
