import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api_client.dart';
import '../widgets/page_header.dart';

class ServicesPage extends StatefulWidget {
  const ServicesPage({super.key});

  @override
  State<ServicesPage> createState() => _ServicesPageState();
}

class _ServicesPageState extends State<ServicesPage> {
  final TextEditingController _searchController = TextEditingController();

  bool _initialized = false;
  bool _loading = true;

  List<dynamic> _services = [];
  List<dynamic> _categories = [];

  String _search = '';
  String _statusFilter = 'All';
  int? _categoryFilter;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_initialized) {
      _initialized = true;
      _loadData();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (mounted) {
      setState(() {
        _loading = true;
      });
    }

    try {
      final api = context.read<ApiClient>();

      final results = await Future.wait([
        api.get('/catalog/services'),
        api.get('/catalog/categories'),
      ]);

      if (!mounted) {
        return;
      }

      setState(() {
        _services = results[0] is List
            ? List<dynamic>.from(results[0])
            : [];

        _categories = results[1] is List
            ? List<dynamic>.from(results[1])
            : [];

        _loading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
      });

      _showMessage(
        'Could not load services.',
        error: true,
      );
    }
  }

  List<dynamic> get _filteredServices {
    final query = _search.trim().toLowerCase();

    return _services.where((service) {
      final name = _text(service['name']).toLowerCase();
      final description =
          _text(service['description']).toLowerCase();
      final category =
          _categoryName(service).toLowerCase();

      final matchesSearch = query.isEmpty ||
          name.contains(query) ||
          description.contains(query) ||
          category.contains(query);

      final active = _isActive(service);

      final matchesStatus = switch (_statusFilter) {
        'Active' => active,
        'Inactive' => !active,
        _ => true,
      };

      final serviceCategoryId =
          _toInt(service['categoryId']);

      final matchesCategory =
          _categoryFilter == null ||
              serviceCategoryId == _categoryFilter;

      return matchesSearch &&
          matchesStatus &&
          matchesCategory;
    }).toList();
  }

  int get _activeServices {
    return _services.where(_isActive).length;
  }

  int get _depositServices {
    return _services
        .where((service) => _requiresDeposit(service))
        .length;
  }

  double get _averagePrice {
    if (_services.isEmpty) {
      return 0;
    }

    final prices = _services
        .map((service) => _toDouble(service['price']))
        .toList();

    if (prices.isEmpty) {
      return 0;
    }

    return prices.reduce((a, b) => a + b) /
        prices.length;
  }

  bool _isActive(dynamic service) {
    return service['isActive'] != false;
  }

  bool _requiresDeposit(dynamic service) {
    return service['requiresDeposit'] == true;
  }

  String _categoryName(dynamic service) {
    final categoryName = service['categoryName'];

    if (categoryName != null &&
        categoryName.toString().trim().isNotEmpty) {
      return categoryName.toString();
    }

    final category = service['category'];

    if (category is Map &&
        category['name'] != null) {
      return category['name'].toString();
    }

    final categoryId =
        _toInt(service['categoryId']);

    if (categoryId != null) {
      for (final category in _categories) {
        if (_toInt(category['id']) == categoryId) {
          return _text(category['name']);
        }
      }
    }

    return 'Uncategorized';
  }

  @override
  Widget build(BuildContext context) {
    final services = _filteredServices;

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(28),
        children: [
          PageHeader(
            'Services',
            'Manage services, pricing, duration and deposits',
            action: FilledButton.icon(
              onPressed: _showCreateService,
              icon: const Icon(
                Icons.add_rounded,
              ),
              label: const Text('Add service'),
            ),
          ),

       

          // _buildSummary(),

          const SizedBox(height: 22),

          _buildToolbar(),

          const SizedBox(height: 16),

          if (_loading)
            _buildLoading()
          else if (services.isEmpty)
            _buildEmpty()
          else
            _buildServices(services),
        ],
      ),
    );
  }

  Widget _buildSummary() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        double cardWidth;

        if (width >= 1150) {
          cardWidth = (width - 48) / 4;
        } else if (width >= 700) {
          cardWidth = (width - 16) / 2;
        } else {
          cardWidth = width;
        }

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _summaryCard(
              cardWidth,
              'Total services',
              '${_services.length}',
              Icons.design_services_outlined,
              const Color(0xFFF0EFFF),
              const Color(0xFF6C63FF),
            ),
            _summaryCard(
              cardWidth,
              'Active services',
              '$_activeServices',
              Icons.check_circle_outline_rounded,
              const Color(0xFFEAF8F0),
              const Color(0xFF279466),
            ),
            _summaryCard(
              cardWidth,
              'Require deposit',
              '$_depositServices',
              Icons.account_balance_wallet_outlined,
              const Color(0xFFFFF4E8),
              const Color(0xFFE28A36),
            ),
            _summaryCard(
              cardWidth,
              'Average price',
              '€${_averagePrice.toStringAsFixed(2)}',
              Icons.payments_outlined,
              const Color(0xFFEAF6FF),
              const Color(0xFF4389C7),
            ),
          ],
        );
      },
    );
  }

  Widget _summaryCard(
    double width,
    String title,
    String value,
    IconData icon,
    Color background,
    Color iconColor,
  ) {
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
                color: background,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                icon,
                color: iconColor,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF77798A),
                      fontSize: 13,
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
          final compact =
              constraints.maxWidth < 900;

          final search = TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() {
                _search = value;
              });
            },
            decoration: InputDecoration(
              hintText: 'Search services...',
              prefixIcon:
                  const Icon(Icons.search_rounded),
              filled: true,
              fillColor: const Color(0xFFF8F9FC),
              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(13),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(13),
                borderSide: BorderSide.none,
              ),
            ),
          );

          final category =
              DropdownButtonFormField<int?>(
            value: _categoryFilter,
            isExpanded: true,
            decoration: InputDecoration(
              prefixIcon: const Icon(
                Icons.category_outlined,
              ),
              filled: true,
              fillColor: const Color(0xFFF8F9FC),
              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(13),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(13),
                borderSide: BorderSide.none,
              ),
            ),
            items: [
              const DropdownMenuItem<int?>(
                value: null,
                child: Text('All categories'),
              ),
              ..._categories.map(
                (item) {
                  final id = _toInt(item['id']);

                  return DropdownMenuItem<int?>(
                    value: id,
                    child: Text(
                      _text(item['name']),
                    ),
                  );
                },
              ),
            ],
            onChanged: (value) {
              setState(() {
                _categoryFilter = value;
              });
            },
          );

          if (compact) {
            return Column(
              children: [
                search,
                const SizedBox(height: 12),
                category,
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: _statusFilters(),
                ),
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: search),
              const SizedBox(width: 14),
              SizedBox(
                width: 210,
                child: category,
              ),
              const SizedBox(width: 14),
              _statusFilters(),
              const SizedBox(width: 6),
              IconButton(
                tooltip: 'Refresh',
                onPressed: _loadData,
                icon: const Icon(
                  Icons.refresh_rounded,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _statusFilters() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _filterButton('All'),
        const SizedBox(width: 7),
        _filterButton('Active'),
        const SizedBox(width: 7),
        _filterButton('Inactive'),
      ],
    );
  }

  Widget _filterButton(String value) {
    final selected =
        _statusFilter == value;

    return InkWell(
      borderRadius: BorderRadius.circular(11),
      onTap: () {
        setState(() {
          _statusFilter = value;
        });
      },
      child: AnimatedContainer(
        duration:
            const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 11,
        ),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF6C63FF)
              : const Color(0xFFF8F9FC),
          borderRadius:
              BorderRadius.circular(11),
        ),
        child: Text(
          value,
          style: TextStyle(
            color: selected
                ? Colors.white
                : const Color(0xFF555766),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildServices(
    List<dynamic> services,
  ) {
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
          _tableHeader(),

          for (int i = 0;
              i < services.length;
              i++) ...[
            _serviceRow(services[i]),
            if (i != services.length - 1)
              const Divider(
                height: 1,
                indent: 20,
                endIndent: 20,
              ),
          ],

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            color: const Color(0xFFFBFBFD),
            child: Text(
              '${services.length} services shown',
              style: const TextStyle(
                color: Color(0xFF77798A),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tableHeader() {
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
              'SERVICE',
              style: _headerStyle,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'DURATION',
              style: _headerStyle,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'PRICE',
              style: _headerStyle,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'DEPOSIT',
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
          SizedBox(width: 50),
        ],
      ),
    );
  }

  Widget _serviceRow(dynamic service) {
    final name = _text(service['name']);
    final category =
        _categoryName(service);

    final duration =
        _toInt(service['durationMinutes']) ?? 0;

    final price =
        _toDouble(service['price']);

    final deposit =
        _toDouble(service['depositAmount']);

    final requiresDeposit =
        _requiresDeposit(service);

    final active =
        _isActive(service);

    return InkWell(
      onTap: () {
        _showEditService(service);
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
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      color:
                          const Color(0xFFF0EFFF),
                      borderRadius:
                          BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.design_services_outlined,
                      color:
                          Color(0xFF6C63FF),
                      size: 21,
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow:
                              TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight:
                                FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          category,
                          maxLines: 1,
                          overflow:
                              TextOverflow.ellipsis,
                          style: const TextStyle(
                            color:
                                Color(0xFF9092A1),
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
              flex: 2,
              child: Text(
                _formatDuration(duration),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                '€${price.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                requiresDeposit
                    ? '€${deposit.toStringAsFixed(2)}'
                    : 'Not required',
                style: TextStyle(
                  color: requiresDeposit
                      ? const Color(0xFFE28A36)
                      : const Color(0xFF8A8C99),
                  fontWeight:
                      FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Align(
                alignment:
                    Alignment.centerLeft,
                child:
                    _statusBadge(active),
              ),
            ),
            SizedBox(
              width: 50,
              child:
                  PopupMenuButton<String>(
                icon: const Icon(
                  Icons.more_horiz_rounded,
                ),
                onSelected: (value) {
                  if (value == 'edit') {
                    _showEditService(service);
                  }

                  if (value == 'status') {
                    _toggleService(service);
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(
                          Icons.edit_outlined,
                          size: 18,
                        ),
                        SizedBox(width: 10),
                        Text('Edit service'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'status',
                    child: Row(
                      children: [
                        Icon(
                          active
                              ? Icons
                                  .visibility_off_outlined
                              : Icons
                                  .visibility_outlined,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          active
                              ? 'Deactivate'
                              : 'Activate',
                        ),
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
        borderRadius:
            BorderRadius.circular(20),
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

  Widget _buildLoading() {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE9EAF0),
        ),
      ),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildEmpty() {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 70,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE9EAF0),
        ),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.design_services_outlined,
            size: 40,
            color: Color(0xFF6C63FF),
          ),
          SizedBox(height: 15),
          Text(
            'No services found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showCreateService() async {
    final saved =
        await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ServiceFormDialog(
        categories: _categories,
      ),
    );

    if (saved == true) {
      await _loadData();

      if (mounted) {
        _showMessage(
          'Service created successfully.',
        );
      }
    }
  }

  Future<void> _showEditService(
    dynamic service,
  ) async {
    final saved =
        await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ServiceFormDialog(
        categories: _categories,
        service: service,
      ),
    );

    if (saved == true) {
      await _loadData();

      if (mounted) {
        _showMessage(
          'Service updated successfully.',
        );
      }
    }
  }

  Future<void> _toggleService(
    dynamic service,
  ) async {
    final id =
        _toInt(service['id']);

    if (id == null) {
      return;
    }

    try {
      await context
          .read<ApiClient>()
          .put(
        '/catalog/services/$id',
        data: {
          'name':
              _text(service['name']),
          'description':
              _nullableText(
                  service['description']),
          'price':
              _toDouble(service['price']),
          'durationMinutes':
              _toInt(
                    service[
                        'durationMinutes'],
                  ) ??
                  0,
          'categoryId':
              _toInt(
                    service['categoryId'],
                  ) ??
                  0,
          'requiresDeposit':
              _requiresDeposit(service),
          'depositAmount':
              _toDouble(
                  service['depositAmount']),
          'isActive':
              !_isActive(service),
        },
      );

      await _loadData();

      if (mounted) {
        _showMessage(
          _isActive(service)
              ? 'Service deactivated.'
              : 'Service activated.',
        );
      }
    } on DioException catch (e) {
      _showApiError(e);
    }
  }

  String _formatDuration(int minutes) {
    if (minutes <= 0) {
      return '—';
    }

    if (minutes < 60) {
      return '$minutes min';
    }

    final hours = minutes ~/ 60;
    final remaining = minutes % 60;

    if (remaining == 0) {
      return '$hours hr';
    }

    return '${hours}h ${remaining}m';
  }

  void _showApiError(DioException e) {
    if (!mounted) {
      return;
    }

    final response = e.response?.data;

    String message =
        'Something went wrong.';

    if (response is String &&
        response.isNotEmpty) {
      message = response;
    } else if (response is Map) {
      message = response['message']
              ?.toString() ??
          response['title']?.toString() ??
          message;
    }

    _showMessage(
      message,
      error: true,
    );
  }

  void _showMessage(
    String message, {
    bool error = false,
  }) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior:
              SnackBarBehavior.floating,
          backgroundColor: error
              ? const Color(0xFFD94343)
              : const Color(0xFF292B38),
          content: Text(message),
        ),
      );
  }
}

class _ServiceFormDialog
    extends StatefulWidget {
  final List<dynamic> categories;
  final dynamic service;

  const _ServiceFormDialog({
    required this.categories,
    this.service,
  });

  @override
  State<_ServiceFormDialog>
      createState() =>
          _ServiceFormDialogState();
}

class _ServiceFormDialogState
    extends State<_ServiceFormDialog> {
  final _formKey =
      GlobalKey<FormState>();

  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _price;
  late final TextEditingController _duration;
  late final TextEditingController _deposit;

  int? _categoryId;

  bool _requiresDeposit = false;
  bool _isActive = true;
  bool _saving = false;

  bool get _editing =>
      widget.service != null;

  @override
  void initState() {
    super.initState();

    final service = widget.service;

    _name = TextEditingController(
      text: _text(service?['name']),
    );

    _description =
        TextEditingController(
      text:
          _text(service?['description']),
    );

    _price = TextEditingController(
      text: service == null
          ? ''
          : _toDouble(service['price'])
              .toStringAsFixed(2),
    );

    _duration =
        TextEditingController(
      text: service == null
          ? ''
          : (_toInt(
                    service[
                        'durationMinutes'],
                  ) ??
                  '')
              .toString(),
    );

    _deposit =
        TextEditingController(
      text: service == null
          ? ''
          : _toDouble(
                  service['depositAmount'])
              .toStringAsFixed(2),
    );

    _categoryId =
        _toInt(service?['categoryId']);

    _requiresDeposit =
        service?['requiresDeposit'] ==
            true;

    _isActive =
        service?['isActive'] != false;
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _price.dispose();
    _duration.dispose();
    _deposit.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding:
          const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(22),
      ),
      child: ConstrainedBox(
        constraints:
            const BoxConstraints(
          maxWidth: 650,
        ),
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.all(28),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                _header(),

                const SizedBox(height: 28),

                _field(
                  controller: _name,
                  label: 'Service name',
                  hint:
                      'e.g. Haircut',
                  icon: Icons
                      .design_services_outlined,
                  required: true,
                ),

                const SizedBox(height: 16),

                DropdownButtonFormField<int>(
                  value: _categoryId,
                  isExpanded: true,
                  validator: (value) {
                    if (value == null) {
                      return 'Category is required';
                    }

                    return null;
                  },
                  decoration:
                      _inputDecoration(
                    'Category',
                    Icons.category_outlined,
                  ),
                  items: widget.categories
    .where((category) => _toInt(category['id']) != null)
    .map<DropdownMenuItem<int>>((category) {
      final id = _toInt(category['id'])!;

      return DropdownMenuItem<int>(
        value: id,
        child: Text(
          _text(category['name']),
          overflow: TextOverflow.ellipsis,
        ),
      );
    })
    .toList(),
                  onChanged: (value) {
                    setState(() {
                      _categoryId = value;
                    });
                  },
                ),

                const SizedBox(height: 16),

                LayoutBuilder(
                  builder:
                      (context, constraints) {
                    if (constraints.maxWidth <
                        500) {
                      return Column(
                        children: [
                          _priceField(),
                          const SizedBox(
                              height: 16),
                          _durationField(),
                        ],
                      );
                    }

                    return Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child:
                              _priceField(),
                        ),
                        const SizedBox(
                            width: 14),
                        Expanded(
                          child:
                              _durationField(),
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 18),

                _switchTile(
                  title: 'Require deposit',
                  subtitle:
                      'Customer must pay an advance for this service.',
                  value:
                      _requiresDeposit,
                  icon: Icons
                      .account_balance_wallet_outlined,
                  onChanged: (value) {
                    setState(() {
                      _requiresDeposit =
                          value;

                      if (!value) {
                        _deposit.clear();
                      }
                    });
                  },
                ),

                AnimatedSize(
                  duration: const Duration(
                      milliseconds: 180),
                  child: _requiresDeposit
                      ? Padding(
                          padding:
                              const EdgeInsets
                                  .only(
                            top: 16,
                          ),
                          child: _field(
                            controller:
                                _deposit,
                            label:
                                'Deposit amount',
                            hint: '0.00',
                            icon: Icons
                                .payments_outlined,
                            keyboardType:
                                const TextInputType
                                    .numberWithOptions(
                              decimal: true,
                            ),
                            required: true,
                            validator:
                                _depositValidator,
                          ),
                        )
                      : const SizedBox
                          .shrink(),
                ),

                const SizedBox(height: 18),

                _switchTile(
                  title: 'Active service',
                  subtitle: _isActive
                      ? 'Customers can book this service.'
                      : 'This service is currently unavailable.',
                  value: _isActive,
                  icon: Icons
                      .check_circle_outline_rounded,
                  onChanged: (value) {
                    setState(() {
                      _isActive = value;
                    });
                  },
                ),

                const SizedBox(height: 18),

                _field(
                  controller:
                      _description,
                  label: 'Description',
                  hint:
                      'Add service details...',
                  icon:
                      Icons.notes_rounded,
                  maxLines: 4,
                ),

                const SizedBox(height: 28),

                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _saving
                          ? null
                          : () {
                              Navigator.pop(
                                  context);
                            },
                      child:
                          const Text('Cancel'),
                    ),
                    const SizedBox(width: 10),
                    FilledButton.icon(
                      onPressed:
                          _saving
                              ? null
                              : _save,
                      icon: _saving
                          ? const SizedBox(
                              width: 17,
                              height: 17,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth: 2,
                                color:
                                    Colors.white,
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
                                : 'Create service',
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

  Widget _header() {
    return Row(
      children: [
        Container(
          width: 47,
          height: 47,
          decoration: BoxDecoration(
            color:
                const Color(0xFFF0EFFF),
            borderRadius:
                BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.design_services_outlined,
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
                    ? 'Edit service'
                    : 'New service',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                _editing
                    ? 'Update service information and booking settings'
                    : 'Create a service customers can book',
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
              : () =>
                  Navigator.pop(context),
          icon: const Icon(
            Icons.close_rounded,
          ),
        ),
      ],
    );
  }

  Widget _priceField() {
    return _field(
      controller: _price,
      label: 'Price',
      hint: '0.00',
      icon: Icons.euro_rounded,
      keyboardType:
          const TextInputType
              .numberWithOptions(
        decimal: true,
      ),
      required: true,
      validator: (value) {
        final price =
            _parseDouble(value);

        if (price == null) {
          return 'Enter a valid price';
        }

        if (price < 0) {
          return 'Price cannot be negative';
        }

        return null;
      },
    );
  }

  Widget _durationField() {
    return _field(
      controller: _duration,
      label: 'Duration',
      hint: 'Minutes',
      icon: Icons.schedule_rounded,
      keyboardType:
          TextInputType.number,
      required: true,
      validator: (value) {
        final duration =
            int.tryParse(
                value?.trim() ?? '');

        if (duration == null ||
            duration <= 0) {
          return 'Enter duration in minutes';
        }

        return null;
      },
    );
  }

  Widget _switchTile({
    required String title,
    required String subtitle,
    required bool value,
    required IconData icon,
    required ValueChanged<bool>
        onChanged,
  }) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color:
            const Color(0xFFF8F9FC),
        borderRadius:
            BorderRadius.circular(14),
        border: Border.all(
          color:
              const Color(0xFFE8E9EF),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 39,
            height: 39,
            decoration: BoxDecoration(
              color:
                  const Color(0xFFF0EFFF),
              borderRadius:
                  BorderRadius.circular(11),
            ),
            child: Icon(
              icon,
              size: 19,
              color:
                  const Color(0xFF6C63FF),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color:
                        Color(0xFF858795),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _field({
    required TextEditingController
        controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    bool required = false,
    String? Function(String?)?
        validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator ??
          (required
              ? (value) {
                  if (value == null ||
                      value
                          .trim()
                          .isEmpty) {
                    return '$label is required';
                  }

                  return null;
                }
              : null),
      decoration: _inputDecoration(
        label,
        maxLines == 1 ? icon : null,
      ).copyWith(
        hintText: hint,
        alignLabelWithHint:
            maxLines > 1,
      ),
    );
  }

  InputDecoration _inputDecoration(
    String label,
    IconData? icon,
  ) {
    return InputDecoration(
      labelText: label,
      prefixIcon: icon == null
          ? null
          : Icon(
              icon,
              size: 19,
            ),
      filled: true,
      fillColor:
          const Color(0xFFF8F9FC),
      border: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(13),
        borderSide: const BorderSide(
          color:
              Color(0xFFE6E7EC),
        ),
      ),
      enabledBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(13),
        borderSide: const BorderSide(
          color:
              Color(0xFFE6E7EC),
        ),
      ),
    );
  }

  String? _depositValidator(
      String? value) {
    if (!_requiresDeposit) {
      return null;
    }

    final deposit =
        _parseDouble(value);

    if (deposit == null ||
        deposit < 0) {
      return 'Enter a valid deposit';
    }

    final price =
        _parseDouble(_price.text);

    if (price != null &&
        deposit > price) {
      return 'Deposit cannot exceed price';
    }

    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!
        .validate()) {
      return;
    }

    if (_categoryId == null) {
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final data = {
        'name': _name.text.trim(),
        'description':
            _emptyToNull(
                _description.text),
        'price':
            _parseDouble(_price.text) ??
                0,
        'durationMinutes':
            int.parse(
                _duration.text.trim()),
        'categoryId':
            _categoryId,
        'requiresDeposit':
            _requiresDeposit,
        'depositAmount':
            _requiresDeposit
                ? _parseDouble(
                        _deposit.text) ??
                    0
                : 0,
        'isActive':
            _isActive,
      };

      final api =
          context.read<ApiClient>();

      if (_editing) {
        final id =
            _toInt(widget.service['id']);

        if (id == null) {
          throw Exception(
              'Invalid service ID.');
        }

        await api.put(
          '/catalog/services/$id',
          data: data,
        );
      } else {
        await api.post(
          '/catalog/services',
          data: data,
        );
      }

      if (!mounted) {
        return;
      }

      Navigator.pop(context, true);
    } on DioException catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _saving = false;
      });

      final response =
          e.response?.data;

      String message =
          'Could not save service.';

      if (response is String &&
          response.isNotEmpty) {
        message = response;
      } else if (response is Map) {
        message =
            response['message']
                    ?.toString() ??
                response['title']
                    ?.toString() ??
                message;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            behavior:
                SnackBarBehavior.floating,
            backgroundColor:
                const Color(0xFFD94343),
            content: Text(message),
          ),
        );
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _saving = false;
      });

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            behavior:
                SnackBarBehavior.floating,
            backgroundColor:
                const Color(0xFFD94343),
            content: Text(
              e.toString(),
            ),
          ),
        );
    }
  }
}

String _text(dynamic value) {
  if (value == null) {
    return '';
  }

  return value.toString().trim();
}

String? _nullableText(dynamic value) {
  final text = _text(value);

  return text.isEmpty ? null : text;
}

String? _emptyToNull(String value) {
  final text = value.trim();

  return text.isEmpty ? null : text;
}

int? _toInt(dynamic value) {
  if (value == null) {
    return null;
  }

  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(
    value.toString(),
  );
}

double _toDouble(dynamic value) {
  if (value == null) {
    return 0;
  }

  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(
        value.toString(),
      ) ??
      0;
}

double? _parseDouble(String? value) {
  if (value == null) {
    return null;
  }

  return double.tryParse(
    value
        .trim()
        .replaceAll(',', '.'),
  );
}

const TextStyle _headerStyle =
    TextStyle(
  color: Color(0xFF858795),
  fontSize: 10,
  fontWeight: FontWeight.w700,
  letterSpacing: 0.6,
);