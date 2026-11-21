import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../config/app_config.dart';
import '../data/customer_store.dart';
import '../models/customer.dart';
import '../theme/app_theme.dart';

Future<void> showCustomerQrDialog(
  BuildContext context, {
  required Customer customer,
  required CustomerStore store,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) => _CustomerQrDialog(customer: customer, store: store),
  );
}

class _CustomerQrDialog extends StatefulWidget {
  final Customer customer;
  final CustomerStore store;

  const _CustomerQrDialog({required this.customer, required this.store});

  @override
  State<_CustomerQrDialog> createState() => _CustomerQrDialogState();
}

class _CustomerQrDialogState extends State<_CustomerQrDialog> {
  bool _publishing = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _publish();
  }

  Future<void> _publish() async {
    setState(() {
      _publishing = true;
      _error = null;
    });
    try {
      await widget.store.publishCustomerView(widget.customer.id);
      if (mounted) setState(() => _publishing = false);
    } catch (error) {
      if (mounted) {
        setState(() {
          _publishing = false;
          _error = error.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppPalette.of(context);
    final url = customerViewUrl(widget.customer.id);

    return AlertDialog(
      icon: Icon(
        Icons.qr_code_2_rounded,
        color: theme.colorScheme.primary,
        size: 28,
      ),
      title: const Text('Customer QR code'),
      content: SizedBox(
        width: 340,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${widget.customer.name} · ${widget.customer.id}',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: palette.muted,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: palette.border),
              ),
              child: _publishing
                  ? const SizedBox(
                      height: 200,
                      child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : Center(
                      child: QrImageView(
                        data: url,
                        version: QrVersions.auto,
                        size: 200,
                        backgroundColor: Colors.white,
                      ),
                    ),
            ),
            const SizedBox(height: 14),
            if (_error != null)
              Text(
                'Could not refresh the online receipt: $_error',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: palette.danger,
                ),
              )
            else
              Text(
                'Customers can scan this code with any phone camera to view '
                'their receipt and account details online (view-only).',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: palette.muted,
                  fontSize: 11.5,
                  height: 1.4,
                ),
              ),
            const SizedBox(height: 10),
            SelectableText(
              url,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelSmall?.copyWith(
                color: palette.muted,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton.icon(
          onPressed: _publishing ? null : _publish,
          icon: const Icon(Icons.refresh_rounded, size: 17),
          label: const Text('Refresh receipt'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Done'),
        ),
      ],
    );
  }
}
