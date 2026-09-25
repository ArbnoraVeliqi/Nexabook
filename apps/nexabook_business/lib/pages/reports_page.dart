import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api_client.dart';
import '../widgets/page_header.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  bool _initialized = false;
  bool _loading = true;

  Map<String, dynamic> _data = {};

  late DateTime _from;
  late DateTime _to;

  String _period = 'This month';
  String _groupBy = 'daily';

  int? _selectedStaffId;
  int? _selectedServiceId;
  String? _selectedStatus;

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();

    _from = DateTime(
      now.year,
      now.month,
      1,
    );

    _to = _endOfDay(now);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_initialized) {
      _initialized = true;
      _loadReports();
    }
  }

  Map<String, dynamic> get _financial {
    final value = _data['financial'];

    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    return {};
  }

  Map<String, dynamic> get _statuses {
    final value = _data['statuses'];

    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    return {};
  }

  Map<String, dynamic> get _performance {
    final value = _data['performance'];

    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    return {};
  }

  Map<String, dynamic> get _filters {
    final value = _data['filters'];

    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    return {};
  }

  List<dynamic> get _staffData {
    final value = _data['byStaff'];

    if (value is List) {
      return value;
    }

    return [];
  }

  List<dynamic> get _serviceData {
    final value = _data['byService'];

    if (value is List) {
      return value;
    }

    return [];
  }

  List<dynamic> get _paymentMethods {
    final value = _data['paymentMethods'];

    if (value is List) {
      return value;
    }

    return [];
  }

  List<dynamic> get _timeline {
    final value = _data['timeline'];

    if (value is List) {
      return value;
    }

    return [];
  }

  List<dynamic> get _staffFilters {
    final value = _filters['staff'];

    if (value is List) {
      return value;
    }

    return [];
  }

  List<dynamic> get _serviceFilters {
    final value = _filters['services'];

    if (value is List) {
      return value;
    }

    return [];
  }

  List<String> get _statusFilters {
    final value = _filters['statuses'];

    if (value is! List) {
      return [];
    }

    return value
        .map((item) => item.toString())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  Future<void> _loadReports() async {
    if (mounted) {
      setState(() {
        _loading = true;
      });
    }

    try {
      final query = <String, dynamic>{
        'from': _from.toIso8601String(),
        'to': _to.toIso8601String(),
        'groupBy': _groupBy,
      };

      if (_selectedStaffId != null) {
        query['staffId'] = _selectedStaffId;
      }

      if (_selectedServiceId != null) {
        query['serviceId'] = _selectedServiceId;
      }

      if (_selectedStatus != null &&
          _selectedStatus!.isNotEmpty) {
        query['status'] = _selectedStatus;
      }

      final response = await context
          .read<ApiClient>()
          .get(
            '/reports/summary',
            query: query,
          );

      if (!mounted) {
        return;
      }

      setState(() {
        _data = response is Map
            ? Map<String, dynamic>.from(response)
            : {};

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
        'Could not load reports.',
        error: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadReports,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(28),
        children: [
          PageHeader(
            'Reports & Analytics',
            'Revenue, appointments, services and team performance',
            action: OutlinedButton.icon(
              onPressed: _chooseCustomPeriod,
              icon: const Icon(
                Icons.calendar_month_outlined,
                size: 18,
              ),
              label: Text(
                '${_shortDate(_from)} - ${_shortDate(_to)}',
              ),
            ),
          ),

          const SizedBox(height: 24),

          _buildPeriodSelector(),

          const SizedBox(height: 16),

          _buildFilters(),

          const SizedBox(height: 22),

          if (_loading)
            _buildLoading()
          else ...[
            _buildSummary(),

            const SizedBox(height: 22),

            _buildSecondarySummary(),

            const SizedBox(height: 22),

            _buildRevenueSection(),

            const SizedBox(height: 22),

            _buildPerformanceGrid(),

            const SizedBox(height: 22),

            _buildBottomGrid(),

            const SizedBox(height: 30),
          ],
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    const periods = [
      'Today',
      'Yesterday',
      'This week',
      'Last week',
      'This month',
      'Last month',
      'This year',
      'Custom',
    ];

    return Container(
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE9EAF0),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: periods.map((period) {
            final selected = _period == period;

            return Padding(
              padding: const EdgeInsets.only(
                right: 5,
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(11),
                onTap: () {
                  _selectPeriod(period);
                },
                child: AnimatedContainer(
                  duration: const Duration(
                    milliseconds: 180,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 17,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? const Color(0xFF6C63FF)
                        : Colors.transparent,
                    borderRadius:
                        BorderRadius.circular(11),
                  ),
                  child: Text(
                    period,
                    style: TextStyle(
                      color: selected
                          ? Colors.white
                          : const Color(0xFF676977),
                      fontSize: 12,
                      fontWeight: selected
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE9EAF0),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 850) {
            return Column(
              children: [
                _buildStaffFilter(),
                const SizedBox(height: 12),
                _buildServiceFilter(),
                const SizedBox(height: 12),
                _buildStatusFilter(),
                const SizedBox(height: 12),
                _buildGroupFilter(),
                const SizedBox(height: 12),
                _buildResetButton(
                  fullWidth: true,
                ),
              ],
            );
          }

          return Row(
            children: [
              Expanded(
                child: _buildStaffFilter(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildServiceFilter(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatusFilter(),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 170,
                child: _buildGroupFilter(),
              ),
              const SizedBox(width: 10),
              _buildResetButton(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStaffFilter() {
    final validIds = _staffFilters
        .map((staff) => _toInt(staff['id']))
        .whereType<int>()
        .toSet();

    final selectedValue =
        _selectedStaffId != null &&
                validIds.contains(_selectedStaffId)
            ? _selectedStaffId
            : null;

    return DropdownButtonFormField<int?>(
      value: selectedValue,
      isExpanded: true,
      decoration: _filterDecoration(
        'Staff',
        Icons.person_outline_rounded,
      ),
      items: [
        const DropdownMenuItem<int?>(
          value: null,
          child: Text('All staff'),
        ),
        ..._staffFilters
            .where(
              (staff) => _toInt(staff['id']) != null,
            )
            .map<DropdownMenuItem<int?>>(
          (staff) {
            final id = _toInt(staff['id'])!;

            return DropdownMenuItem<int?>(
              value: id,
              child: Text(
                _text(staff['name']).isEmpty
                    ? 'Team member'
                    : _text(staff['name']),
                overflow: TextOverflow.ellipsis,
              ),
            );
          },
        ),
      ],
      onChanged: (value) async {
        setState(() {
          _selectedStaffId = value;
        });

        await _loadReports();
      },
    );
  }

  Widget _buildServiceFilter() {
    final validIds = _serviceFilters
        .map((service) => _toInt(service['id']))
        .whereType<int>()
        .toSet();

    final selectedValue =
        _selectedServiceId != null &&
                validIds.contains(_selectedServiceId)
            ? _selectedServiceId
            : null;

    return DropdownButtonFormField<int?>(
      value: selectedValue,
      isExpanded: true,
      decoration: _filterDecoration(
        'Service',
        Icons.design_services_outlined,
      ),
      items: [
        const DropdownMenuItem<int?>(
          value: null,
          child: Text('All services'),
        ),
        ..._serviceFilters
            .where(
              (service) =>
                  _toInt(service['id']) != null,
            )
            .map<DropdownMenuItem<int?>>(
          (service) {
            final id = _toInt(service['id'])!;

            return DropdownMenuItem<int?>(
              value: id,
              child: Text(
                _text(service['name']).isEmpty
                    ? 'Service'
                    : _text(service['name']),
                overflow: TextOverflow.ellipsis,
              ),
            );
          },
        ),
      ],
      onChanged: (value) async {
        setState(() {
          _selectedServiceId = value;
        });

        await _loadReports();
      },
    );
  }

  Widget _buildStatusFilter() {
    final selectedValue =
        _selectedStatus != null &&
                _statusFilters.contains(_selectedStatus)
            ? _selectedStatus
            : null;

    return DropdownButtonFormField<String?>(
      value: selectedValue,
      isExpanded: true,
      decoration: _filterDecoration(
        'Status',
        Icons.tune_rounded,
      ),
      items: [
        const DropdownMenuItem<String?>(
          value: null,
          child: Text('All statuses'),
        ),
        ..._statusFilters.map<DropdownMenuItem<String?>>(
          (status) {
            return DropdownMenuItem<String?>(
              value: status,
              child: Text(
                _displayStatus(status),
                overflow: TextOverflow.ellipsis,
              ),
            );
          },
        ),
      ],
      onChanged: (value) async {
        setState(() {
          _selectedStatus = value;
        });

        await _loadReports();
      },
    );
  }

  Widget _buildGroupFilter() {
    return DropdownButtonFormField<String>(
      value: _groupBy,
      isExpanded: true,
      decoration: _filterDecoration(
        'Group by',
        Icons.view_week_outlined,
      ),
      items: const [
        DropdownMenuItem(
          value: 'daily',
          child: Text('Daily'),
        ),
        DropdownMenuItem(
          value: 'weekly',
          child: Text('Weekly'),
        ),
        DropdownMenuItem(
          value: 'monthly',
          child: Text('Monthly'),
        ),
      ],
      onChanged: (value) async {
        if (value == null) {
          return;
        }

        setState(() {
          _groupBy = value;
        });

        await _loadReports();
      },
    );
  }

  InputDecoration _filterDecoration(
    String label,
    IconData icon,
  ) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(
        icon,
        size: 19,
      ),
      filled: true,
      fillColor: const Color(0xFFF8F9FC),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 14,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(
          color: Color(0xFF6C63FF),
        ),
      ),
    );
  }

  Widget _buildResetButton({
    bool fullWidth = false,
  }) {
    final button = OutlinedButton.icon(
      onPressed: _hasFilters
          ? _resetFilters
          : null,
      icon: const Icon(
        Icons.restart_alt_rounded,
        size: 18,
      ),
      label: const Text(
        'Reset',
      ),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(
          100,
          56,
        ),
      ),
    );

    if (fullWidth) {
      return SizedBox(
        width: double.infinity,
        child: button,
      );
    }

    return button;
  }

  bool get _hasFilters {
    return _selectedStaffId != null ||
        _selectedServiceId != null ||
        _selectedStatus != null;
  }

  Widget _buildSummary() {
    return LayoutBuilder(
      builder: (context, constraints) {
        double width;

        if (constraints.maxWidth >= 1150) {
          width = (constraints.maxWidth - 48) / 4;
        } else if (constraints.maxWidth >= 650) {
          width = (constraints.maxWidth - 16) / 2;
        } else {
          width = constraints.maxWidth;
        }

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _summaryCard(
              width: width,
              title: 'Revenue',
              value: _currency(
                _financial['revenue'],
              ),
              subtitle:
                  '${_data['appointments'] ?? 0} appointments',
              icon: Icons.trending_up_rounded,
              background:
                  const Color(0xFFEAF8F0),
              iconColor:
                  const Color(0xFF279466),
            ),
            _summaryCard(
              width: width,
              title: 'Appointments',
              value:
                  '${_data['appointments'] ?? 0}',
              subtitle:
                  '${_statuses['completed'] ?? 0} completed',
              icon:
                  Icons.calendar_month_outlined,
              background:
                  const Color(0xFFEAF6FF),
              iconColor:
                  const Color(0xFF4389C7),
            ),
            _summaryCard(
              width: width,
              title: 'Average ticket',
              value: _currency(
                _financial['averageTicket'],
              ),
              subtitle:
                  'Average booking value',
              icon:
                  Icons.receipt_long_outlined,
              background:
                  const Color(0xFFF0EFFF),
              iconColor:
                  const Color(0xFF6C63FF),
            ),
            _summaryCard(
              width: width,
              title: 'Expected revenue',
              value: _currency(
                _financial['expectedRevenue'],
              ),
              subtitle:
                  '${_currency(_financial['outstanding'])} outstanding',
              icon: Icons
                  .account_balance_wallet_outlined,
              background:
                  const Color(0xFFFFF4E8),
              iconColor:
                  const Color(0xFFE28A36),
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
    required String subtitle,
    required IconData icon,
    required Color background,
    required Color iconColor,
  }) {
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius:
              BorderRadius.circular(18),
          border: Border.all(
            color:
                const Color(0xFFE9EAF0),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: background,
                borderRadius:
                    BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 25,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,
                    style: const TextStyle(
                      color:
                          Color(0xFF252631),
                      fontSize: 23,
                      height: 1.1,
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    title,
                    style: const TextStyle(
                      color:
                          Color(0xFF555766),
                      fontSize: 13,
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,
                    style: const TextStyle(
                      color:
                          Color(0xFF9698A5),
                      fontSize: 11,
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

  Widget _buildSecondarySummary() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact =
            constraints.maxWidth < 750;

        final cards = [
          _smallMetric(
            title: 'Outstanding',
            value: _currency(
              _financial['outstanding'],
            ),
            icon:
                Icons.schedule_outlined,
            color:
                const Color(0xFFE28A36),
          ),
          _smallMetric(
            title: 'Advances',
            value: _currency(
              _financial['advances'],
            ),
            icon:
                Icons.savings_outlined,
            color:
                const Color(0xFF4389C7),
          ),
          _smallMetric(
            title: 'Refunds',
            value: _currency(
              _financial['refunds'],
            ),
            icon:
                Icons.undo_rounded,
            color:
                const Color(0xFFD95864),
          ),
          _smallMetric(
            title: 'Completion rate',
            value:
                '${_number(_performance['completionRate']).toStringAsFixed(1)}%',
            icon:
                Icons.task_alt_rounded,
            color:
                const Color(0xFF279466),
          ),
        ];

        if (compact) {
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: cards
                .map(
                  (card) => SizedBox(
                    width: constraints.maxWidth,
                    child: card,
                  ),
                )
                .toList(),
          );
        }

        return Row(
          children: [
            for (int i = 0;
                i < cards.length;
                i++) ...[
              Expanded(
                child: cards[i],
              ),
              if (i != cards.length - 1)
                const SizedBox(width: 12),
            ],
          ],
        );
      },
    );
  }

  Widget _smallMetric({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color:
              const Color(0xFFE9EAF0),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 39,
            height: 39,
            decoration: BoxDecoration(
              color: color.withValues(
                alpha: 0.10,
              ),
              borderRadius:
                  BorderRadius.circular(11),
            ),
            child: Icon(
              icon,
              color: color,
              size: 19,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color:
                        Color(0xFF30313C),
                    fontSize: 16,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  title,
                  style: const TextStyle(
                    color:
                        Color(0xFF8B8D99),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueSection() {
    return _section(
      title: 'Revenue overview',
      subtitle:
          '${_shortDate(_from)} - ${_shortDate(_to)}',
      icon: Icons.show_chart_rounded,
      trailing: _buildChartGrouping(),
      child: _timeline.isEmpty
          ? _emptyState(
              icon:
                  Icons.show_chart_rounded,
              title:
                  'No revenue data',
              subtitle:
                  'There is no report data for the selected period.',
            )
          : Column(
              children: [
                SizedBox(
                  height: 280,
                  width: double.infinity,
                  child: _RevenueChart(
                    data: _timeline,
                    currencyFormatter:
                        _compactCurrency,
                  ),
                ),
                const SizedBox(height: 22),
                _buildTimelineTotals(),
              ],
            ),
    );
  }

  Widget _buildChartGrouping() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F8),
        borderRadius:
            BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _chartGroupButton(
            'Daily',
            'daily',
          ),
          _chartGroupButton(
            'Weekly',
            'weekly',
          ),
          _chartGroupButton(
            'Monthly',
            'monthly',
          ),
        ],
      ),
    );
  }

  Widget _chartGroupButton(
    String label,
    String value,
  ) {
    final selected =
        _groupBy == value;

    return InkWell(
      borderRadius:
          BorderRadius.circular(8),
      onTap: () async {
        if (_groupBy == value) {
          return;
        }

        setState(() {
          _groupBy = value;
        });

        await _loadReports();
      },
      child: AnimatedContainer(
        duration: const Duration(
          milliseconds: 160,
        ),
        padding:
            const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 7,
        ),
        decoration: BoxDecoration(
          color: selected
              ? Colors.white
              : Colors.transparent,
          borderRadius:
              BorderRadius.circular(8),
          boxShadow: selected
              ? const [
                  BoxShadow(
                    color:
                        Color(0x12000000),
                    blurRadius: 5,
                    offset:
                        Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected
                ? const Color(
                    0xFF5E56E8,
                  )
                : const Color(
                    0xFF777986,
                  ),
            fontSize: 11,
            fontWeight:
                FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineTotals() {
    final appointments = _timeline.fold<int>(
      0,
      (total, item) =>
          total +
          (_toInt(
                item['appointments'],
              ) ??
              0),
    );

    final completed = _timeline.fold<int>(
      0,
      (total, item) =>
          total +
          (_toInt(
                item['completed'],
              ) ??
              0),
    );

    final revenue = _timeline.fold<double>(
      0,
      (total, item) =>
          total +
          _number(
            item['revenue'],
          ),
    );

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FC),
        borderRadius:
            BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          Expanded(
            child: _chartFooterValue(
              'Revenue',
              _currency(revenue),
            ),
          ),
          _verticalDivider(),
          Expanded(
            child: _chartFooterValue(
              'Appointments',
              '$appointments',
            ),
          ),
          _verticalDivider(),
          Expanded(
            child: _chartFooterValue(
              'Completed',
              '$completed',
            ),
          ),
        ],
      ),
    );
  }

  Widget _chartFooterValue(
    String label,
    String value,
  ) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight:
                FontWeight.w800,
            color:
                Color(0xFF353641),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color:
                Color(0xFF9294A2),
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _verticalDivider() {
    return Container(
      width: 1,
      height: 30,
      margin:
          const EdgeInsets.symmetric(
        horizontal: 15,
      ),
      color:
          const Color(0xFFE4E5EA),
    );
  }

  Widget _buildPerformanceGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact =
            constraints.maxWidth < 900;

        final team =
            _buildTeamPerformance();

        final services =
            _buildServicePerformance();

        if (compact) {
          return Column(
            children: [
              team,
              const SizedBox(height: 22),
              services,
            ],
          );
        }

        return Row(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Expanded(child: team),
            const SizedBox(width: 22),
            Expanded(child: services),
          ],
        );
      },
    );
  }

  Widget _buildTeamPerformance() {
    return _section(
      title: 'Team performance',
      subtitle:
          'Performance for the selected period',
      icon: Icons.groups_outlined,
      child: _staffData.isEmpty
          ? _emptyState(
              icon:
                  Icons.person_search_outlined,
              title:
                  'No team data',
              subtitle:
                  'No staff performance was found for this period.',
            )
          : Column(
              children: [
                for (int index = 0;
                    index <
                        _staffData.length;
                    index++) ...[
                  _teamRow(
                    _staffData[index],
                    index,
                  ),
                  if (index !=
                      _staffData.length -
                          1)
                    const Divider(
                      height: 1,
                      color:
                          Color(0xFFEEEEF2),
                    ),
                ],
              ],
            ),
    );
  }

  Widget _teamRow(
    dynamic staff,
    int index,
  ) {
    final name =
        _text(staff['name']).isEmpty
            ? 'Team member'
            : _text(staff['name']);

    final appointments =
        _toInt(staff['appointments']) ??
            0;

    final completed =
        _toInt(staff['completed']) ?? 0;

    final rate = _number(
      staff['completionRate'],
    );

    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical: 14,
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color:
                  const Color(0xFFF0EFFF),
              borderRadius:
                  BorderRadius.circular(13),
            ),
            alignment: Alignment.center,
            child: Text(
              '${index + 1}',
              style: const TextStyle(
                color:
                    Color(0xFF6C63FF),
                fontWeight:
                    FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
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
                    fontSize: 13,
                    fontWeight:
                        FontWeight.w700,
                    color:
                        Color(0xFF353641),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '$appointments appointments • $completed completed • '
                  '${rate.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    color:
                        Color(0xFF9294A2),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            _currency(
              staff['revenue'],
            ),
            style: const TextStyle(
              fontSize: 13,
              fontWeight:
                  FontWeight.w800,
              color:
                  Color(0xFF27875D),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServicePerformance() {
    return _section(
      title: 'Service performance',
      subtitle:
          'Revenue and bookings by service',
      icon:
          Icons.design_services_outlined,
      child: _serviceData.isEmpty
          ? _emptyState(
              icon:
                  Icons.design_services_outlined,
              title:
                  'No service data',
              subtitle:
                  'No service performance was found for this period.',
            )
          : Column(
              children: [
                for (int index = 0;
                    index <
                        _serviceData.length;
                    index++) ...[
                  _serviceRow(
                    _serviceData[index],
                    index,
                  ),
                  if (index !=
                      _serviceData.length -
                          1)
                    const Divider(
                      height: 1,
                      color:
                          Color(0xFFEEEEF2),
                    ),
                ],
              ],
            ),
    );
  }

  Widget _serviceRow(
    dynamic service,
    int index,
  ) {
    final name =
        _text(service['name']).isEmpty
            ? 'Service'
            : _text(service['name']);

    final count =
        _toInt(service['count']) ?? 0;

    final completed =
        _toInt(service['completed']) ?? 0;

    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical: 14,
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color:
                  const Color(0xFFEAF6FF),
              borderRadius:
                  BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.content_cut_rounded,
              color:
                  Color(0xFF4389C7),
              size: 19,
            ),
          ),
          const SizedBox(width: 12),
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
                    fontSize: 13,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '$count bookings • $completed completed',
                  style: const TextStyle(
                    color:
                        Color(0xFF9294A2),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment:
                CrossAxisAlignment.end,
            children: [
              Text(
                _currency(
                  service['revenue'],
                ),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight:
                      FontWeight.w800,
                  color:
                      Color(0xFF27875D),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Avg ${_currency(service['averagePrice'])}',
                style: const TextStyle(
                  color:
                      Color(0xFF9294A2),
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact =
            constraints.maxWidth < 900;

        final status =
            _buildStatusSection();

        final payments =
            _buildPaymentSection();

        if (compact) {
          return Column(
            children: [
              status,
              const SizedBox(height: 22),
              payments,
            ],
          );
        }

        return Row(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Expanded(child: status),
            const SizedBox(width: 22),
            Expanded(child: payments),
          ],
        );
      },
    );
  }

  Widget _buildStatusSection() {
    final total =
        _toInt(_data['appointments']) ??
            0;

    return _section(
      title: 'Appointment status',
      subtitle:
          '$total appointments in this period',
      icon:
          Icons.donut_large_outlined,
      child: Column(
        children: [
          _statusRow(
            label: 'Completed',
            value:
                _statuses['completed'],
            total: total,
            color:
                const Color(0xFF279466),
          ),
          _statusRow(
            label: 'Confirmed',
            value:
                _statuses['confirmed'],
            total: total,
            color:
                const Color(0xFF4389C7),
          ),
          _statusRow(
            label: 'In progress',
            value:
                _statuses['inProgress'],
            total: total,
            color:
                const Color(0xFF6C63FF),
          ),
          _statusRow(
            label: 'Pending',
            value:
                _statuses['pending'],
            total: total,
            color:
                const Color(0xFFE1A62A),
          ),
          _statusRow(
            label: 'Cancelled',
            value:
                _statuses['cancelled'],
            total: total,
            color:
                const Color(0xFFD95864),
          ),
          _statusRow(
            label: 'No show',
            value:
                _statuses['noShow'],
            total: total,
            color:
                const Color(0xFF777986),
            showDivider: false,
          ),
        ],
      ),
    );
  }

  Widget _statusRow({
    required String label,
    required dynamic value,
    required int total,
    required Color color,
    bool showDivider = true,
  }) {
    final count =
        _toInt(value) ?? 0;

    final percentage = total <= 0
        ? 0.0
        : count / total;

    return Column(
      children: [
        Padding(
          padding:
              const EdgeInsets.symmetric(
            vertical: 11,
          ),
          child: Row(
            children: [
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color:
                        Color(0xFF555766),
                    fontSize: 12,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(
                width: 110,
                child:
                    LinearProgressIndicator(
                  value: percentage
                      .clamp(0, 1),
                  minHeight: 5,
                  borderRadius:
                      BorderRadius.circular(
                    10,
                  ),
                  backgroundColor:
                      const Color(
                    0xFFF0F0F3,
                  ),
                  color: color,
                ),
              ),
              const SizedBox(width: 13),
              SizedBox(
                width: 32,
                child: Text(
                  '$count',
                  textAlign:
                      TextAlign.right,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          const Divider(
            height: 1,
            color:
                Color(0xFFEEEEF2),
          ),
      ],
    );
  }

  Widget _buildPaymentSection() {
    return _section(
      title: 'Payment methods',
      subtitle:
          'Collected revenue by payment method',
      icon: Icons.payments_outlined,
      child: Column(
        children: [
          if (_paymentMethods.isEmpty)
            _emptyState(
              icon:
                  Icons.credit_card_off_outlined,
              title:
                  'No payments',
              subtitle:
                  'No payments were recorded for this period.',
            )
          else
            for (int index = 0;
                index <
                    _paymentMethods.length;
                index++) ...[
              _paymentRow(
                _paymentMethods[index],
              ),
              if (index !=
                  _paymentMethods.length -
                      1)
                const Divider(
                  height: 1,
                  color:
                      Color(0xFFEEEEF2),
                ),
            ],

          if (_paymentMethods.isNotEmpty)
            const SizedBox(height: 18),

          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color:
                  const Color(0xFFF8F9FC),
              borderRadius:
                  BorderRadius.circular(13),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _paymentFooter(
                    'Advances',
                    _currency(
                      _financial[
                          'advances'],
                    ),
                  ),
                ),
                Container(
                  width: 1,
                  height: 35,
                  color:
                      const Color(
                    0xFFE4E5EA,
                  ),
                ),
                Expanded(
                  child: _paymentFooter(
                    'Refunds',
                    _currency(
                      _financial[
                          'refunds'],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _paymentRow(dynamic payment) {
    final method =
        _text(payment['method']).isEmpty
            ? 'Payment'
            : _text(payment['method']);

    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical: 13,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color:
                  const Color(0xFFF0EFFF),
              borderRadius:
                  BorderRadius.circular(12),
            ),
            child: Icon(
              _paymentIcon(method),
              color:
                  const Color(0xFF6C63FF),
              size: 19,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  _displayPaymentMethod(
                    method,
                  ),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${payment['count'] ?? 0} payments',
                  style: const TextStyle(
                    color:
                        Color(0xFF9294A2),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          Text(
            _currency(
              payment['amount'],
            ),
            style: const TextStyle(
              fontSize: 13,
              fontWeight:
                  FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _paymentFooter(
    String label,
    String value,
  ) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color:
                Color(0xFF353641),
            fontSize: 14,
            fontWeight:
                FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color:
                Color(0xFF9294A2),
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _section({
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget child,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color:
              const Color(0xFFE9EAF0),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color:
                      const Color(0xFFF0EFFF),
                  borderRadius:
                      BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color:
                      const Color(0xFF6C63FF),
                  size: 20,
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
                        color:
                            Color(0xFF30313C),
                        fontSize: 16,
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color:
                            Color(0xFF9294A2),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null)
                trailing,
            ],
          ),
          const SizedBox(height: 22),
          child,
        ],
      ),
    );
  }

  Widget _emptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: 35,
        horizontal: 20,
      ),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color:
                  const Color(0xFFF5F5F8),
              borderRadius:
                  BorderRadius.circular(15),
            ),
            child: Icon(
              icon,
              color:
                  const Color(0xFF999BA7),
              size: 23,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight:
                  FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color:
                  Color(0xFF9294A2),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return Container(
      height: 450,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color:
              const Color(0xFFE9EAF0),
        ),
      ),
      child: const Center(
        child:
            CircularProgressIndicator(),
      ),
    );
  }

  Future<void> _selectPeriod(
    String period,
  ) async {
    if (period == 'Custom') {
      await _chooseCustomPeriod();
      return;
    }

    final now = DateTime.now();

    late DateTime start;
    late DateTime end;

    switch (period) {
      case 'Today':
        start = DateTime(
          now.year,
          now.month,
          now.day,
        );

        end = _endOfDay(now);
        break;

      case 'Yesterday':
        final yesterday =
            now.subtract(
          const Duration(days: 1),
        );

        start = DateTime(
          yesterday.year,
          yesterday.month,
          yesterday.day,
        );

        end = _endOfDay(
          yesterday,
        );
        break;

      case 'This week':
        start = _startOfWeek(now);
        end = _endOfDay(now);
        break;

      case 'Last week':
        final thisWeek =
            _startOfWeek(now);

        start = thisWeek.subtract(
          const Duration(days: 7),
        );

        end = thisWeek.subtract(
          const Duration(
            microseconds: 1,
          ),
        );
        break;

      case 'Last month':
        final firstThisMonth =
            DateTime(
          now.year,
          now.month,
          1,
        );

        start = DateTime(
          firstThisMonth
              .subtract(
                const Duration(
                  days: 1,
                ),
              )
              .year,
          firstThisMonth
              .subtract(
                const Duration(
                  days: 1,
                ),
              )
              .month,
          1,
        );

        end = firstThisMonth.subtract(
          const Duration(
            microseconds: 1,
          ),
        );
        break;

      case 'This year':
        start = DateTime(
          now.year,
          1,
          1,
        );

        end = _endOfDay(now);
        break;

      case 'This month':
      default:
        start = DateTime(
          now.year,
          now.month,
          1,
        );

        end = _endOfDay(now);
    }

    setState(() {
      _period = period;
      _from = start;
      _to = end;

      if (period == 'This year') {
        _groupBy = 'monthly';
      } else if (period == 'Last month' ||
          period == 'This month') {
        _groupBy = 'daily';
      } else {
        _groupBy = 'daily';
      }
    });

    await _loadReports();
  }

  Future<void> _chooseCustomPeriod() async {
    final result =
        await showDateRangePicker(
      context: context,
      firstDate: DateTime(
        DateTime.now().year - 5,
      ),
      lastDate: DateTime.now().add(
        const Duration(days: 365),
      ),
      initialDateRange:
          DateTimeRange(
        start: _from,
        end: _to,
      ),
    );

    if (result == null) {
      return;
    }

    setState(() {
      _period = 'Custom';

      _from = DateTime(
        result.start.year,
        result.start.month,
        result.start.day,
      );

      _to = DateTime(
        result.end.year,
        result.end.month,
        result.end.day,
        23,
        59,
        59,
        999,
      );
    });

    await _loadReports();
  }

  Future<void> _resetFilters() async {
    setState(() {
      _selectedStaffId = null;
      _selectedServiceId = null;
      _selectedStatus = null;
    });

    await _loadReports();
  }

  DateTime _startOfWeek(
    DateTime date,
  ) {
    final difference =
        date.weekday - DateTime.monday;

    final start = date.subtract(
      Duration(days: difference),
    );

    return DateTime(
      start.year,
      start.month,
      start.day,
    );
  }

  DateTime _endOfDay(
    DateTime date,
  ) {
    return DateTime(
      date.year,
      date.month,
      date.day,
      23,
      59,
      59,
      999,
    );
  }

  String _displayStatus(
    String status,
  ) {
    switch (status) {
      case 'InProgress':
        return 'In progress';

      case 'NoShow':
        return 'No show';

      default:
        return status;
    }
  }

  String _displayPaymentMethod(
    String method,
  ) {
    switch (method) {
      case 'BankTransfer':
        return 'Bank transfer';

      default:
        return method;
    }
  }

  IconData _paymentIcon(
    String method,
  ) {
    switch (method.toLowerCase()) {
      case 'cash':
        return Icons.payments_outlined;

      case 'card':
        return Icons.credit_card_outlined;

      case 'banktransfer':
        return Icons
            .account_balance_outlined;

      default:
        return Icons
            .account_balance_wallet_outlined;
    }
  }

  String _currency(dynamic value) {
    return '€${_number(value).toStringAsFixed(2)}';
  }

  String _compactCurrency(
    double value,
  ) {
    if (value >= 1000000) {
      return '€${(value / 1000000).toStringAsFixed(1)}M';
    }

    if (value >= 1000) {
      return '€${(value / 1000).toStringAsFixed(1)}K';
    }

    return '€${value.toStringAsFixed(0)}';
  }

  double _number(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  int? _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
      value?.toString() ?? '',
    );
  }

  String _text(dynamic value) {
    if (value == null) {
      return '';
    }

    return value.toString().trim();
  }

  String _shortDate(
    DateTime date,
  ) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
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

class _RevenueChart extends StatelessWidget {
  final List<dynamic> data;
  final String Function(double value)
      currencyFormatter;

  const _RevenueChart({
    required this.data,
    required this.currencyFormatter,
  });

  @override
  Widget build(BuildContext context) {
    final values = data
        .map(
          (item) =>
              _chartNumber(
            item['revenue'],
          ),
        )
        .toList();

    final maximum = values.isEmpty
        ? 0.0
        : values.reduce(math.max);

    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomPaint(
          painter: _RevenueChartPainter(
            data: data,
            maxValue: maximum,
            currencyFormatter:
                currencyFormatter,
          ),
          size: Size(
            constraints.maxWidth,
            constraints.maxHeight,
          ),
        );
      },
    );
  }
}

class _RevenueChartPainter
    extends CustomPainter {
  final List<dynamic> data;
  final double maxValue;
  final String Function(double value)
      currencyFormatter;

  _RevenueChartPainter({
    required this.data,
    required this.maxValue,
    required this.currencyFormatter,
  });

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    if (data.isEmpty) {
      return;
    }

    const left = 55.0;
    const right = 12.0;
    const top = 15.0;
    const bottom = 42.0;

    final chartWidth =
        size.width - left - right;

    final chartHeight =
        size.height - top - bottom;

    if (chartWidth <= 0 ||
        chartHeight <= 0) {
      return;
    }

    final gridPaint = Paint()
      ..color =
          const Color(0xFFEDEEF2)
      ..strokeWidth = 1;

    final linePaint = Paint()
      ..color =
          const Color(0xFF6C63FF)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final pointPaint = Paint()
      ..color =
          const Color(0xFF6C63FF)
      ..style = PaintingStyle.fill;

    final fillPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0x336C63FF),
          Color(0x006C63FF),
        ],
      ).createShader(
        Rect.fromLTWH(
          left,
          top,
          chartWidth,
          chartHeight,
        ),
      );

    const gridLines = 4;

    final safeMax =
        maxValue <= 0 ? 1.0 : maxValue;

    for (int i = 0;
        i <= gridLines;
        i++) {
      final y = top +
          chartHeight *
              (i / gridLines);

      canvas.drawLine(
        Offset(left, y),
        Offset(
          size.width - right,
          y,
        ),
        gridPaint,
      );

      final value = safeMax *
          (1 - i / gridLines);

      final textPainter =
          TextPainter(
        text: TextSpan(
          text:
              currencyFormatter(value),
          style: const TextStyle(
            color:
                Color(0xFF999BA7),
            fontSize: 9,
          ),
        ),
        textDirection:
            TextDirection.ltr,
      )..layout(
          maxWidth: left - 8,
        );

      textPainter.paint(
        canvas,
        Offset(
          left -
              textPainter.width -
              8,
          y -
              textPainter.height /
                  2,
        ),
      );
    }

    final points = <Offset>[];

    for (int i = 0;
        i < data.length;
        i++) {
      final value =
          _chartNumber(
        data[i]['revenue'],
      );

      final x = data.length == 1
          ? left +
              chartWidth / 2
          : left +
              chartWidth *
                  (i /
                      (data.length -
                          1));

      final ratio =
          (value / safeMax)
              .clamp(0.0, 1.0);

      final y = top +
          chartHeight *
              (1 - ratio);

      points.add(
        Offset(x, y),
      );
    }

    if (points.length == 1) {
      final point = points.first;

      canvas.drawLine(
        Offset(
          left,
          point.dy,
        ),
        Offset(
          size.width - right,
          point.dy,
        ),
        linePaint,
      );
    } else {
      final path = Path()
        ..moveTo(
          points.first.dx,
          points.first.dy,
        );

      for (int i = 1;
          i < points.length;
          i++) {
        path.lineTo(
          points[i].dx,
          points[i].dy,
        );
      }

      canvas.drawPath(
        path,
        linePaint,
      );

      final fillPath =
          Path.from(path)
            ..lineTo(
              points.last.dx,
              top + chartHeight,
            )
            ..lineTo(
              points.first.dx,
              top + chartHeight,
            )
            ..close();

      canvas.drawPath(
        fillPath,
        fillPaint,
      );
    }

    final labelStep =
        data.length <= 8
            ? 1
            : (data.length / 7)
                .ceil();

    for (int i = 0;
        i < points.length;
        i++) {
      canvas.drawCircle(
        points[i],
        4,
        pointPaint,
      );

      canvas.drawCircle(
        points[i],
        7,
        Paint()
          ..color =
              const Color(
            0x226C63FF,
          ),
      );

      final shouldShowLabel =
          i % labelStep == 0 ||
              i ==
                  points.length -
                      1;

      if (!shouldShowLabel) {
        continue;
      }

      final label =
          data[i]['label']
                  ?.toString() ??
              '';

      final painter =
          TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(
            color:
                Color(0xFF858795),
            fontSize: 9,
          ),
        ),
        maxLines: 1,
        textDirection:
            TextDirection.ltr,
      )..layout(
          maxWidth: 80,
        );

      var x = points[i].dx -
          painter.width / 2;

      x = x.clamp(
        left,
        size.width -
            right -
            painter.width,
      );

      painter.paint(
        canvas,
        Offset(
          x,
          top +
              chartHeight +
              13,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(
    covariant _RevenueChartPainter
        oldDelegate,
  ) {
    return oldDelegate.data != data ||
        oldDelegate.maxValue !=
            maxValue;
  }
}

double _chartNumber(dynamic value) {
  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(
        value?.toString() ?? '',
      ) ??
      0;
}