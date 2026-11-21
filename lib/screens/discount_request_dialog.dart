import 'package:flutter/material.dart';

import '../data/customer_store.dart';
import '../models/customer.dart';
import '../theme/app_theme.dart';

Future<bool> showDiscountRequestDialog(
  BuildContext context, {
  required Customer customer,
  required CustomerStore store,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) =>
        _DiscountRequestDialog(customer: customer, store: store),
  );
  return result ?? false;
}

class _DiscountRequestDialog extends StatefulWidget {
  final Customer customer;
  final CustomerStore store;

  const _DiscountRequestDialog({
    required this.customer,
    required this.store,
  });

  @override
  State<_DiscountRequestDialog> createState() => _DiscountRequestDialogState();
}

class _DiscountRequestDialogState extends State<_DiscountRequestDialog> {
  final _amountCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();
  String? _error;
  bool _submitting = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_amountCtrl.text.trim());
    final reason = _reasonCtrl.text.trim();
    if (amount == null || amount <= 0) {
      setState(() => _error = 'Enter a discount amount greater than zero.');
      return;
    }
    if (amount > widget.customer.remainingBalance) {
      setState(
        () => _error =
            'The discount cannot exceed the remaining balance of ₱${widget.customer.remainingBalance.toStringAsFixed(2)}.',
      );
      return;
    }
    if (reason.isEmpty) {
      setState(() => _error = 'A reason is required for the request.');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      await widget.store.requestDiscount(
        widget.customer.id,
        amount,
        reason,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = error.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppPalette.of(context);
    final customer = widget.customer;

    return AlertDialog(
      icon: Icon(
        Icons.percent_rounded,
        color: theme.colorScheme.primary,
        size: 26,
      ),
      title: const Text('Request a discount'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${customer.name} · ${customer.id}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: palette.muted,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Remaining balance: ₱${customer.remainingBalance.toStringAsFixed(2)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: palette.muted,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Discount amount',
                  prefixText: '₱ ',
                  prefixIcon: Icon(Icons.attach_money_rounded, size: 19),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _reasonCtrl,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Reason',
                  hintText: 'Why does this account need a discount?',
                  alignLabelWithHint: true,
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: palette.danger,
                  ),
                ),
              ],
              const SizedBox(height: 4),
              Text(
                'An admin must approve the request before the discount is applied.',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: palette.muted,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          onPressed: _submitting ? null : _submit,
          icon: _submitting
              ? const SizedBox(
                  width: 15,
                  height: 15,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.send_rounded, size: 17),
          label: Text(_submitting ? 'Sending...' : 'Send request'),
        ),
      ],
    );
  }
}
