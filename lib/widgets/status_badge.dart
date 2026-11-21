import 'package:flutter/material.dart';

import '../models/customer.dart';
import '../theme/app_theme.dart';

class StatusBadge extends StatelessWidget {
  final PaymentStatus status;
  final bool onGradient;

  const StatusBadge({super.key, required this.status, this.onGradient = false});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final config = _getConfig(palette);

    final background = onGradient
        ? Colors.white.withValues(alpha: 0.24)
        : config.color.withValues(alpha: 0.12);
    final border = onGradient
        ? Colors.white.withValues(alpha: 0.42)
        : config.color.withValues(alpha: 0.28);
    final foreground = onGradient ? Colors.white : config.color;
    final dot = onGradient ? Colors.white : config.color;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              config.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: foreground,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  _BadgeConfig _getConfig(AppPalette palette) {
    switch (status) {
      case PaymentStatus.unpaid:
        return _BadgeConfig(label: 'Unpaid', color: palette.muted);
      case PaymentStatus.partiallyPaid:
        return _BadgeConfig(label: 'Partial', color: palette.warning);
      case PaymentStatus.overdue:
        return _BadgeConfig(label: 'Overdue', color: palette.danger);
      case PaymentStatus.fullyPaid:
        return _BadgeConfig(label: 'Fully Paid', color: palette.success);
    }
  }
}

class AccountStatusBadge extends StatelessWidget {
  final AccountStatus status;

  const AccountStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final Color color;
    final String label;

    switch (status) {
      case AccountStatus.active:
        color = Theme.of(context).colorScheme.primary;
        label = 'Active';
        break;
      case AccountStatus.delayed:
        color = palette.danger;
        label = 'Delayed';
        break;
      case AccountStatus.completed:
        color = palette.success;
        label = 'Completed';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _BadgeConfig {
  final String label;
  final Color color;

  _BadgeConfig({required this.label, required this.color});
}
