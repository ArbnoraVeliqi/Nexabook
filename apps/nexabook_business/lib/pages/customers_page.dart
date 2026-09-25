
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api_client.dart';
import '../widgets/page_header.dart';

class CustomersPage extends StatefulWidget {
  const CustomersPage({super.key});

  @override
  State<CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends State<CustomersPage> {
  final TextEditingController _searchController = TextEditingController();

  bool _initialized = false;
  bool _loading = true;

  List<dynamic> _customers = [];

  String _search = '';
  String _filter = 'All';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_initialized) {
      _initialized = true;
      _loadCustomers();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomers() async {
    setState(() {
      _loading = true;
    });

    try {
      final result = await context.read<ApiClient>().get('/customers');

      if (!mounted) {
        return;
      }

      setState(() {
        _customers = result is List
            ? List<dynamic>.from(result)
            : [];

        _loading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
      });

      _showMessage(
        'Could not load customers.',
        error: true,
      );
    }
  }

  List<dynamic> get _filteredCustomers {
    return _customers.where((customer) {
      final firstName =
          customer['firstName']?.toString().toLowerCase() ?? '';

      final lastName =
          customer['lastName']?.toString().toLowerCase() ?? '';

      final email =
          customer['email']?.toString().toLowerCase() ?? '';

      final phone =
          customer['phone']?.toString().toLowerCase() ?? '';

      final query = _search.trim().toLowerCase();

      final matchesSearch = query.isEmpty ||
          firstName.contains(query) ||
          lastName.contains(query) ||
          email.contains(query) ||
          phone.contains(query) ||
          '$firstName $lastName'.contains(query);

      final active = _isActive(customer);

      final matchesFilter = switch (_filter) {
        'Active' => active,
        'Inactive' => !active,
        _ => true,
      };

      return matchesSearch && matchesFilter;
    }).toList();
  }

  int get _activeCustomers {
    return _customers.where(_isActive).length;
  }

  int get _inactiveCustomers {
    return _customers.length - _activeCustomers;
  }

  bool _isActive(dynamic customer) {
    if (customer['isActive'] != null) {
      return customer['isActive'] == true;
    }

    final status = customer['status']?.toString().toLowerCase();

    if (status == 'inactive' ||
        status == 'disabled' ||
        status == 'blocked') {
      return false;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    final customers = _filteredCustomers;

    return RefreshIndicator(
      onRefresh: _loadCustomers,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(28),
        children: [
          PageHeader(
            'Customers',
            'Manage customer profiles, contact details and booking activity',
            action: FilledButton.icon(
              onPressed: _showCreateCustomerDialog,
              icon: const Icon(
                Icons.person_add_alt_1_rounded,
                size: 19,
              ),
              label: const Text('Add customer'),
            ),
          ),

          const SizedBox(height: 26),

          _buildSummary(),

          const SizedBox(height: 22),

          _buildToolbar(),

          const SizedBox(height: 16),

          if (_loading)
            _buildLoading()
          else if (customers.isEmpty)
            _buildEmptyState()
          else
            _buildCustomerList(customers),
        ],
      ),
    );
  }

  Widget _buildSummary() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        double itemWidth;

        if (width >= 1000) {
          itemWidth = (width - 32) / 3;
        } else if (width >= 650) {
          itemWidth = (width - 16) / 2;
        } else {
          itemWidth = width;
        }

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _summaryCard(
              width: itemWidth,
              title: 'Total customers',
              value: '${_customers.length}',
              icon: Icons.groups_2_outlined,
            ),
            _summaryCard(
              width: itemWidth,
              title: 'Active customers',
              value: '$_activeCustomers',
              icon: Icons.verified_user_outlined,
            ),
            _summaryCard(
              width: itemWidth,
              title: 'Inactive customers',
              value: '$_inactiveCustomers',
              icon: Icons.person_off_outlined,
            ),
          ],
        );
      },
    );
  }

  Widget _summaryCard({
    required double width,
    required String title,
    required String value,
    required IconData icon,
  }) {
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFFE9EAF0),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFFF0EFFF),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF6C63FF),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF77798A),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE9EAF0),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 700;

          final search = TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() {
                _search = value;
              });
            },
            decoration: InputDecoration(
              hintText: 'Search name, email or phone...',
              prefixIcon: const Icon(
                Icons.search_rounded,
              ),
              suffixIcon: _search.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear',
                      onPressed: () {
                        _searchController.clear();

                        setState(() {
                          _search = '';
                        });
                      },
                      icon: const Icon(
                        Icons.close_rounded,
                      ),
                    ),
              filled: true,
              fillColor: const Color(0xFFF8F9FC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 15,
              ),
            ),
          );

          final filters = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _filterButton('All'),
              const SizedBox(width: 7),
              _filterButton('Active'),
              const SizedBox(width: 7),
              _filterButton('Inactive'),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Refresh',
                onPressed: _loadCustomers,
                icon: const Icon(
                  Icons.refresh_rounded,
                ),
              ),
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                search,
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: filters,
                ),
              ],
            );
          }

          return Row(
            children: [
              Expanded(
                child: search,
              ),
              const SizedBox(width: 16),
              filters,
            ],
          );
        },
      ),
    );
  }

  Widget _filterButton(String value) {
    final selected = _filter == value;

    return InkWell(
      borderRadius: BorderRadius.circular(11),
      onTap: () {
        setState(() {
          _filter = value;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 11,
        ),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF6C63FF)
              : const Color(0xFFF8F9FC),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Text(
          value,
          style: TextStyle(
            color: selected
                ? Colors.white
                : const Color(0xFF555766),
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE9EAF0),
        ),
      ),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 70,
        horizontal: 24,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE9EAF0),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 66,
            height: 66,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F2FF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.people_outline_rounded,
              size: 30,
              color: Color(0xFF6C63FF),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'No customers found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'Try changing your search or add a new customer.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF77798A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerList(List<dynamic> customers) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE9EAF0),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _buildTableHeader(),

          for (int index = 0;
              index < customers.length;
              index++) ...[
            _customerRow(customers[index]),
            if (index != customers.length - 1)
              const Divider(
                height: 1,
                indent: 20,
                endIndent: 20,
              ),
          ],

          _buildTableFooter(customers.length),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 14,
      ),
      color: const Color(0xFFF8F9FC),
      child: const Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              'CUSTOMER',
              style: _headerStyle,
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              'CONTACT',
              style: _headerStyle,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'STATUS',
              style: _headerStyle,
            ),
          ),
          SizedBox(
            width: 50,
          ),
        ],
      ),
    );
  }

  Widget _customerRow(dynamic customer) {
    final firstName =
        customer['firstName']?.toString().trim() ?? '';

    final lastName =
        customer['lastName']?.toString().trim() ?? '';

    final fullName = '$firstName $lastName'.trim();

    final email =
        customer['email']?.toString().trim() ?? '';

    final phone =
        customer['phone']?.toString().trim() ?? '';

    final active = _isActive(customer);

    return InkWell(
      onTap: () {
        _showCustomerDetails(customer);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 17,
        ),
        child: Row(
          children: [
            Expanded(
              flex: 4,
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _avatarColor(fullName),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _initials(fullName),
                      style: const TextStyle(
                        color: Color(0xFF5F57D9),
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          fullName.isEmpty
                              ? 'Unnamed customer'
                              : fullName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _customerReference(customer),
                          style: const TextStyle(
                            color: Color(0xFF9092A1),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.mail_outline_rounded,
                        size: 14,
                        color: Color(0xFF9294A3),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          email.isEmpty ? '—' : email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF5F6170),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(
                        Icons.phone_outlined,
                        size: 14,
                        color: Color(0xFF9294A3),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        phone.isEmpty ? '—' : phone,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF5F6170),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: _statusBadge(active),
              ),
            ),

            SizedBox(
              width: 50,
              child: PopupMenuButton<String>(
                tooltip: 'Actions',
                icon: const Icon(
                  Icons.more_horiz_rounded,
                ),
                onSelected: (value) {
                  if (value == 'details') {
                    _showCustomerDetails(customer);
                  } else if (value == 'edit') {
                    _showEditCustomerDialog(customer);
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'details',
                    child: Row(
                      children: [
                        Icon(
                          Icons.visibility_outlined,
                          size: 19,
                        ),
                        SizedBox(width: 10),
                        Text('View details'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(
                          Icons.edit_outlined,
                          size: 19,
                        ),
                        SizedBox(width: 10),
                        Text('Edit customer'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableFooter(int count) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 13,
      ),
      color: const Color(0xFFFBFBFD),
      child: Text(
        '$count ${count == 1 ? 'customer' : 'customers'} shown',
        style: const TextStyle(
          color: Color(0xFF77798A),
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _statusBadge(bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: active
            ? const Color(0xFFEAF8F0)
            : const Color(0xFFF1F1F4),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: active
                  ? const Color(0xFF279466)
                  : const Color(0xFF858795),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            active ? 'Active' : 'Inactive',
            style: TextStyle(
              color: active
                  ? const Color(0xFF237C57)
                  : const Color(0xFF676976),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showCreateCustomerDialog() async {
    final created = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _CustomerFormDialog(),
    );

    if (created == true) {
      await _loadCustomers();

      if (!mounted) {
        return;
      }

      _showMessage('Customer created successfully.');
    }
  }

  Future<void> _showEditCustomerDialog(
    dynamic customer,
  ) async {
    final updated = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _CustomerFormDialog(
        customer: customer,
      ),
    );

    if (updated == true) {
      await _loadCustomers();

      if (!mounted) {
        return;
      }

      _showMessage('Customer updated successfully.');
    }
  }

  void _showCustomerDetails(dynamic customer) {
    final firstName =
        customer['firstName']?.toString() ?? '';

    final lastName =
        customer['lastName']?.toString() ?? '';

    final fullName = '$firstName $lastName'.trim();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.all(24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 560,
            ),
            child: Padding(
              padding: const EdgeInsets.all(26),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: _avatarColor(fullName),
                          borderRadius:
                              BorderRadius.circular(16),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          _initials(fullName),
                          style: const TextStyle(
                            color: Color(0xFF5F57D9),
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              fullName.isEmpty
                                  ? 'Customer'
                                  : fullName,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              _customerReference(customer),
                              style: const TextStyle(
                                color: Color(0xFF858795),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          Navigator.pop(dialogContext);
                        },
                        icon: const Icon(
                          Icons.close_rounded,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 26),

                  const Divider(),

                  const SizedBox(height: 18),

                  _detailRow(
                    Icons.mail_outline_rounded,
                    'Email',
                    customer['email']?.toString(),
                  ),
                  _detailRow(
                    Icons.phone_outlined,
                    'Phone',
                    customer['phone']?.toString(),
                  ),
                  _detailRow(
                    Icons.notes_rounded,
                    'Notes',
                    customer['notes']?.toString(),
                  ),

                  const SizedBox(height: 22),

                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: () {
                          Navigator.pop(dialogContext);

                          _showEditCustomerDialog(
                            customer,
                          );
                        },
                        child: const Text('Edit customer'),
                      ),
                      const SizedBox(width: 10),
                      FilledButton(
                        onPressed: () {
                          Navigator.pop(dialogContext);
                        },
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _detailRow(
    IconData icon,
    String label,
    String? value,
  ) {
    final displayValue =
        value == null || value.trim().isEmpty
            ? '—'
            : value.trim();

    return Padding(
      padding: const EdgeInsets.only(bottom: 17),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F8),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              icon,
              size: 18,
              color: const Color(0xFF77798A),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF8A8C9A),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  displayValue,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _customerReference(dynamic customer) {
    final id = customer['id'];

    if (id == null) {
      return 'Customer';
    }

    return 'Customer #${id.toString().padLeft(4, '0')}';
  }

  String _initials(String name) {
    final parts = name
        .trim()
        .split(' ')
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.isEmpty) {
      return 'C';
    }

    if (parts.length == 1) {
      return parts.first[0].toUpperCase();
    }

    return '${parts.first[0]}${parts.last[0]}'
        .toUpperCase();
  }

  Color _avatarColor(String name) {
    final colors = [
      const Color(0xFFF0EFFF),
      const Color(0xFFEAF6FF),
      const Color(0xFFEAF8F0),
      const Color(0xFFFFF4E8),
      const Color(0xFFFFEDF3),
    ];

    final index =
        name.hashCode.abs() % colors.length;

    return colors[index];
  }

  void _showMessage(
    String message, {
    bool error = false,
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: error
              ? const Color(0xFFD94343)
              : const Color(0xFF292B38),
          content: Text(message),
        ),
      );
  }
}

class _CustomerFormDialog extends StatefulWidget {
  final dynamic customer;

  const _CustomerFormDialog({
    this.customer,
  });

  @override
  State<_CustomerFormDialog> createState() =>
      _CustomerFormDialogState();
}

class _CustomerFormDialogState
    extends State<_CustomerFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  late final TextEditingController _notes;

  bool _saving = false;

  bool get _editing => widget.customer != null;

  @override
  void initState() {
    super.initState();

    _firstName = TextEditingController(
      text: widget.customer?['firstName']
              ?.toString() ??
          '',
    );

    _lastName = TextEditingController(
      text: widget.customer?['lastName']
              ?.toString() ??
          '',
    );

    _email = TextEditingController(
      text: widget.customer?['email']?.toString() ??
          '',
    );

    _phone = TextEditingController(
      text: widget.customer?['phone']?.toString() ??
          '',
    );

    _notes = TextEditingController(
      text: widget.customer?['notes']?.toString() ??
          '',
    );
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _phone.dispose();
    _notes.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 620,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 45,
                      height: 45,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0EFFF),
                        borderRadius:
                            BorderRadius.circular(13),
                      ),
                      child: const Icon(
                        Icons.person_outline_rounded,
                        color: Color(0xFF6C63FF),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            _editing
                                ? 'Edit customer'
                                : 'New customer',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight:
                                  FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _editing
                                ? 'Update customer information'
                                : 'Add a new customer profile',
                            style: const TextStyle(
                              color:
                                  Color(0xFF858795),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _saving
                          ? null
                          : () {
                              Navigator.pop(context);
                            },
                      icon: const Icon(
                        Icons.close_rounded,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                LayoutBuilder(
                  builder: (context, constraints) {
                    final stacked =
                        constraints.maxWidth < 500;

                    if (stacked) {
                      return Column(
                        children: [
                          _firstNameField(),
                          const SizedBox(height: 15),
                          _lastNameField(),
                        ],
                      );
                    }

                    return Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _firstNameField(),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _lastNameField(),
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 15),

                _field(
                  controller: _email,
                  label: 'Email',
                  hint: 'customer@example.com',
                  icon: Icons.mail_outline_rounded,
                  keyboardType:
                      TextInputType.emailAddress,
                ),

                const SizedBox(height: 15),

                _field(
                  controller: _phone,
                  label: 'Phone',
                  hint: '+383...',
                  icon: Icons.phone_outlined,
                  keyboardType:
                      TextInputType.phone,
                ),

                const SizedBox(height: 15),

                _field(
                  controller: _notes,
                  label: 'Notes',
                  hint:
                      'Preferences, important information...',
                  icon: Icons.notes_rounded,
                  maxLines: 4,
                ),

                const SizedBox(height: 26),

                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _saving
                          ? null
                          : () {
                              Navigator.pop(context);
                            },
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 10),
                    FilledButton.icon(
                      onPressed:
                          _saving ? null : _save,
                      icon: _saving
                          ? const SizedBox(
                              width: 17,
                              height: 17,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Icon(
                              _editing
                                  ? Icons
                                      .check_rounded
                                  : Icons
                                      .add_rounded,
                            ),
                      label: Text(
                        _saving
                            ? 'Saving...'
                            : _editing
                                ? 'Save changes'
                                : 'Create customer',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _firstNameField() {
    return _field(
      controller: _firstName,
      label: 'First name',
      hint: 'First name',
      icon: Icons.person_outline_rounded,
      required: true,
    );
  }

  Widget _lastNameField() {
    return _field(
      controller: _lastName,
      label: 'Last name',
      hint: 'Last name',
      icon: Icons.person_outline_rounded,
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    bool required = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: required
          ? (value) {
              if (value == null ||
                  value.trim().isEmpty) {
                return '$label is required';
              }

              return null;
            }
          : null,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: maxLines == 1
            ? Icon(
                icon,
                size: 19,
              )
            : null,
        alignLabelWithHint: maxLines > 1,
        filled: true,
        fillColor: const Color(0xFFF8F9FC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(
            color: Color(0xFFE6E7EC),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(
            color: Color(0xFFE6E7EC),
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final api = context.read<ApiClient>();

      final data = {
        'firstName': _firstName.text.trim(),
        'lastName': _lastName.text.trim(),
        'email': _emptyToNull(_email.text),
        'phone': _emptyToNull(_phone.text),
        'notes': _emptyToNull(_notes.text),
      };

      if (_editing) {
        final id = widget.customer['id'];

        await api.put(
          '/customers/$id',
          data: data,
        );
      } else {
        await api.post(
          '/customers',
          data: data,
        );
      }

      if (!mounted) {
        return;
      }

      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _saving = false;
      });

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: Color(0xFFD94343),
            content: Text(
              'Could not save customer.',
            ),
          ),
        );
    }
  }

  String? _emptyToNull(String value) {
    final text = value.trim();

    return text.isEmpty ? null : text;
  }
}

const TextStyle _headerStyle = TextStyle(
  color: Color(0xFF858795),
  fontSize: 10,
  fontWeight: FontWeight.w700,
  letterSpacing: 0.6,
);