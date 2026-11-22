import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/app_preferences.dart';
import '../models/customer_draft.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state.dart';
import '../widgets/page_header.dart';

/// Unfinished New Customer forms saved by the user.
class DraftsScreen extends StatefulWidget {
  final AppPreferences? preferences;

  const DraftsScreen({super.key, this.preferences});

  @override
  State<DraftsScreen> createState() => _DraftsScreenState();
}

class _DraftsScreenState extends State<DraftsScreen> {
  List<CustomerDraft> _drafts = const [];

  @override
  void initState() {
    super.initState();
    _drafts = widget.preferences?.loadDrafts() ?? const [];
  }

  Future<void> _delete(CustomerDraft draft) async {
    await widget.preferences?.deleteDraft(draft.id);
    if (!mounted) return;
    setState(() {
      _drafts = widget.preferences?.loadDrafts() ?? const [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PageHeader(
                icon: Icons.inventory_outlined,
                title: 'Drafts',
                subtitle:
                    'Unfinished customer registrations saved from the '
                    'New Customer page.',
              ),
              const SizedBox(height: 20),
              if (_drafts.isEmpty)
                Card(
                  child: EmptyState(
                    icon: Icons.inventory_2_outlined,
                    title: 'No drafts',
                    message:
                        'When you back out of the New Customer page, you can '
                        'save the unfinished information here to finalize '
                        'later.',
                  ),
                )
              else
                for (final draft in _drafts) ...[
                  _buildDraftCard(context, draft),
                  const SizedBox(height: 14),
                ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDraftCard(BuildContext context, CustomerDraft draft) {
    final theme = Theme.of(context);
    final palette = AppPalette.of(context);
    final itemsLabel =
        '${draft.items.length} item${draft.items.length != 1 ? 's' : ''}';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: palette.brandSoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.inventory_outlined,
                size: 21,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    draft.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      if (draft.contactNumber.isNotEmpty)
                        draft.contactNumber
                      else
                        'No contact number yet',
                      itemsLabel,
                      'Saved ${_formatDate(draft.savedAt)}',
                    ].join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: palette.muted,
                      fontSize: 10.5,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Delete draft',
              icon: Icon(
                Icons.delete_outline_rounded,
                size: 20,
                color: palette.danger,
              ),
              onPressed: () => _delete(draft),
            ),
            const SizedBox(width: 4),
            ElevatedButton.icon(
              onPressed: () => context.go('/add?draft=${draft.id}'),
              icon: const Icon(Icons.edit_rounded, size: 16),
              label: const Text('Finalize'),
            ),
          ],
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
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '${months[date.month - 1]} ${date.day}, '
        '$hour:$minute $period';
  }
}
