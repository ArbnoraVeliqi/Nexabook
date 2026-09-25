import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api_client.dart';
import '../core/auth_provider.dart';
import 'booking_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();

  List<dynamic> _services = [];

  bool _loading = true;
  bool _initialized = false;

  String _search = '';
  String _selectedCategory = 'All';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_initialized) {
      _initialized = true;
      _loadServices();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadServices() async {
    setState(() {
      _loading = true;
    });

    try {
      final result = await context.read<ApiClient>().get(
        '/catalog/services',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _services = result is List
            ? List<dynamic>.from(result)
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

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text(
              'Could not load services.',
            ),
          ),
        );
    }
  }

  List<String> get _categories {
    final categories = <String>{};

    for (final service in _services) {
      final category = _categoryName(service);

      if (category.isNotEmpty) {
        categories.add(category);
      }
    }

    return [
      'All',
      ...categories,
    ];
  }

  List<dynamic> get _filteredServices {
    final query = _search.trim().toLowerCase();

    return _services.where((service) {
      final name = _value(service, 'name').toLowerCase();
      final description =
          _value(service, 'description').toLowerCase();

      final category =
          _categoryName(service).toLowerCase();

      final matchesSearch = query.isEmpty ||
          name.contains(query) ||
          description.contains(query) ||
          category.contains(query);

      final matchesCategory =
          _selectedCategory == 'All' ||
              category ==
                  _selectedCategory.toLowerCase();

      return matchesSearch && matchesCategory;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    final fullName = auth.name?.trim() ?? '';

    final firstName = fullName.isEmpty
        ? 'there'
        : fullName.split(' ').first;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8FB),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadServices,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  20,
                  18,
                  20,
                  32,
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate(
                    [
                      _buildHeader(firstName),

                      const SizedBox(height: 28),

                      _buildSearch(),

                      const SizedBox(height: 24),

                      _buildHeroCard(),

                      const SizedBox(height: 32),

                      _buildSectionHeader(
                        title: 'Explore services',
                        subtitle:
                            'Find the right service for you',
                      ),

                      const SizedBox(height: 16),

                      _buildCategories(),

                      const SizedBox(height: 30),

                      _buildSectionHeader(
                        title: 'Popular services',
                        subtitle:
                            '${_filteredServices.length} services available',
                      ),

                      const SizedBox(height: 16),

                      if (_loading)
                        _buildLoading()
                      else if (_filteredServices.isEmpty)
                        _buildEmptyState()
                      else
                        _buildServices(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String firstName) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                'Hello, $firstName 👋',
                style: const TextStyle(
                  color: Color(0xFF77798A),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'Find your next\nappointment',
                style: TextStyle(
                  color: Color(0xFF20212A),
                  fontSize: 28,
                  height: 1.15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.7,
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: const Color(0xFFE9E9EF),
            ),
          ),
          child: IconButton(
            tooltip: 'Notifications',
            onPressed: () {},
            icon: const Icon(
              Icons.notifications_none_rounded,
              size: 23,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearch() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 18,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _search = value;
          });
        },
        decoration: InputDecoration(
          hintText: 'Search services...',
          hintStyle: const TextStyle(
            color: Color(0xFF9A9BA8),
            fontSize: 14,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: Color(0xFF696B78),
          ),
          suffixIcon: _search.isEmpty
              ? null
              : IconButton(
                  onPressed: () {
                    _searchController.clear();

                    setState(() {
                      _search = '';
                    });
                  },
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 19,
                  ),
                ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(
            vertical: 17,
          ),
        ),
      ),
    );
  }

  Widget _buildHeroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF6C63FF),
            Color(0xFF897FFB),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: const [
          BoxShadow(
            color: Color(0x336C63FF),
            blurRadius: 25,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -25,
            top: -40,
            child: Container(
              width: 135,
              height: 135,
              decoration: BoxDecoration(
                color: Colors.white.withValues(
                  alpha: 0.08,
                ),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: 25,
            bottom: -65,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white.withValues(
                  alpha: 0.06,
                ),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(
                    alpha: 0.15,
                  ),
                  borderRadius:
                      BorderRadius.circular(20),
                ),
                child: const Text(
                  'BOOK WITH EASE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.7,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Your time,\nyour choice.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  height: 1.1,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Discover services and book your\nnext appointment in seconds.',
                style: TextStyle(
                  color: Colors.white.withValues(
                    alpha: 0.82,
                  ),
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              Material(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(13),
                child: InkWell(
                  borderRadius:
                      BorderRadius.circular(13),
                  onTap: () {
                    if (_services.isEmpty) {
                      return;
                    }

                    setState(() {
                      _selectedCategory = 'All';
                      _search = '';
                    });

                    _searchController.clear();
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 17,
                      vertical: 11,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Explore services',
                          style: TextStyle(
                            color: Color(0xFF5E56D9),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(width: 7),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 17,
                          color: Color(0xFF5E56D9),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF25262E),
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xFF8A8C99),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategories() {
    final categories = _categories;

    return SizedBox(
      height: 43,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) =>
            const SizedBox(width: 9),
        itemBuilder: (context, index) {
          final category = categories[index];

          final selected =
              category == _selectedCategory;

          return InkWell(
            borderRadius:
                BorderRadius.circular(14),
            onTap: () {
              setState(() {
                _selectedCategory = category;
              });
            },
            child: AnimatedContainer(
              duration:
                  const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(
                horizontal: 17,
              ),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xFF6C63FF)
                    : Colors.white,
                borderRadius:
                    BorderRadius.circular(14),
                border: Border.all(
                  color: selected
                      ? const Color(0xFF6C63FF)
                      : const Color(0xFFE8E8EE),
                ),
                boxShadow: selected
                    ? const [
                        BoxShadow(
                          color: Color(0x226C63FF),
                          blurRadius: 12,
                          offset: Offset(0, 5),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                category,
                style: TextStyle(
                  color: selected
                      ? Colors.white
                      : const Color(0xFF626470),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildServices() {
    final services = _filteredServices;

    return Column(
      children: List.generate(
        services.length,
        (index) {
          final service = services[index];

          return TweenAnimationBuilder<double>(
            duration: Duration(
              milliseconds: 300 + (index * 60),
            ),
            tween: Tween(
              begin: 0,
              end: 1,
            ),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(
                  0,
                  14 * (1 - value),
                ),
                child: Opacity(
                  opacity: value,
                  child: child,
                ),
              );
            },
            child: Padding(
              padding:
                  const EdgeInsets.only(bottom: 13),
              child: _serviceCard(service),
            ),
          );
        },
      ),
    );
  }

  Widget _serviceCard(dynamic service) {
    final name = _value(
      service,
      'name',
      fallback: 'Service',
    );

    final description =
        _value(service, 'description');

    final category = _categoryName(service);

    final duration = _value(
      service,
      'durationMinutes',
      fallback: '0',
    );

    final price = _formatPrice(
      service['price'],
    );

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(19),
      child: InkWell(
        borderRadius: BorderRadius.circular(19),
       onTap: () {
  debugPrint('========== BEFORE BOOKING ==========');
  debugPrint('SERVICE TYPE: ${service.runtimeType}');
  debugPrint('SERVICE: $service');

  if (service is Map) {
    debugPrint('ID TYPE: ${service['id']?.runtimeType}');
    debugPrint('NAME TYPE: ${service['name']?.runtimeType}');
    debugPrint(
      'DURATION TYPE: ${service['durationMinutes']?.runtimeType}',
    );
    debugPrint(
      'PRICE TYPE: ${service['price']?.runtimeType}',
    );
    debugPrint(
      'CATEGORY TYPE: ${service['categoryName']?.runtimeType}',
    );
  }

  debugPrint('====================================');

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => BookingPage(
        service: Map<String, dynamic>.from(service),
      ),
    ),
  );
},
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(19),
            border: Border.all(
              color: const Color(0xFFEBEBF0),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFF0EFFF),
                      Color(0xFFE8E6FF),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius:
                      BorderRadius.circular(17),
                ),
                child: const Icon(
                  Icons.spa_outlined,
                  color: Color(0xFF6C63FF),
                  size: 27,
                ),
              ),

              const SizedBox(width: 15),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    if (category.isNotEmpty) ...[
                      Text(
                        category.toUpperCase(),
                        maxLines: 1,
                        overflow:
                            TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF8D86E8),
                          fontSize: 9,
                          fontWeight:
                              FontWeight.w700,
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(height: 5),
                    ],

                    Text(
                      name,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF292A32),
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        description,
                        maxLines: 1,
                        overflow:
                            TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF92939F),
                          fontSize: 11,
                        ),
                      ),
                    ],

                    const SizedBox(height: 8),

                    Row(
                      children: [
                        const Icon(
                          Icons.schedule_rounded,
                          size: 14,
                          color: Color(0xFF92939F),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$duration min',
                          style: const TextStyle(
                            color: Color(0xFF777986),
                            fontSize: 11,
                            fontWeight:
                                FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              Column(
                crossAxisAlignment:
                    CrossAxisAlignment.end,
                children: [
                  Text(
                    '€$price',
                    style: const TextStyle(
                      color: Color(0xFF25262E),
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 13),
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color:
                          const Color(0xFFF0EFFF),
                      borderRadius:
                          BorderRadius.circular(11),
                    ),
                    child: const Icon(
                      Icons.arrow_forward_rounded,
                      color: Color(0xFF6C63FF),
                      size: 18,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return const Padding(
      padding: EdgeInsets.symmetric(
        vertical: 60,
      ),
      child: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 45,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFEBEBF0),
        ),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.search_off_rounded,
            color: Color(0xFF9B9CA8),
            size: 35,
          ),
          SizedBox(height: 13),
          Text(
            'No services found',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Try another search or category.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF8B8D99),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  String _categoryName(dynamic service) {
    final category = service['category'];

    if (category is Map) {
      final name =
          category['name'] ??
              category['categoryName'];

      if (name != null) {
        return name.toString().trim();
      }
    }

    final categoryName =
        service['categoryName'];

    if (categoryName != null) {
      return categoryName.toString().trim();
    }

    return '';
  }

  String _value(
    dynamic object,
    String key, {
    String fallback = '',
  }) {
    final value = object[key];

    if (value == null) {
      return fallback;
    }

    final text = value.toString().trim();

    return text.isEmpty ? fallback : text;
  }

  String _formatPrice(dynamic value) {
    if (value == null) {
      return '0.00';
    }

    final number = double.tryParse(
      value.toString(),
    );

    if (number == null) {
      return value.toString();
    }

    return number.toStringAsFixed(2);
  }
}