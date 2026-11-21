import 'package:flutter/material.dart';

import '../models/customer.dart';
import '../data/customer_store.dart';
import '../theme/app_theme.dart';
import '../widgets/page_header.dart';
import '../widgets/section_card.dart';

class _ItemEntry {
  final TextEditingController nameCtrl;
  final TextEditingController amountCtrl;

  _ItemEntry({String name = '', String amount = ''})
    : nameCtrl = TextEditingController(text: name),
      amountCtrl = TextEditingController(text: amount);

  void dispose() {
    nameCtrl.dispose();
    amountCtrl.dispose();
  }
}

class AddCustomerScreen extends StatefulWidget {
  final CustomerStore store;
  final VoidCallback? onBack;

  const AddCustomerScreen({super.key, required this.store, this.onBack});

  @override
  State<AddCustomerScreen> createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends State<AddCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();
  final _remarksCtrl = TextEditingController();
  final _packageNameCtrl = TextEditingController();
  final _items = <_ItemEntry>[];
  DateTime _dateStarted = DateTime.now();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 30));
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _items.add(_ItemEntry());
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _contactCtrl.dispose();
    _remarksCtrl.dispose();
    _packageNameCtrl.dispose();
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  double get _totalCost {
    double total = 0;
    for (final item in _items) {
      total += double.tryParse(item.amountCtrl.text) ?? 0;
    }
    return total;
  }

  void _addItem() {
    setState(() => _items.add(_ItemEntry()));
  }

  void _removeItem(int index) {
    setState(() {
      _items[index].dispose();
      _items.removeAt(index);
    });
  }

  Future<void> _pickDate(BuildContext context, bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _dateStarted : _dueDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _dateStarted = picked;
        } else {
          _dueDate = picked;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one package item')),
      );
      return;
    }

    final packageItems = _items.map((e) {
      return PackageItem(
        name: e.nameCtrl.text.trim(),
        amount: double.tryParse(e.amountCtrl.text) ?? 0,
      );
    }).toList();

    final invalidItem = packageItems.indexWhere(
      (i) => i.name.isEmpty || i.amount <= 0,
    );
    if (invalidItem != -1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Every item needs a name and valid amount'),
        ),
      );
      return;
    }

    if (_totalCost <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Total package amount must be greater than 0'),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final customer = Customer(
      id: '',
      dateAdded: _dateStarted,
      name: _nameCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
      contactNumber: _contactCtrl.text.trim(),
      package: _packageNameCtrl.text.trim().isEmpty
          ? 'Custom Package'
          : _packageNameCtrl.text.trim(),
      items: packageItems,
      amountPaid: 0.0,
      remarks: _remarksCtrl.text.trim(),
      dueDate: _dueDate,
    );

    try {
      final created = await widget.store.addCustomer(customer);
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Customer ${created.name} added successfully!'),
          backgroundColor: const Color(0xFF2E7D32),
        ),
      );
      widget.onBack?.call();
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1120),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const PageHeader(
                        icon: Icons.person_add_alt_1_rounded,
                        title: 'New Customer',
                        subtitle:
                            'Register a client, build their package, and set the payment schedule.',
                      ),
                      const SizedBox(height: 20),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final wide = constraints.maxWidth >= 920;
                          final left = Column(
                            children: [
                              _buildBasicInfo(),
                              const SizedBox(height: 16),
                              _buildDateInfo(),
                            ],
                          );
                          final right = Column(
                            children: [
                              _buildPackageInfo(),
                              const SizedBox(height: 16),
                              _buildRemarks(),
                            ],
                          );
                          if (!wide) {
                            return Column(
                              children: [
                                left,
                                const SizedBox(height: 16),
                                right,
                              ],
                            );
                          }
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 5, child: left),
                              const SizedBox(width: 18),
                              Expanded(flex: 4, child: right),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        _buildActionBar(),
      ],
    );
  }

  Widget _buildBasicInfo() {
    return SectionCard(
      title: 'Basic Information',
      icon: Icons.badge_outlined,
      child: Column(
        children: [
          _buildField(
            'Full Name',
            _nameCtrl,
            Icons.person_outline_rounded,
            validator: (v) =>
                (v?.trim().isEmpty ?? true) ? 'Name is required' : null,
          ),
          const SizedBox(height: 14),
          _buildField(
            'Address',
            _addressCtrl,
            Icons.location_on_outlined,
            maxLines: 2,
            validator: (v) =>
                (v?.trim().isEmpty ?? true) ? 'Address is required' : null,
          ),
          const SizedBox(height: 14),
          _buildField(
            'Contact Number',
            _contactCtrl,
            Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            validator: (v) => (v?.trim().isEmpty ?? true)
                ? 'Contact number is required'
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildPackageInfo() {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final palette = AppPalette.of(context);

    return SectionCard(
      title: 'Package Items',
      icon: Icons.inventory_2_outlined,
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: palette.brandSoft,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: scheme.primary.withValues(alpha: 0.16)),
        ),
        child: Text(
          '₱${_totalCost.toStringAsFixed(2)}',
          style: theme.textTheme.labelSmall?.copyWith(
            color: scheme.primary,
            fontWeight: FontWeight.w700,
            fontSize: 11,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildField(
            'Package Name (optional)',
            _packageNameCtrl,
            Icons.sell_outlined,
          ),
          const SizedBox(height: 16),
          ...List.generate(_items.length, (index) => _buildItemRow(index)),
          const SizedBox(height: 4),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: _addItem,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add Item'),
              ),
              const SizedBox(width: 8),
              const Spacer(),
              Flexible(
                child: Text(
                  '${_items.length} item${_items.length != 1 ? 's' : ''}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: palette.muted,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildItemRow(int index) {
    final item = _items[index];
    final palette = AppPalette.of(context);

    final nameField = TextFormField(
      controller: item.nameCtrl,
      decoration: const InputDecoration(
        labelText: 'Item name',
        hintText: 'e.g. Installation',
      ),
      validator: (v) => (v?.trim().isEmpty ?? true) ? 'Required' : null,
    );

    final amountField = TextFormField(
      controller: item.amountCtrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: const InputDecoration(labelText: 'Amount', prefixText: '₱ '),
      onChanged: (_) => setState(() {}),
      validator: (v) {
        if (v?.trim().isEmpty ?? true) return 'Required';
        final val = double.tryParse(v!);
        if (val == null || val <= 0) return 'Invalid';
        return null;
      },
    );

    final removeButton = _items.length > 1
        ? IconButton(
            tooltip: 'Remove item',
            icon: Icon(
              Icons.remove_circle_outline_rounded,
              color: palette.danger,
              size: 21,
            ),
            onPressed: () => _removeItem(index),
          )
        : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 380) {
            return Column(
              children: [
                nameField,
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: amountField),
                    if (removeButton != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 4, top: 6),
                        child: removeButton,
                      ),
                  ],
                ),
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: nameField),
              const SizedBox(width: 8),
              Expanded(flex: 2, child: amountField),
              if (removeButton != null)
                Padding(
                  padding: const EdgeInsets.only(left: 4, top: 6),
                  child: removeButton,
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDateInfo() {
    return SectionCard(
      title: 'Schedule',
      icon: Icons.event_note_outlined,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 520;
          final start = _datePickerField('Date Started', _dateStarted, true);
          final due = _datePickerField('Due Date', _dueDate, false);
          if (!wide) {
            return Column(children: [start, const SizedBox(height: 14), due]);
          }
          return Row(
            children: [
              Expanded(child: start),
              const SizedBox(width: 14),
              Expanded(child: due),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRemarks() {
    return SectionCard(
      title: 'Remarks',
      icon: Icons.notes_outlined,
      child: _buildField(
        'Internal notes (optional)',
        _remarksCtrl,
        Icons.edit_note_rounded,
        maxLines: 3,
      ),
    );
  }

  Widget _buildActionBar() {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final palette = AppPalette.of(context);

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(top: BorderSide(color: palette.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1120),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 620;
                  final total = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'PACKAGE TOTAL',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: palette.muted,
                          fontSize: 10,
                          letterSpacing: 1,
                        ),
                      ),
                      Text(
                        '₱${_totalCost.toStringAsFixed(2)}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontFamily: 'Bitter',
                          fontWeight: FontWeight.w700,
                          color: scheme.primary,
                        ),
                      ),
                    ],
                  );

                  final cancel = OutlinedButton(
                    onPressed: widget.onBack,
                    child: const Text('Cancel'),
                  );

                  final submit = ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _submit,
                    icon: _isSubmitting
                        ? SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: scheme.onPrimary,
                            ),
                          )
                        : const Icon(Icons.check_rounded, size: 19),
                    label: Text(_isSubmitting ? 'Saving...' : 'Add Customer'),
                  );

                  if (compact) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(child: total),
                            if (constraints.maxWidth >= 360) ...[
                              const SizedBox(width: 12),
                              Flexible(
                                child: Text(
                                  'Ready to register',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.right,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: palette.muted,
                                    fontSize: 10.5,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(child: cancel),
                            const SizedBox(width: 10),
                            Expanded(child: submit),
                          ],
                        ),
                      ],
                    );
                  }

                  return Row(
                    children: [
                      total,
                      const SizedBox(width: 16),
                      Container(width: 1, height: 30, color: palette.border),
                      const Spacer(),
                      cancel,
                      const SizedBox(width: 10),
                      submit,
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller,
    IconData icon, {
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        alignLabelWithHint: maxLines > 1,
        prefixIcon: Icon(icon, size: 19),
      ),
    );
  }

  Widget _datePickerField(String label, DateTime date, bool isStart) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return InkWell(
      onTap: () => _pickDate(context, isStart),
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.calendar_month_outlined, size: 19),
          suffixIcon: Icon(
            Icons.expand_more_rounded,
            size: 19,
            color: scheme.primary,
          ),
        ),
        child: Text(
          _formatDate(date),
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

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
