import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/customer.dart';
import '../data/customer_store.dart';
import '../theme/app_theme.dart';
import '../widgets/customer_table.dart';
import '../widgets/empty_state.dart';

class SearchCustomerScreen extends StatefulWidget {
  final CustomerStore store;

  const SearchCustomerScreen({super.key, required this.store});

  @override
  State<SearchCustomerScreen> createState() => _SearchCustomerScreenState();
}

class _SearchCustomerScreenState extends State<SearchCustomerScreen> {
  final _searchCtrl = TextEditingController();
  List<Customer> _results = [];
  bool _sortAscending = true;
  int? _sortColumnIndex;

  @override
  void initState() {
    super.initState();
    widget.store.addListener(_onStoreChanged);
    // Every customer record Ã¢â‚¬â€ active, delayed, and completed Ã¢â‚¬â€ is listed
    // right away, newest first.
    _results = widget.store.searchAllCustomers(_searchCtrl.text);
  }

  void _onStoreChanged() {
    setState(() {
      _results = widget.store.searchAllCustomers(_searchCtrl.text);
      _applySort(_results);
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
      _applySort(_results);
    });
  }

  void _applySort(List<Customer> customers) {
    if (_sortColumnIndex == null) return;
    final ascending = _sortAscending;
    customers.sort((a, b) {
      int result;
      switch (_sortColumnIndex) {
        case 0:
          result = a.dateAdded.compareTo(b.dateAdded);
          break;
        case 1:
          result = a.name.toLowerCase().compareTo(b.name.toLowerCase());
          break;
        case 5:
          result = a.totalPackageCost.compareTo(b.totalPackageCost);
          break;
        case 6:
          result = a.amountPaid.compareTo(b.amountPaid);
          break;
        case 7:
          result = a.remainingBalance.compareTo(b.remainingBalance);
          break;
        case 8:
          result = a.paymentStatus.index.compareTo(b.paymentStatus.index);
          break;
        case 10:
          result = a.dueDate.compareTo(b.dueDate);
          break;
        default:
          result = 0;
      }
      return ascending ? result : -result;
    });
  }

  void _onSort(int columnIndex, bool ascending) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;
      _applySort(_results);
    });
  }

  void _openProfile(Customer customer) {
    context.push('/customer/${customer.id}');
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
                      'Every customer record Ã¢â‚¬â€ active, delayed, or completed. Search by name, contact number, or customer ID.',
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

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1240),
        child: Card(
          margin: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(
                          alpha: 0.09,
                        ),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Icon(
                        Icons.table_rows_rounded,
                        size: 17,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        'All Customers',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: palette.surfaceAlt,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: palette.border),
                      ),
                      child: Text(
                        '${_results.length}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: palette.muted,
                          fontSize: 10.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: palette.border),
              Expanded(
                child: SingleChildScrollView(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: CustomerTable(
                      customers: _results,
                      sortColumnIndex: _sortColumnIndex,
                      sortAscending: _sortAscending,
                      onSort: _onSort,
                      onRowTap: _openProfile,
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
}
