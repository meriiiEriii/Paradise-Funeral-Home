import '../utils/formatters.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/customer.dart';
import '../models/customer_draft.dart';
import '../models/package_template.dart';
import '../data/app_preferences.dart';
import '../data/customer_store.dart';
import '../theme/app_theme.dart';
import '../utils/back_handlers.dart';
import '../utils/validators.dart' show capitalizeWords, validateContactNumber;
import '../utils/formatters.dart' show capitalizeSentences, formatPeso;
import '../widgets/package_editor_dialog.dart';
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
  final bool isAdmin;
  final AppPreferences? preferences;
  final String draftId;
  final VoidCallback? onBack;

  const AddCustomerScreen({
    super.key,
    required this.store,
    this.isAdmin = true,
    this.preferences,
    this.draftId = '',
    this.onBack,
  });

  @override
  State<AddCustomerScreen> createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends State<AddCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _middleNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _suffixCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();
  final _remarksCtrl = TextEditingController();
  final _packageNameCtrl = TextEditingController();
  final _items = <_ItemEntry>[];
  DateTime _dateStarted = DateTime.now();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 10));
  bool _isSubmitting = false;
  String _selectedTemplateId = '';
  String _draftId = '';

  /// "Juan", "Reyes", "Dela", "Jr." -> "Juan Reyes Dela Jr."
  String get _fullName {
    String part(String raw) {
      final trimmed = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
      if (trimmed.isEmpty) return '';
      return trimmed
          .split(' ')
          .map(
            (word) => word.isEmpty
                ? word
                : word[0].toUpperCase() + word.substring(1).toLowerCase(),
          )
          .join(' ');
    }

    final suffix = _suffixCtrl.text.trim().replaceAll(RegExp(r'\s+'), ' ');
    return [
      part(_firstNameCtrl.text),
      part(_middleNameCtrl.text),
      part(_lastNameCtrl.text),
      suffix.isEmpty ? '' : suffix.toUpperCase(),
    ].where((value) => value.isNotEmpty).join(' ');
  }

  /// Real-time capitalization: `textCapitalization` is ignored by desktop
  /// keyboards, so the first letter of every word is uppercased in code as
  /// the user types.
  void _autoCapitalize(
    TextEditingController controller, {
    bool allCaps = false,
  }) {
    final raw = controller.text;
    final formatted = allCaps ? raw.toUpperCase() : capitalizeWords(raw);
    if (formatted == raw) return;
    controller.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  @override
  void initState() {
    super.initState();
    widget.store.addListener(_onStoreChanged);
    _items.add(_ItemEntry());
    _loadDraft();
    routeBackHandlers['add'] = _handleBack;
  }

  void _loadDraft() {
    if (widget.draftId.isEmpty || widget.preferences == null) return;
    final draft = widget.preferences
        ?.loadDrafts()
        .where((d) => d.id == widget.draftId)
        .first;
    if (draft == null) return;
    _draftId = draft.id;
    _firstNameCtrl.text = draft.firstName;
    _middleNameCtrl.text = draft.middleName;
    _lastNameCtrl.text = draft.lastName;
    _suffixCtrl.text = draft.suffix;
    _addressCtrl.text = draft.address;
    _contactCtrl.text = draft.contactNumber;
    _remarksCtrl.text = draft.remarks;
    _packageNameCtrl.text = draft.packageName;
    _dueDate = draft.dueDate;
    for (final item in _items) {
      item.dispose();
    }
    _items
      ..clear()
      ..addAll(
        draft.items
            .map(
              (item) => _ItemEntry(
                name: item.name,
                amount: item.amount.toStringAsFixed(2),
              ),
            ),
      );
    if (_items.isEmpty) _items.add(_ItemEntry());
  }

  bool get _hasInput =>
      _firstNameCtrl.text.trim().isNotEmpty ||
      _middleNameCtrl.text.trim().isNotEmpty ||
      _lastNameCtrl.text.trim().isNotEmpty ||
      _suffixCtrl.text.trim().isNotEmpty ||
      _addressCtrl.text.trim().isNotEmpty ||
      _contactCtrl.text.trim().isNotEmpty ||
      _remarksCtrl.text.trim().isNotEmpty ||
      _packageNameCtrl.text.trim().isNotEmpty ||
      _items.any(
        (item) =>
            item.nameCtrl.text.trim().isNotEmpty ||
            item.amountCtrl.text.trim().isNotEmpty,
      );

  /// Intercepted back press: offer to save the unfinished form as a draft.
  Future<bool> _handleBack() async {
    if (!_hasInput) return false;
    final choice = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(
          Icons.inventory_2_outlined,
          color: Theme.of(context).colorScheme.primary,
          size: 26,
        ),
        title: const Text('Save this draft?'),
        content: const Text(
          'Do you want to cancel this customer? You can save the '
          'unfinished information to Drafts and finalize it later.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop('discard'),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop('draft'),
            icon: const Icon(Icons.inventory_outlined, size: 17),
            label: const Text('Save to Drafts'),
          ),
        ],
      ),
    );
    if (!mounted) return true;
    if (choice == 'draft') {
      await _saveDraft();
      if (!mounted) return true;
      context.go('/dashboard');
      return true;
    }
    // Discarded: clean up the draft being edited, continue default back-nav.
    if (_draftId.isNotEmpty) {
      await widget.preferences?.deleteDraft(_draftId);
    }
    return false;
  }

  Future<void> _saveDraft() async {
    final preferences = widget.preferences;
    if (preferences == null) return;
    final draft = CustomerDraft(
      id: _draftId.isEmpty
          ? 'D${DateTime.now().millisecondsSinceEpoch}'
          : _draftId,
      firstName: _firstNameCtrl.text,
      middleName: _middleNameCtrl.text,
      lastName: _lastNameCtrl.text,
      suffix: _suffixCtrl.text,
      address: _addressCtrl.text,
      contactNumber: _contactCtrl.text,
      remarks: _remarksCtrl.text,
      packageName: _packageNameCtrl.text,
      items: _items
          .map(
            (item) => PackageItem(
              name: item.nameCtrl.text,
              amount: double.tryParse(item.amountCtrl.text) ?? 0,
            ),
          )
          .toList(),
      dueDate: _dueDate,
      savedAt: DateTime.now(),
    );
    await preferences.upsertDraft(draft);
  }

  void _onStoreChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    routeBackHandlers.remove('add');
    widget.store.removeListener(_onStoreChanged);
    _firstNameCtrl.dispose();
    _middleNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _suffixCtrl.dispose();
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

  String get _normalizedContact =>
      _contactCtrl.text.trim().replaceAll(RegExp(r'\D'), '');

  void _selectTemplate(String templateId) {
    setState(() {
      _selectedTemplateId = templateId;
      if (templateId.isEmpty) return;
      final template = widget.store.getPackageTemplateById(templateId);
      if (template == null) return;
      _packageNameCtrl.text = template.name;
      for (final item in _items) {
        item.dispose();
      }
      _items
        ..clear()
        ..addAll(
          template.items
              .map(
                (item) => _ItemEntry(
                  name: item.name,
                  amount: item.amount.toStringAsFixed(2),
                ),
              ),
        );
      if (_items.isEmpty) _items.add(_ItemEntry());
    });
  }

  Future<void> _createPackage() async {
    final saved = await showPackageEditorDialog(
      context,
      store: widget.store,
    );
    if (saved == null || !mounted) return;
    _selectTemplate(saved.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Package "${saved.name}" created.')),
    );
  }

  Future<void> _editSelectedPackage() async {
    final template = widget.store.getPackageTemplateById(
      _selectedTemplateId,
    );
    if (template == null) return;
    final saved = await showPackageEditorDialog(
      context,
      store: widget.store,
      existing: template,
    );
    if (saved == null || !mounted) return;
    if (widget.store.getPackageTemplateById(saved.id) == null) {
      // The template was deleted.
      setState(() {
        _selectedTemplateId = '';
        _packageNameCtrl.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Package "${template.name}" deleted.')),
      );
      return;
    }
    _selectTemplate(saved.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Package "${saved.name}" updated.')),
    );
  }

  /// Capitalizes the first letter of every word ("juan dela cruz" ->
  /// "Juan Dela Cruz").
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
        name: _titleCase(e.nameCtrl.text),
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
      name: _fullName,
      address: _titleCase(_addressCtrl.text),
      contactNumber: _normalizedContact,
      package: _packageNameCtrl.text.trim().isEmpty
          ? 'Custom Package'
          : _titleCase(_packageNameCtrl.text),
      items: packageItems,
      amountPaid: 0.0,
      remarks: capitalizeSentences(_remarksCtrl.text),
      dueDate: _dueDate,
    );

    try {
      final created = await widget.store.addCustomer(customer);
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      if (_draftId.isNotEmpty) {
        await widget.preferences?.deleteDraft(_draftId);
      }
      if (!mounted) return;
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
          Row(
            children: [
              Expanded(
                child: _buildField(
                  'First Name',
                  _firstNameCtrl,
                  Icons.person_outline_rounded,
                  textCapitalization: TextCapitalization.words,
                  onChanged: (_) => _autoCapitalize(_firstNameCtrl),
                  validator: (v) =>
                      (v?.trim().isEmpty ?? true) ? 'Required' : null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildField(
                  'Last Name',
                  _lastNameCtrl,
                  Icons.person_outline_rounded,
                  textCapitalization: TextCapitalization.words,
                  onChanged: (_) => _autoCapitalize(_lastNameCtrl),
                  validator: (v) =>
                      (v?.trim().isEmpty ?? true) ? 'Required' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildField(
                  'Middle Name (optional)',
                  _middleNameCtrl,
                  Icons.person_outline_rounded,
                  textCapitalization: TextCapitalization.words,
                  onChanged: (_) => _autoCapitalize(_middleNameCtrl),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildField(
                  'Suffix (optional)',
                  _suffixCtrl,
                  Icons.person_outline_rounded,
                  hint: 'Jr., Sr., II',
                  textCapitalization: TextCapitalization.characters,
                  onChanged: (_) => _autoCapitalize(_suffixCtrl, allCaps: true),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildField(
            'Address',
            _addressCtrl,
            Icons.location_on_outlined,
            maxLines: 2,
            textCapitalization: TextCapitalization.words,
            onChanged: (_) => _autoCapitalize(_addressCtrl),
            validator: (v) =>
                (v?.trim().isEmpty ?? true) ? 'Address is required' : null,
          ),
          const SizedBox(height: 14),
          _buildField(
            'Contact Number',
            _contactCtrl,
            Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            hint: '09171234567',
            validator: (v) => validateContactNumber(v),
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
          formatPeso(_totalCost),
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
          _buildPackageSelector(),
          const SizedBox(height: 16),
          ...List.generate(_items.length, (index) => _buildItemRow(index)),
          const SizedBox(height: 4),
          Row(
            children: [
              if (!_itemsReadOnly)
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

  Widget _buildPackageSelector() {
    final theme = Theme.of(context);
    final palette = AppPalette.of(context);
    final templates = widget.store.packageTemplates;
    PackageTemplate? selected;
    for (final template in templates) {
      if (template.id == _selectedTemplateId) {
        selected = template;
        break;
      }
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: 'Package',
              prefixIcon: const Icon(Icons.sell_outlined, size: 19),
              helperText: widget.isAdmin
                  ? 'Select a pre-made package or enter items manually.'
                  : 'Pre-made packages are managed by the administrator.',
              helperMaxLines: 2,
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedTemplateId,
                isExpanded: true,
                isDense: true,
                hint: const Text('Custom (manual entry)'),
                items: [
                  const DropdownMenuItem(
                    value: '',
                    child: Text('Custom (manual entry)'),
                  ),
                  for (final template in templates)
                    DropdownMenuItem(
                      value: template.id,
                      child: Text(
                        template.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (value) => _selectTemplate(value ?? ''),
              ),
            ),
          ),
        ),
        if (widget.isAdmin) ...[
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: IconButton(
              tooltip: 'New package',
              icon: const Icon(Icons.add_circle_outline_rounded, size: 24),
              color: theme.colorScheme.primary,
              onPressed: _createPackage,
            ),
          ),
          if (selected != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: IconButton(
                tooltip: 'Edit package',
                icon: Icon(
                  Icons.edit_outlined,
                  size: 21,
                  color: palette.muted,
                ),
                onPressed: _editSelectedPackage,
              ),
            ),
        ],
      ],
    );
  }

  /// Staff using a pre-made package cannot edit its items — only admins can.
  bool get _itemsReadOnly => !widget.isAdmin && _selectedTemplateId.isNotEmpty;

  Widget _buildItemRow(int index) {
    final item = _items[index];
    final palette = AppPalette.of(context);
    final readOnly = _itemsReadOnly;

    final nameField = TextFormField(
      controller: item.nameCtrl,
      enabled: !readOnly,
      textCapitalization: TextCapitalization.words,
      onChanged: (_) => _autoCapitalize(item.nameCtrl),
      decoration: const InputDecoration(
        labelText: 'Item name',
        hintText: 'e.g. Installation',
      ),
      validator: (v) => (v?.trim().isEmpty ?? true) ? 'Required' : null,
    );

    final amountField = TextFormField(
      controller: item.amountCtrl,
      enabled: !readOnly,
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

    final removeButton = _items.length > 1 && !readOnly
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
                        formatPeso(_totalCost),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontFamily: 'Lora',
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
    String? hint,
    TextCapitalization textCapitalization = TextCapitalization.none,
    ValueChanged<String>? onChanged,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      onChanged: onChanged,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
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
