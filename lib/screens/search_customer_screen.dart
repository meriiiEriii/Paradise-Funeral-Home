import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/customer.dart';
import '../data/customer_store.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state.dart';
import '../widgets/status_badge.dart';

class SearchCustomerScreen extends StatefulWidget {
  final CustomerStore store;

  const SearchCustomerScreen({super.key, required this.store});

  @override
  State<SearchCustomerScreen> createState() => _SearchCustomerScreenState();
}

class _SearchCustomerScreenState extends State<SearchCustomerScreen> {
  final _searchCtrl = TextEditingController();
  List<Customer> _results = [];

  @override
  void initState() {
    super.initState();
    widget.store.addListener(_onStoreChanged);
    // Every customer record â€” active, delayed, and completed â€” is listed
    // right away, newest first.
    _results = widget.store.searchAllCustomers(_searchCtrl.text);
  }

  void _onStoreChanged() {
    setState(() {
      _results = widget.store.searchAllCustomers(_searchCtrl.text);
    });
  }

  @override
  void dispose() {
    widget.store.removeListener(_onStoreChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  void _search(String query) {
    setState(() {
      _results = widget.store.searchAllCustomers(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1120),
              child: _buildSearchHero(),
            ),
          ),
        ),
        Expanded(child: _buildResults()),
      ],
    );
  }

  Widget _buildSearchHero() {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final palette = AppPalette.of(context);

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
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.16),
                  ),
                ),
                child: const Icon(
                  Icons.person_search_rounded,
                  color: Colors.white,
                  size: 23,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'All Customers',
                      style: TextStyle(
                        fontFamily: 'Lora',
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Every customer record â€” active, delayed, or completed. Search by name, contact number, or customer ID.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.82),
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _searchCtrl,
            style: theme.textTheme.bodyMedium,
            decoration: InputDecoration(
              hintText: 'Type a name, contact number, or ID...',
              prefixIcon: Icon(Icons.search_rounded, color: scheme.primary),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(
                      tooltip: 'Clear',
                      icon: const Icon(Icons.close_rounded, size: 18),
                      onPressed: () {
                        _searchCtrl.clear();
                        _search('');
                      },
                    )
                  : null,
              fillColor: scheme.surface,
            ),
            onChanged: _search,
            textInputAction: TextInputAction.search,
          ),
        ],
      ),
    );
  }

  Widget _buildResults() {

    if (_results.isEmpty) {
      return const EmptyState(
        icon: Icons.person_off_outlined,
        title: 'No customers found',
        message:
            'Try a different spelling, a shorter contact number, or the customer ID.',
      );
    }

    final theme = Theme.of(context);
    final palette = AppPalette.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1120),
              child: Row(
                children: [
                  Text(
                    '${_results.length} result${_results.length != 1 ? 's' : ''}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: palette.muted,
                      letterSpacing: 0.6,
                      fontSize: 11,
                    ),
                  ),
                  const Spacer(),
                  Flexible(
                    child: Text(
                      'Tap a card to open the full profile',
                      textAlign: TextAlign.right,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: palette.muted,
                        letterSpacing: 0.1,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async => _search(_searchCtrl.text),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              itemCount: _results.length,
              itemBuilder: (context, index) {
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1120),
                    child: _buildCustomerCard(_results[index]),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCustomerCard(Customer customer) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final palette = AppPalette.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _openProfile(customer),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(
                        color: scheme.primary.withValues(alpha: 0.16),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        _initials(customer.name),
                        style: TextStyle(
                          color: scheme.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customer.name,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 14.5,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          customer.id,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: palette.muted,
                            fontSize: 10.5,
                            letterSpacing: 0.6,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  StatusBadge(status: customer.paymentStatus),
                ],
              ),
              const SizedBox(height: 14),
              Divider(height: 1, color: palette.border),
              const SizedBox(height: 12),
              _detailRow(Icons.location_on_outlined, customer.address),
              const SizedBox(height: 7),
              _detailRow(Icons.phone_outlined, customer.contactNumber),
              const SizedBox(height: 7),
              _detailRow(Icons.inventory_2_outlined, customer.package),
              const SizedBox(height: 14),
              LayoutBuilder(
                builder: (context, constraints) {
                  final tiles = [
                    _moneyTile(
                      'PACKAGE COST',
                      customer.totalPackageCost,
                      scheme.onSurface,
                    ),
                    _moneyTile(
                      'AMOUNT PAID',
                      customer.amountPaid,
                      palette.success,
                    ),
                    _moneyTile(
                      'BALANCE',
                      customer.remainingBalance,
                      customer.remainingBalance > 0
                          ? palette.danger
                          : palette.success,
                    ),
                  ];
                  if (constraints.maxWidth < 360) {
                    return Column(
                      children: [
                        for (var i = 0; i < tiles.length; i++) ...[
                          if (i > 0) const SizedBox(height: 8),
                          tiles[i],
                        ],
                      ],
                    );
                  }
                  return Row(
                    children: [
                      for (var i = 0; i < tiles.length; i++) ...[
                        if (i > 0) const SizedBox(width: 8),
                        Expanded(child: tiles[i]),
                      ],
                    ],
                  );
                },
              ),
              if (customer.remarks.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: palette.surfaceAlt,
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: palette.border),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.notes_outlined,
                        size: 14,
                        color: palette.muted,
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          customer.remarks,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: palette.muted,
                            fontSize: 11.5,
                            fontStyle: FontStyle.italic,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  AccountStatusBadge(status: customer.accountStatus),
                  TextButton.icon(
                    onPressed: () => _openProfile(customer),
                    icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                    label: const Text('View Profile'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String text) {
    final theme = Theme.of(context);
    final palette = AppPalette.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: palette.muted),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: palette.muted,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _moneyTile(String label, double amount, Color color) {
    final theme = Theme.of(context);
    final palette = AppPalette.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: palette.surfaceAlt,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: palette.muted,
              fontSize: 9.5,
              letterSpacing: 0.7,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'â‚±${amount.toStringAsFixed(2)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 12.5,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _openProfile(Customer customer) {
    context.push('/customer/${customer.id}');
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }
}
