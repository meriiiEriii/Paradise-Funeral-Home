import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/app_preferences.dart';
import '../data/customer_store.dart';
import '../models/customer.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state.dart';
import '../widgets/stat_card.dart';
import '../widgets/status_badge.dart';

class DashboardScreen extends StatefulWidget {
  final CustomerStore store;
  final AppPreferences? preferences;
  final bool isAdmin;

  const DashboardScreen({
    super.key,
    required this.store,
    this.preferences,
    this.isAdmin = false,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _searchCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  String _searchQuery = '';
  String _addressQuery = '';
  String _statusFilter = 'active';
  String _yearFilter = 'all';
  DateTime? _dateAddedFilter;
  DateTime? _dueDateFilter;
  bool _sortAscending = true;
  int? _sortColumnIndex;
  List<Customer> _localCustomers = const [];
  bool _showImportBanner = false;
  bool _importing = false;

  bool get _hasActiveFilters =>
      _addressQuery.isNotEmpty ||
      _statusFilter != 'active' ||
      _yearFilter != 'all' ||
      _dateAddedFilter != null ||
      _dueDateFilter != null;

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  List<String> get _availableYears {
    final years = widget.store.allCustomers
        .map((c) => c.dateAdded.year)
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));
    return years.map((year) => year.toString()).toList();
  }

  @override
  void initState() {
    super.initState();
    widget.store.addListener(_onStoreChanged);
    _loadImportState();
  }

  void _loadImportState() {
    final preferences = widget.preferences;
    if (preferences == null ||
        !widget.isAdmin ||
        preferences.customersImported) {
      return;
    }
    final local = preferences.loadLocalCustomers();
    if (local.isEmpty) return;
    _localCustomers = local;
    _showImportBanner = true;
  }

  void _onStoreChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.store.removeListener(_onStoreChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Customer> get _filteredCustomers {
    var customers = widget.store.searchAllCustomers(_searchQuery).where((c) {
      // The dashboard defaults to active accounts; the filters can surface
      // any other status.
      switch (_statusFilter) {
        case 'active':
          if (c.accountStatus != AccountStatus.active) return false;
          break;
        case 'delayed':
          if (c.accountStatus != AccountStatus.delayed) return false;
          break;
        case 'paid':
          if (c.accountStatus != AccountStatus.paid) return false;
          break;
        case 'completed':
          if (c.accountStatus != AccountStatus.completed) return false;
          break;
      }
      if (_addressQuery.isNotEmpty &&
          !c.address.toLowerCase().contains(
            _addressQuery.toLowerCase(),
          )) {
        return false;
      }
      if (_yearFilter != 'all' && c.dateAdded.year.toString() != _yearFilter) {
        return false;
      }
      if (_dateAddedFilter != null &&
          !_sameDay(c.dateAdded, _dateAddedFilter!)) {
        return false;
      }
      if (_dueDateFilter != null && !_sameDay(c.dueDate, _dueDateFilter!)) {
        return false;
      }
      return true;
    }).toList();
    _applySort(customers);
    return customers;
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
    });
  }

  Future<void> _importLocalCustomers() async {
    final preferences = widget.preferences;
    if (preferences == null || _importing) return;

    setState(() => _importing = true);
    try {
      final count = await widget.store.importCustomers(_localCustomers);
      await preferences.markCustomersImported();
      if (!mounted) return;
      setState(() {
        _importing = false;
        _showImportBanner = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            count == 0
                ? 'Those local customers are already in the shared database.'
                : 'Imported $count local customers.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _importing = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Widget _buildImportBanner() {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final palette = AppPalette.of(context);
    final count = _localCustomers.length;

    final info = Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.cloud_upload_rounded,
            color: scheme.primary,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$count local customers ready to import',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'These records exist only in this browser. Import them into the shared database so every signed-in user can see them.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: palette.muted,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    final button = FilledButton.icon(
      onPressed: _importing ? null : _importLocalCustomers,
      icon: _importing
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.cloud_upload_rounded, size: 18),
      label: Text(_importing ? 'Importing...' : 'Import now'),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 560) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [info, const SizedBox(height: 12), button],
              );
            }
            return Row(
              children: [
                Expanded(child: info),
                const SizedBox(width: 12),
                button,
              ],
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final customers = _filteredCustomers;
    final store = widget.store;

    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontal = constraints.maxWidth >= 720 ? 24.0 : 16.0;
        final contentWidth = constraints.maxWidth > 1440
            ? 1440.0
            : constraints.maxWidth;
        final scrollingPage =
            constraints.maxWidth < 900 || constraints.maxHeight < 640;

        if (scrollingPage) {
          return Center(
            child: SizedBox(
              width: contentWidth,
              height: constraints.maxHeight,
              child: ListView(
                padding: EdgeInsets.fromLTRB(horizontal, 20, horizontal, 24),
                children: [
                  if (_showImportBanner) ...[
                    _buildImportBanner(),
                    const SizedBox(height: 16),
                  ],
                  _buildStatsRow(store),
                  const SizedBox(height: 16),
                  _buildToolbar(customers.length),
                  const SizedBox(height: 16),
                  SizedBox(height: 520, child: _buildBody(customers)),
                ],
              ),
            ),
          );
        }

        return Center(
          child: SizedBox(
            width: contentWidth,
            height: constraints.maxHeight,
            child: Column(
              children: [
                if (_showImportBanner)
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      horizontal,
                      20,
                      horizontal,
                      0,
                    ),
                    child: _buildImportBanner(),
                  ),
                Padding(
                  padding: EdgeInsets.fromLTRB(horizontal, 20, horizontal, 0),
                  child: _buildStatsRow(store),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(horizontal, 16, horizontal, 0),
                  child: _buildToolbar(customers.length),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      horizontal,
                      16,
                      horizontal,
                      16,
                    ),
                    child: _buildBody(customers),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatsRow(CustomerStore store) {
    final scheme = Theme.of(context).colorScheme;
    final palette = AppPalette.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1000
            ? 4
            : constraints.maxWidth >= 280
            ? 2
            : 1;
        const gap = 14.0;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;

        final cards = [
          StatCard(
            label: 'Active accounts',
            value: '${store.totalActiveCustomers}',
            caption: 'of ${store.allCustomers.length} total clients',
            icon: Icons.groups_2_outlined,
            accent: scheme.primary,
          ),
          StatCard(
            label: 'Package revenue',
            value: '₱${store.totalRevenue.toStringAsFixed(0)}',
            caption: 'Across active accounts',
            icon: Icons.trending_up_rounded,
            accent: palette.accent,
          ),
          StatCard(
            label: 'Overdue',
            value: '${store.overdueCount}',
            caption: store.overdueCount == 0
                ? 'All accounts on schedule'
                : 'Requires follow-up',
            icon: Icons.warning_amber_rounded,
            accent: palette.danger,
          ),
          StatCard(
            label: 'Fully paid',
            value: '${store.fullyPaidCount}',
            caption: 'Settled active accounts',
            icon: Icons.verified_outlined,
            accent: palette.success,
          ),
        ];

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final card in cards) SizedBox(width: width, child: card),
          ],
        );
      },
    );
  }

  Widget _buildToolbar(int shownCount) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final palette = AppPalette.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    style: theme.textTheme.bodyMedium,
                    decoration: InputDecoration(
                      hintText:
                          'Search accounts by name, contact, or ID',
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              tooltip: 'Clear search',
                              icon: const Icon(Icons.close_rounded, size: 18),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                    ),
                    onChanged: (v) => setState(() => _searchQuery = v),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: palette.brandSoft,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: scheme.primary.withValues(alpha: 0.14),
                    ),
                  ),
                  child: Text(
                    '$shownCount shown',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _buildFilterRow(theme, scheme, palette),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterRow(
    ThemeData theme,
    ColorScheme scheme,
    AppPalette palette,
  ) {
    Future<void> pickDate({required bool isDueDate}) async {
      final picked = await showDatePicker(
        context: context,
        initialDate: isDueDate
            ? (_dueDateFilter ?? DateTime.now())
            : (_dateAddedFilter ?? DateTime.now()),
        firstDate: DateTime(2020),
        lastDate: DateTime(2035),
      );
      if (picked == null) return;
      setState(() {
        if (isDueDate) {
          _dueDateFilter = picked;
        } else {
          _dateAddedFilter = picked;
        }
      });
    }

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 190,
          child: TextField(
            controller: _addressCtrl,
            style: theme.textTheme.bodySmall,
            decoration: InputDecoration(
              hintText: 'Filter by address',
              prefixIcon: const Icon(Icons.location_on_outlined, size: 18),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              suffixIcon: _addressQuery.isNotEmpty
                  ? IconButton(
                      tooltip: 'Clear address filter',
                      icon: const Icon(Icons.close_rounded, size: 16),
                      onPressed: () {
                        _addressCtrl.clear();
                        setState(() => _addressQuery = '');
                      },
                    )
                  : null,
            ),
            onChanged: (v) => setState(() => _addressQuery = v),
          ),
        ),
        _filterDropdown(
          theme,
          palette,
          value: _statusFilter,
          label: _statusLabel(_statusFilter),
          icon: Icons.flag_outlined,
          items: const [
            ('active', 'Active'),
            ('delayed', 'Delayed'),
            ('paid', 'Paid'),
            ('completed', 'Completed'),
            ('all', 'All statuses'),
          ],
          onChanged: (value) => setState(() => _statusFilter = value),
        ),
        _filterDropdown(
          theme,
          palette,
          value: _yearFilter,
          label: _yearFilter == 'all' ? 'All years' : _yearFilter,
          icon: Icons.calendar_today_outlined,
          items: [
            ('all', 'All years'),
            for (final year in _availableYears) (year, year),
          ],
          onChanged: (value) => setState(() => _yearFilter = value),
        ),
        _filterDateChip(
          theme,
          palette,
          label: _dateAddedFilter == null
              ? 'Date added'
              : 'Added ${_formatDate(_dateAddedFilter!)}',
          icon: Icons.event_outlined,
          selected: _dateAddedFilter != null,
          onTap: () => pickDate(isDueDate: false),
          onClear: () => setState(() => _dateAddedFilter = null),
        ),
        _filterDateChip(
          theme,
          palette,
          label: _dueDateFilter == null
              ? 'Due date'
              : 'Due ${_formatDate(_dueDateFilter!)}',
          icon: Icons.date_range_outlined,
          selected: _dueDateFilter != null,
          onTap: () => pickDate(isDueDate: true),
          onClear: () => setState(() => _dueDateFilter = null),
        ),
        if (_hasActiveFilters)
          TextButton.icon(
            onPressed: () {
              _addressCtrl.clear();
              setState(() {
                _addressQuery = '';
                _statusFilter = 'active';
                _yearFilter = 'all';
                _dateAddedFilter = null;
                _dueDateFilter = null;
              });
            },
            icon: const Icon(Icons.restart_alt_rounded, size: 17),
            label: const Text('Clear filters'),
          ),
      ],
    );
  }

  String _statusLabel(String value) {
    switch (value) {
      case 'delayed':
        return 'Delayed';
      case 'paid':
        return 'Paid';
      case 'completed':
        return 'Completed';
      case 'all':
        return 'All statuses';
      default:
        return 'Active';
    }
  }

  Widget _filterDropdown(
    ThemeData theme,
    AppPalette palette, {
    required String value,
    required String label,
    required IconData icon,
    required List<(String, String)> items,
    required ValueChanged<String> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: palette.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isDense: true,
          borderRadius: BorderRadius.circular(10),
          items: [
            for (final (itemValue, itemLabel) in items)
              DropdownMenuItem(
                value: itemValue,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 15, color: palette.muted),
                    const SizedBox(width: 6),
                    Text(itemLabel, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
          ],
          onChanged: (selected) {
            if (selected != null) onChanged(selected);
          },
        ),
      ),
    );
  }

  Widget _filterDateChip(
    ThemeData theme,
    AppPalette palette, {
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
    required VoidCallback onClear,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 2, 4, 2),
      decoration: BoxDecoration(
        color: selected ? palette.brandSoft : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: selected
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.4)
              : palette.border,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 9),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 15,
                    color: selected
                        ? Theme.of(context).colorScheme.primary
                        : palette.muted,
                  ),
                  const SizedBox(width: 6),
                  Text(label, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
          ),
          if (selected)
            IconButton(
              tooltip: 'Clear',
              icon: const Icon(Icons.close_rounded, size: 15),
              onPressed: onClear,
            ),
        ],
      ),
    );
  }

  Widget _buildBody(List<Customer> customers) {
    if (widget.store.isLoading && widget.store.allCustomers.isEmpty) {
      return const Card(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (widget.store.error != null && widget.store.allCustomers.isEmpty) {
      return Card(
        child: EmptyState(
          icon: Icons.cloud_off_rounded,
          title: 'Could not load customers',
          message: widget.store.error!,
          action: TextButton.icon(
            onPressed: () => widget.store.reload(),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Try again'),
          ),
        ),
      );
    }

    if (customers.isEmpty) {
      return Card(
        child: EmptyState(
          icon: Icons.groups_2_outlined,
          title: _searchQuery.isEmpty ? 'No customers yet' : 'No matches found',
          message: _searchQuery.isEmpty
              ? 'Add your first client to start monitoring accounts, packages, and payments.'
              : 'No active account matches "$_searchQuery". Try a different name, contact, or ID.',
          action: _searchQuery.isNotEmpty
              ? TextButton.icon(
                  onPressed: () {
                    _searchCtrl.clear();
                    setState(() => _searchQuery = '');
                  },
                  icon: const Icon(Icons.restart_alt_rounded, size: 18),
                  label: const Text('Clear search'),
                )
              : null,
        ),
      );
    }

    return _buildTable(customers);
  }

  Widget _buildTable(List<Customer> customers) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final palette = AppPalette.of(context);

    return Card(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: scheme.primary.withValues(alpha: 0.09),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Icon(
                        Icons.table_rows_rounded,
                        size: 17,
                        color: scheme.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        'Active Accounts',
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
                        '${customers.length}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: palette.muted,
                          fontSize: 10.5,
                        ),
                      ),
                    ),
                    if (constraints.maxWidth >= 420) ...[
                      const Spacer(),
                    ],
                  ],
                );
              },
            ),
          ),
          Divider(height: 1, color: palette.border),
          Expanded(
            child: SingleChildScrollView(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: DataTable(
                  columnSpacing: 14,
                  horizontalMargin: 12,
                  sortColumnIndex: _sortColumnIndex,
                  sortAscending: _sortAscending,
                  showCheckboxColumn: false,
                  columns: [
                    DataColumn(
                      label: const Text('DATE ADDED'),
                      onSort: _onSort,
                    ),
                    const DataColumn(label: Text('CUSTOMER')),
                    const DataColumn(label: Text('ADDRESS')),
                    const DataColumn(label: Text('CONTACT')),
                    const DataColumn(label: Text('PACKAGE')),
                    DataColumn(
                      label: const Text('COST'),
                      numeric: true,
                      onSort: _onSort,
                    ),
                    DataColumn(
                      label: const Text('PAID'),
                      numeric: true,
                      onSort: _onSort,
                    ),
                    DataColumn(
                      label: const Text('BALANCE'),
                      numeric: true,
                      onSort: _onSort,
                    ),
                    DataColumn(label: const Text('STATUS'), onSort: _onSort),
                    const DataColumn(label: Text('REMARKS')),
                    DataColumn(label: const Text('DUE DATE'), onSort: _onSort),
                    const DataColumn(label: Text('DAYS LEFT')),
                  ],
                  rows: [
                    for (var index = 0; index < customers.length; index++)
                      _buildRow(customers[index], index),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  DataRow _buildRow(Customer c, int index) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final palette = AppPalette.of(context);
    final zebra = palette.surfaceAlt.withValues(alpha: 0.42);

    return DataRow(
      color: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.hovered)) {
          return scheme.primary.withValues(alpha: 0.055);
        }
        return index.isEven ? null : zebra;
      }),
      onSelectChanged: (_) => _openProfile(c),
      cells: [
        DataCell(
          Text(
            _formatDate(c.dateAdded),
            style: TextStyle(color: palette.muted, fontSize: 12),
          ),
        ),
        DataCell(
          InkWell(
            onTap: () => _openProfile(c),
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
              child: Text(
                c.name,
                style: TextStyle(
                  color: scheme.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ),
        DataCell(
          SizedBox(
            width: 170,
            child: Text(
              c.address,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: palette.muted, fontSize: 12),
            ),
          ),
        ),
        DataCell(
          Text(
            c.contactNumber,
            style: TextStyle(color: palette.muted, fontSize: 12),
          ),
        ),
        DataCell(
          SizedBox(
            width: 140,
            child: Text(
              c.package,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: scheme.onSurface.withValues(alpha: 0.85),
                fontSize: 12,
              ),
            ),
          ),
        ),
        DataCell(
          Text(
            '₱${_f(c.totalPackageCost)}',
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
          ),
        ),
        DataCell(
          Text(
            '₱${_f(c.amountPaid)}',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 13,
              color: c.amountPaid > 0 ? palette.success : palette.muted,
            ),
          ),
        ),
        DataCell(
          Text(
            '₱${_f(c.remainingBalance)}',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: c.remainingBalance > 0 ? palette.danger : palette.success,
            ),
          ),
        ),
        DataCell(
          SizedBox(
            width: 130,
            child: Align(
              alignment: Alignment.centerLeft,
              child: StatusBadge(status: c.paymentStatus),
            ),
          ),
        ),
        DataCell(
          SizedBox(
            width: 100,
            child: Text(
              c.remarks.isEmpty ? '\u2014' : c.remarks,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: palette.muted, fontSize: 12),
            ),
          ),
        ),
        DataCell(
          Text(
            _formatDate(c.dueDate),
            style: TextStyle(color: palette.muted, fontSize: 12),
          ),
        ),
        DataCell(_daysBadge(c.daysRemaining)),
      ],
    );
  }

  void _openProfile(Customer c) {
    context.push('/customer/${c.id}');
  }

  Widget _daysBadge(int days) {
    final palette = AppPalette.of(context);
    Color color;
    String text;
    if (days < 0) {
      color = palette.danger;
      text = '${days.abs()}d overdue';
    } else if (days <= 7) {
      color = palette.warning;
      text = '$days days';
    } else {
      color = palette.success;
      text = '$days days';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _f(double v) => v.toStringAsFixed(2);

  String _formatDate(DateTime date) {
    final months = [
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
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
