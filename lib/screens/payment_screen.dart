import '../utils/formatters.dart';
import 'package:flutter/material.dart';

import '../models/customer.dart';
import '../data/customer_store.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state.dart';
import '../widgets/page_header.dart';
import '../widgets/section_card.dart';
import '../widgets/status_badge.dart';

class PaymentScreen extends StatefulWidget {
  final Customer? customer;
  final CustomerStore store;
  final bool embedded;
  final bool isAdmin;

  const PaymentScreen({
    super.key,
    this.customer,
    required this.store,
    this.embedded = false,
    this.isAdmin = true,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _amountCtrl = TextEditingController();
  Customer? _selectedCustomer;
  late CustomerStore _store;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _store = widget.store;
    _store.addListener(_onStoreChanged);
    if (widget.customer != null) {
      _selectedCustomer =
          _store.getCustomerById(widget.customer!.id) ?? widget.customer;
    }
  }

  void _onStoreChanged() {
    final selected = _selectedCustomer;
    if (!mounted || selected == null) return;
    final updated = _store.getCustomerById(selected.id);
    if (updated != null && !identical(updated, selected)) {
      setState(() => _selectedCustomer = updated);
    }
  }

  @override
  void dispose() {
    _store.removeListener(_onStoreChanged);
    _amountCtrl.dispose();
    super.dispose();
  }

  void _searchCustomer(String query) {
    if (query.isEmpty) {
      setState(() => _selectedCustomer = null);
      return;
    }
    final results = _store.searchAllCustomers(query);
    if (results.isNotEmpty) {
      setState(() => _selectedCustomer = results.first);
    }
  }

  Future<void> _recordPayment() async {
    if (_selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a customer first')),
      );
      return;
    }

    final amountText = _amountCtrl.text.trim();
    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid payment amount')),
      );
      return;
    }

    final remaining = _selectedCustomer!.remainingBalance;
    if (amount > remaining) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Amount exceeds remaining balance (formatPeso(remaining))',
          ),
          backgroundColor: const Color(0xFFC62828),
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final isFull = amount >= (_selectedCustomer!.remainingBalance);
      if (widget.isAdmin) {
        await _store.recordPayment(_selectedCustomer!.id, amount);
      } else {
        await _store.requestPayment(_selectedCustomer!.id, amount);
      }
      final updated = _store.getCustomerById(_selectedCustomer!.id);
      if (!mounted) return;
      setState(() {
        _selectedCustomer = updated ?? _selectedCustomer;
        _amountCtrl.clear();
        _isProcessing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isAdmin
                ? 'Payment of ${formatPeso(amount)} recorded successfully!'
                : 'Your ${isFull ? 'full' : 'partial'} payment of '
                    '${formatPeso(amount)} was sent for admin approval.',
          ),
          backgroundColor: const Color(0xFF2E7D32),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PageHeader(
                icon: Icons.payments_rounded,
                title: 'Process Payment',
                subtitle:
                    'Find an account and record a payment against its remaining balance.',
              ),
              const SizedBox(height: 20),
              if (widget.customer == null) _buildSearchCard(),
              if (widget.customer == null) const SizedBox(height: 16),
              if (_selectedCustomer != null) ...[
                _buildCustomerCard(),
                const SizedBox(height: 16),
                _buildPaymentForm(),
              ] else if (widget.customer == null)
                Card(
                  child: EmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: 'No account selected',
                    message:
                        'Search for a customer above to view their balance and record a payment.',
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    if (!widget.embedded) {
      return Scaffold(
        appBar: AppBar(title: const Text('Payment')),
        body: content,
      );
    }
    return content;
  }

  Widget _buildSearchCard() {
    final theme = Theme.of(context);

    return SectionCard(
      title: 'Find Customer',
      icon: Icons.search_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            style: theme.textTheme.bodyMedium,
            decoration: const InputDecoration(
              hintText: 'Search by name, contact number, or ID...',
              prefixIcon: Icon(Icons.search_rounded, size: 20),
            ),
            onChanged: _searchCustomer,
          ),
          const SizedBox(height: 8),
          Text(
            'The first matching account is selected automatically.',
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppPalette.of(context).muted,
              fontSize: 10.5,
              fontWeight: FontWeight.w400,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerCard() {
    final palette = AppPalette.of(context);
    final c = _selectedCustomer!;
    final total = c.totalDue;
    final progress = total <= 0 ? 1.0 : (c.amountPaid / total).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [palette.heroStart, palette.heroEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
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
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    Text(
                      c.id,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 11,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
              StatusBadge(status: c.paymentStatus, onGradient: true),
            ],
          ),
          const SizedBox(height: 16),
          Divider(height: 1, color: Colors.white.withValues(alpha: 0.18)),
          const SizedBox(height: 14),
          _financeInfoRow('Package', c.package),
          const SizedBox(height: 7),
          _financeInfoRow(
            'Package cost',
            formatPeso(c.totalPackageCost),
          ),
          if (c.approvedDiscount > 0) ...[
            const SizedBox(height: 7),
            _financeInfoRow(
              'Discount',
              '-formatPeso(c.approvedDiscount)',
            ),
          ],
          const SizedBox(height: 7),
          _financeInfoRow('Total due', formatPeso(c.totalDue)),
          const SizedBox(height: 7),
          _financeInfoRow('Amount paid', formatPeso(c.amountPaid)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Payment progress',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.78),
                    fontSize: 10.5,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${(progress * 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              backgroundColor: Colors.white.withValues(alpha: 0.16),
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Remaining balance',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  formatPeso(c.remainingBalance),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentForm() {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final palette = AppPalette.of(context);
    final c = _selectedCustomer!;

    return SectionCard(
      title: 'Payment Details',
      icon: Icons.account_balance_wallet_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _amountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: theme.textTheme.bodyMedium,
            decoration: const InputDecoration(
              labelText: 'Payment Amount',
              prefixText: '₱ ',
              prefixIcon: Icon(Icons.attach_money_rounded, size: 19),
              hintText: 'Enter amount to pay',
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.info_outline_rounded, size: 14, color: palette.muted),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Remaining balance: formatPeso(c.remainingBalance)',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: palette.muted,
                    fontSize: 11.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isProcessing || c.remainingBalance <= 0
                  ? null
                  : _recordPayment,
              icon: _isProcessing
                  ? SizedBox(
                      height: 17,
                      width: 17,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: scheme.onPrimary,
                      ),
                    )
                  : const Icon(Icons.check_circle_outline_rounded, size: 19),
              label: Text(
                c.remainingBalance <= 0
                    ? 'Fully Paid'
                    : widget.isAdmin
                    ? 'Record Payment'
                    : 'Send for Approval',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _financeInfoRow(String label, String value) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            maxLines: 1,
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 12.5,
            ),
          ),
        ),
      ],
    );
  }
}
