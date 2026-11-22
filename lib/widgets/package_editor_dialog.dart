import 'package:flutter/material.dart';

import '../data/customer_store.dart';
import '../models/customer.dart';
import '../models/package_template.dart';
import '../theme/app_theme.dart';

/// Admin dialog for creating or editing a pre-made package template.
///
/// Returns the saved [PackageTemplate], or null when cancelled/deleted.
Future<PackageTemplate?> showPackageEditorDialog(
  BuildContext context, {
  required CustomerStore store,
  PackageTemplate? existing,
}) {
  return showDialog<PackageTemplate>(
    context: context,
    builder: (context) =>
        _PackageEditorDialog(store: store, existing: existing),
  );
}

class _PackageEditorDialog extends StatefulWidget {
  final CustomerStore store;
  final PackageTemplate? existing;

  const _PackageEditorDialog({required this.store, this.existing});

  @override
  State<_PackageEditorDialog> createState() => _PackageEditorDialogState();
}

class _PackageEditorDialogState extends State<_PackageEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  final _itemNameCtrls = <TextEditingController>[];
  final _itemAmountCtrls = <TextEditingController>[];
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _nameCtrl = TextEditingController(text: existing?.name ?? '');
    if (existing == null || existing.items.isEmpty) {
      _addItem();
    } else {
      for (final item in existing.items) {
        _addItem(name: item.name, amount: item.amount.toStringAsFixed(2));
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    for (final controller in [..._itemNameCtrls, ..._itemAmountCtrls]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addItem({String name = '', String amount = ''}) {
    setState(() {
      _itemNameCtrls.add(TextEditingController(text: name));
      _itemAmountCtrls.add(TextEditingController(text: amount));
    });
  }

  void _removeItem(int index) {
    setState(() {
      _itemNameCtrls.removeAt(index).dispose();
      _itemAmountCtrls.removeAt(index).dispose();
    });
  }

  String _titleCase(String value) {
    final trimmed = value.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (trimmed.isEmpty) return trimmed;
    return trimmed
        .split(' ')
        .map(
          (word) => word.isEmpty
              ? word
              : word[0].toUpperCase() + word.substring(1).toLowerCase(),
        )
        .join(' ');
  }

  Future<void> _save() async {
    if (_busy || !_formKey.currentState!.validate()) return;

    final name = _titleCase(_nameCtrl.text);
    if (name.isEmpty) {
      setState(() => _error = 'Package name is required.');
      return;
    }

    final items = <PackageItem>[];
    for (var i = 0; i < _itemNameCtrls.length; i++) {
      final itemName = _itemNameCtrls[i].text.trim();
      final amount = double.tryParse(_itemAmountCtrls[i].text.trim()) ?? 0;
      if (itemName.isEmpty && amount <= 0) continue;
      if (itemName.isEmpty || amount <= 0) {
        setState(
          () => _error = 'Every item needs a name and an amount greater '
              'than zero.',
        );
        return;
      }
      items.add(PackageItem(name: _titleCase(itemName), amount: amount));
    }
    if (items.isEmpty) {
      setState(() => _error = 'Add at least one item to the package.');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final existing = widget.existing;
      final saved = await widget.store.savePackageTemplate(
        existing == null
            ? PackageTemplate(
                id: '',
                name: name,
                items: items,
                createdAt: DateTime.now(),
              )
            : existing.copyWith(name: name, items: items),
      );
      if (!mounted) return;
      Navigator.of(context).pop(saved);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = error.toString();
      });
    }
  }

  Future<void> _delete() async {
    final existing = widget.existing;
    if (existing == null || _busy) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.delete_outline_rounded, size: 26),
        title: const Text('Delete package'),
        content: Text('Delete "${existing.name}" from the package list?'),
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
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _busy = true);
    try {
      await widget.store.deletePackageTemplate(existing.id);
      if (!mounted) return;
      Navigator.of(context).pop(existing);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = error.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppPalette.of(context);
    final isEditing = widget.existing != null;

    return AlertDialog(
      icon: Icon(
        Icons.inventory_2_outlined,
        color: theme.colorScheme.primary,
        size: 26,
      ),
      title: Text(isEditing ? 'Edit package' : 'New package'),
      content: SizedBox(
        width: 440,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  key: const Key('package-name-field'),
                  controller: _nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Package name',
                    hintText: 'e.g. Package 1',
                    prefixIcon: Icon(Icons.sell_outlined, size: 19),
                  ),
                  validator: (v) =>
                      (v?.trim().isEmpty ?? true) ? 'Name is required' : null,
                ),
                const SizedBox(height: 16),
                Text(
                  'Package items',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: palette.muted,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 8),
                for (var i = 0; i < _itemNameCtrls.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            key: Key('package-item-name-$i'),
                            controller: _itemNameCtrls[i],
                            textCapitalization: TextCapitalization.words,
                            decoration: InputDecoration(
                              labelText: 'Item ${i + 1}',
                              hintText: 'e.g. Casket',
                            ),
                          ),
                        ),

                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            key: Key('package-item-amount-$i'),
                            controller: _itemAmountCtrls[i],
                            keyboardType:
                                const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                            decoration: const InputDecoration(
                              labelText: 'Amount',
                              prefixText: '₱ ',
                            ),
                          ),
                        ),
                        if (_itemNameCtrls.length > 1)
                          IconButton(
                            tooltip: 'Remove item',
                            icon: Icon(
                              Icons.remove_circle_outline_rounded,
                              size: 20,
                              color: palette.danger,
                            ),
                            onPressed: () => _removeItem(i),
                          ),
                      ],
                    ),
                  ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: _addItem,
                    icon: const Icon(Icons.add_rounded, size: 17),
                    label: const Text('Add item'),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _error!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: palette.danger,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actions: [
        if (isEditing)
          TextButton.icon(
            onPressed: _busy ? null : _delete,
            icon: const Icon(Icons.delete_outline_rounded, size: 17),
            label: const Text('Delete'),
            style: TextButton.styleFrom(foregroundColor: palette.danger),
          )
        else
          const SizedBox.shrink(),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              onPressed: _busy ? null : () => Navigator.of(context).pop(null),
              child: const Text('Cancel'),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: _busy ? null : _save,
              icon: _busy
                  ? const SizedBox(
                      width: 15,
                      height: 15,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check_rounded, size: 17),
              label: Text(isEditing ? 'Save changes' : 'Create package'),
            ),
          ],
        ),
      ],
    );
  }
}
