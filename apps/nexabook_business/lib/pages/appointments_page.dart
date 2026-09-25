import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api_client.dart';

class AppointmentsPage extends StatefulWidget {
  const AppointmentsPage({super.key});

  @override
  State<AppointmentsPage> createState() => _AppointmentsPageState();
}

class _AppointmentsPageState extends State<AppointmentsPage> {
  static const primary = Color(0xFF6C63FF);
  static const background = Color(0xFFF7F8FC);
  static const textPrimary = Color(0xFF1B1D29);
  static const textSecondary = Color(0xFF77798A);

  final searchController = TextEditingController();

  List<dynamic> appointments = [];
  List<dynamic> staff = [];
  List<dynamic> services = [];
  List<dynamic> customers = [];

  bool loading = true;
  bool refreshing = false;
  bool initialized = false;

  String period = 'Today';
  String status = 'All';
  String paymentStatus = 'All';
  int? staffId;
  int? serviceId;

  final periods = const ['Today', 'Tomorrow', 'Week', 'Month', 'All'];
  final statuses = const [
    'All',
    'Pending',
    'Confirmed',
    'In progress',
    'Completed',
    'Cancelled',
    'No show',
  ];
  final paymentStatuses = const ['All', 'Unpaid', 'Partially paid', 'Paid'];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!initialized) {
      initialized = true;
      _loadAll();
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  ApiClient get api => context.read<ApiClient>();

  Future<void> _loadAll() async {
    setState(() => loading = true);

    try {
      final results = await Future.wait([
        api.get('/appointments'),
        api.get('/catalog/staff'),
        api.get('/catalog/services'),
        api.get('/customers'),
      ]);

      if (!mounted) return;

      setState(() {
        appointments = _asList(results[0]);
        staff = _asList(results[1]);
        services = _asList(results[2]);
        customers = _asList(results[3]);
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      _message('Could not load appointments.', error: true);
    }
  }

  Future<void> _refresh() async {
    setState(() => refreshing = true);
    try {
      final result = await api.get('/appointments');
      if (!mounted) return;
      setState(() {
        appointments = _asList(result);
        refreshing = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => refreshing = false);
      _message('Could not refresh appointments.', error: true);
    }
  }

  List<dynamic> _asList(dynamic value) {
    if (value is List) return value;
    if (value is Map && value['items'] is List) return value['items'];
    return [];
  }

  List<dynamic> get visibleAppointments {
    final q = searchController.text.trim().toLowerCase();
    final now = DateTime.now();

    return appointments.where((a) {
      final start = DateTime.tryParse('${a['startTime'] ?? ''}');
      if (!_matchesPeriod(start, now)) return false;

      if (status != 'All' &&
          _normalize('${a['status'] ?? ''}') != _normalize(status)) {
        return false;
      }

      if (paymentStatus != 'All' &&
          _normalize('${a['paymentStatus'] ?? ''}') !=
              _normalize(paymentStatus)) {
        return false;
      }

      if (staffId != null && _staffId(a) != staffId) return false;
      if (serviceId != null && _serviceId(a) != serviceId) return false;

      if (q.isEmpty) return true;

      final haystack = [
        a['reference'],
        _clientName(a),
        _clientEmail(a),
        _clientPhone(a),
        _serviceName(a),
        _staffName(a),
      ].join(' ').toLowerCase();

      return haystack.contains(q);
    }).toList()
      ..sort((a, b) {
        final aa = DateTime.tryParse('${a['startTime'] ?? ''}');
        final bb = DateTime.tryParse('${b['startTime'] ?? ''}');
        if (aa == null || bb == null) return 0;
        return aa.compareTo(bb);
      });
  }

  bool _matchesPeriod(DateTime? date, DateTime now) {
    if (period == 'All') return true;
    if (date == null) return false;

    final d = DateTime(date.year, date.month, date.day);
    final today = DateTime(now.year, now.month, now.day);

    if (period == 'Today') return d == today;
    if (period == 'Tomorrow') return d == today.add(const Duration(days: 1));

    if (period == 'Week') {
      final weekStart = today.subtract(Duration(days: today.weekday - 1));
      final weekEnd = weekStart.add(const Duration(days: 7));
      return !d.isBefore(weekStart) && d.isBefore(weekEnd);
    }

    if (period == 'Month') {
      return d.year == today.year && d.month == today.month;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: background,
      child: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _header(),
                    // const SizedBox(height: 24),
                    // _summary(),
                    const SizedBox(height: 20),
                    _search(),
                    const SizedBox(height: 14),
                    _periodFilters(),
                    const SizedBox(height: 12),
                    _advancedFilters(),
                    const SizedBox(height: 22),
                    if (loading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 80),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (visibleAppointments.isEmpty)
                      _empty()
                    else
                      ...visibleAppointments.map(
                        (a) => Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _appointmentCard(a),
                        ),
                      ),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return LayoutBuilder(
      builder: (context, c) {
        final compact = c.maxWidth < 650;
        final title = const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Appointments',
              style: TextStyle(
                fontSize: 29,
                fontWeight: FontWeight.w800,
                color: textPrimary,
                letterSpacing: -0.8,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Manage bookings, payments and your team schedule.',
              style: TextStyle(color: textSecondary, fontSize: 13.5),
            ),
          ],
        );

        final add = FilledButton.icon(
          onPressed: _openCreate,
          style: FilledButton.styleFrom(
            backgroundColor: primary,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 17),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
          icon: const Icon(Icons.add_rounded),
          label: const Text(
            'New appointment',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        );

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [title, const SizedBox(height: 18), add],
          );
        }

        return Row(
          children: [
            Expanded(child: title),
            add,
          ],
        );
      },
    );
  }

  // Widget _summary() {
  //   final data = visibleAppointments;
  //   final total = data.length;
  //   final confirmed =
  //       data.where((x) => _normalize('${x['status']}') == 'confirmed').length;
  //   final expected = data.fold<double>(
  //     0,
  //     (s, x) => s + _money(x['totalAmount']),
  //   );
  //   final collected = data.fold<double>(
  //     0,
  //     (s, x) => s + _money(x['paidAmount']),
  //   );
  //   final remaining = data.fold<double>(
  //     0,
  //     (s, x) => s + _money(x['remainingAmount']),
  //   );

  //   final cards = [
  //     _SummaryCard(
  //       'Appointments',
  //       '$total',
  //       Icons.calendar_month_outlined,
  //     ),
  //     _SummaryCard(
  //       'Confirmed',
  //       '$confirmed',
  //       Icons.check_circle_outline_rounded,
  //     ),
  //     _SummaryCard(
  //       'Collected',
  //       _eur(collected),
  //       Icons.payments_outlined,
  //     ),
  //     _SummaryCard(
  //       'Remaining',
  //       _eur(remaining),
  //       Icons.account_balance_wallet_outlined,
  //       subtitle: 'Expected ${_eur(expected)}',
  //     ),
  //   ];

  //   return LayoutBuilder(
  //     builder: (context, c) {
  //       if (c.maxWidth >= 900) {
  //         return Row(
  //           children: [
  //             for (var i = 0; i < cards.length; i++) ...[
  //               Expanded(child: cards[i]),
  //               if (i != cards.length - 1) const SizedBox(width: 12),
  //             ],
  //           ],
  //         );
  //       }

  //       final w = c.maxWidth > 520 ? (c.maxWidth - 12) / 2 : c.maxWidth;
  //       return Wrap(
  //         spacing: 12,
  //         runSpacing: 12,
  //         children: cards.map((x) => SizedBox(width: w, child: x)).toList(),
  //       );
  //     },
  //   );
  // }

  Widget _search() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: _panelDecoration(),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search client, reference, service or team member...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: searchController.text.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          searchController.clear();
                          setState(() {});
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
                filled: true,
                fillColor: const Color(0xFFF8F9FC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(13),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          IconButton.filledTonal(
            onPressed: refreshing ? null : _refresh,
            icon: refreshing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
    );
  }

  Widget _periodFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: periods.map((item) {
          final selected = period == item;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(item),
              selected: selected,
              onSelected: (_) => setState(() => period = item),
              selectedColor: primary,
              labelStyle: TextStyle(
                color: selected ? Colors.white : textSecondary,
                fontWeight: FontWeight.w600,
              ),
              side: BorderSide(
                color: selected ? primary : const Color(0xFFE3E4EA),
              ),
              backgroundColor: Colors.white,
              showCheckmark: false,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _advancedFilters() {
    return LayoutBuilder(
      builder: (context, c) {
        final fields = [
          _filterDropdown<String>(
            value: status,
            label: 'Status',
            items: statuses,
            labelFor: (x) => x,
            onChanged: (v) => setState(() => status = v ?? 'All'),
          ),
          _filterDropdown<String>(
            value: paymentStatus,
            label: 'Payment',
            items: paymentStatuses,
            labelFor: (x) => x,
            onChanged: (v) => setState(() => paymentStatus = v ?? 'All'),
          ),
          _filterDropdown<int?>(
            value: staffId,
            label: 'Team member',
            items: <int?>[
              null,
              ...staff
                  .map((x) => _toInt(x['id']))
                  .whereType<int>(),
            ],
            labelFor: (id) =>
                id == null ? 'All team members' : _staffLabelById(id),
            onChanged: (v) => setState(() => staffId = v),
          ),
          _filterDropdown<int?>(
            value: serviceId,
            label: 'Service',
            items: <int?>[
              null,
              ...services
                  .map((x) => _toInt(x['id']))
                  .whereType<int>(),
            ],
            labelFor: (id) =>
                id == null ? 'All services' : _serviceLabelById(id),
            onChanged: (v) => setState(() => serviceId = v),
          ),
        ];

        if (c.maxWidth >= 900) {
          return Row(
            children: [
              for (var i = 0; i < fields.length; i++) ...[
                Expanded(child: fields[i]),
                if (i != fields.length - 1) const SizedBox(width: 10),
              ],
            ],
          );
        }

        return Column(
          children: [
            for (final f in fields) ...[
              f,
              const SizedBox(height: 10),
            ],
          ],
        );
      },
    );
  }

  Widget _filterDropdown<T>({
    required T value,
    required String label,
    required List<T> items,
    required String Function(T) labelFor,
    required ValueChanged<T?> onChanged,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE5E6EC)),
        ),
      ),
      items: items
          .map(
            (x) => DropdownMenuItem<T>(
              value: x,
              child: Text(labelFor(x), overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _appointmentCard(dynamic a) {
    final client = _clientName(a);
    final normalized = _normalize('${a['status'] ?? 'Pending'}');
    final remaining = _money(a['remainingAmount']);

    return Container(
      decoration: _panelDecoration(radius: 20),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                Row(
                  children: [
                    _avatar(client),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            client,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_serviceName(a)} • ${a['reference'] ?? '—'}',
                            style: const TextStyle(
                              color: textSecondary,
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _StatusBadge('${a['status'] ?? 'Pending'}'),
                    PopupMenuButton<String>(
                      onSelected: (x) => _menuAction(x, a),
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'details', child: Text('View details')),
                        PopupMenuItem(value: 'payment', child: Text('Collect payment')),
                        PopupMenuItem(value: 'reschedule', child: Text('Reschedule')),
                        PopupMenuItem(value: 'reassign', child: Text('Reassign team member')),
                        PopupMenuDivider(),
                        PopupMenuItem(value: 'cancel', child: Text('Cancel appointment')),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 17),
                LayoutBuilder(
                  builder: (context, c) {
                    final items = [
                      _Info(Icons.calendar_today_outlined, 'Date', _date(a)),
                      _Info(Icons.schedule_outlined, 'Time', _time(a)),
                      _Info(Icons.person_outline_rounded, 'Team member', _staffName(a)),
                      _Info(Icons.timer_outlined, 'Duration', '${a['durationMinutes'] ?? '—'} min'),
                    ];
                    if (c.maxWidth < 620) {
                      return Column(
                        children: items
                            .map(
                              (x) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: x,
                              ),
                            )
                            .toList(),
                      );
                    }
                    return Row(
                      children: items.map((x) => Expanded(child: x)).toList(),
                    );
                  },
                ),
                const SizedBox(height: 14),
                _paymentBar(a),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(18, 11, 18, 13),
            decoration: const BoxDecoration(
              color: Color(0xFFFCFCFE),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
              border: Border(top: BorderSide(color: Color(0xFFF0F1F5))),
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (normalized == 'pending')
                  _action('Confirm', Icons.check_rounded, () => _changeStatus(a, 'Confirmed'), true),
                if (normalized == 'confirmed')
                  _action('Start', Icons.play_arrow_rounded, () => _changeStatus(a, 'InProgress'), true),
                if (normalized == 'inprogress')
                  _action('Complete', Icons.task_alt_rounded, () => _changeStatus(a, 'Completed'), true),
                if (remaining > 0)
                  _action('Collect payment', Icons.payments_outlined, () => _collectPayment(a), false),
                if (!['completed', 'cancelled', 'noshow'].contains(normalized))
                  _action('Reschedule', Icons.event_repeat_rounded, () => _reschedule(a), false),
                _action('Details', Icons.visibility_outlined, () => _details(a), false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _paymentBar(dynamic a) {
    final total = _money(a['totalAmount']);
    final paid = _money(a['paidAmount']);
    final advance = _money(a['advanceAmount']);
    final remaining = _money(a['remainingAmount']);

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FC),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Wrap(
        spacing: 22,
        runSpacing: 10,
        children: [
          _moneyLabel('Total', total),
          _moneyLabel('Advance', advance),
          _moneyLabel('Paid', paid),
          _moneyLabel('Remaining', remaining),
          _StatusBadge('${a['paymentStatus'] ?? 'Unpaid'}'),
        ],
      ),
    );
  }

  Widget _moneyLabel(String label, double value) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(color: textSecondary, fontSize: 12),
        children: [
          TextSpan(text: '$label  '),
          TextSpan(
            text: _eur(value),
            style: const TextStyle(
              color: textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _action(
    String label,
    IconData icon,
    VoidCallback onPressed,
    bool emphasized,
  ) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: emphasized ? Colors.white : textPrimary,
        backgroundColor: emphasized ? primary : Colors.white,
        side: BorderSide(
          color: emphasized ? primary : const Color(0xFFE1E2E8),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: Icon(icon, size: 17),
      label: Text(label),
    );
  }

  Future<void> _menuAction(String action, dynamic a) async {
    switch (action) {
      case 'details':
        _details(a);
        break;
      case 'payment':
        await _collectPayment(a);
        break;
      case 'reschedule':
        await _reschedule(a);
        break;
      case 'reassign':
        await _reassign(a);
        break;
      case 'cancel':
        await _changeStatus(a, 'Cancelled');
        break;
    }
  }

  Future<void> _changeStatus(dynamic a, String newStatus) async {
    final id = _toInt(a['id']);
    if (id == null) return;

    final ok = await _confirm(
      'Update appointment?',
      'Change this appointment to ${_displayStatus(newStatus)}?',
    );
    if (!ok) return;

    try {
      await api.put(
        '/appointments/$id/status',
        data: {'status': newStatus},
      );
      await _refresh();
      _message('Appointment updated.');
    } catch (_) {
      _message('Could not update appointment.', error: true);
    }
  }

  Future<void> _reschedule(dynamic a) async {
    final id = _toInt(a['id']);
    if (id == null) return;

    final current = DateTime.tryParse('${a['startTime'] ?? ''}') ?? DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: current.isBefore(DateTime.now()) ? DateTime.now() : current,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
    );
    if (time == null || !mounted) return;

    final start = DateTime(date.year, date.month, date.day, time.hour, time.minute);

    try {
      await api.put(
        '/appointments/$id/reschedule',
        data: {'startTime': start.toIso8601String()},
      );
      await _refresh();
      _message('Appointment rescheduled.');
    } catch (_) {
      _message('Could not reschedule appointment.', error: true);
    }
  }

  Future<void> _reassign(dynamic a) async {
    final id = _toInt(a['id']);
    if (id == null) return;

    int? selected = _staffId(a);

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Reassign team member'),
          content: SizedBox(
            width: 420,
            child: DropdownButtonFormField<int?>(
              value: selected,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Team member'),
              items: <DropdownMenuItem<int?>>[
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text('Unassigned'),
                ),
                ...staff.map(
                  (x) => DropdownMenuItem<int?>(
                    value: _toInt(x['id']),
                    child: Text(_staffCatalogName(x)),
                  ),
                ),
              ],
              onChanged: (v) => setDialogState(() => selected = v),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (saved != true) return;

    try {
      await api.put(
        '/appointments/$id/assign',
        data: {'staffProfileId': selected},
      );
      await _refresh();
      _message('Team member updated.');
    } catch (_) {
      _message('Could not reassign team member.', error: true);
    }
  }

  Future<void> _collectPayment(dynamic a) async {
    final id = _toInt(a['id']);
    if (id == null) return;

    final remaining = _money(a['remainingAmount']);
    if (remaining <= 0) {
      _message('This appointment is already fully paid.');
      return;
    }

    final amount = TextEditingController(text: remaining.toStringAsFixed(2));
    String method = 'Cash';
    String type = 'Payment';

    final save = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Collect payment'),
          content: SizedBox(
            width: 440,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Remaining: ${_eur(remaining)}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: amount,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    prefixText: '€ ',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: method,
                  decoration: const InputDecoration(
                    labelText: 'Payment method',
                    border: OutlineInputBorder(),
                  ),
                  items: const ['Cash', 'Card', 'BankTransfer', 'Other']
                      .map((x) => DropdownMenuItem(value: x, child: Text(x)))
                      .toList(),
                  onChanged: (v) => setDialogState(() => method = v ?? 'Cash'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: type,
                  decoration: const InputDecoration(
                    labelText: 'Payment type',
                    border: OutlineInputBorder(),
                  ),
                  items: const ['Payment', 'Advance']
                      .map((x) => DropdownMenuItem(value: x, child: Text(x)))
                      .toList(),
                  onChanged: (v) => setDialogState(() => type = v ?? 'Payment'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Save payment'),
            ),
          ],
        ),
      ),
    );

    if (save != true) {
      amount.dispose();
      return;
    }

    final parsed = double.tryParse(amount.text.replaceAll(',', '.'));
    amount.dispose();

    if (parsed == null || parsed <= 0 || parsed > remaining) {
      _message('Enter a valid amount up to ${_eur(remaining)}.', error: true);
      return;
    }

    try {
      await api.post(
        '/appointments/$id/payments',
        data: {
          'amount': parsed,
          'method': method,
          'type': type,
        },
      );
      await _refresh();
      _message('Payment recorded.');
    } catch (_) {
      _message('Could not record payment.', error: true);
    }
  }

  Future<void> _openCreate() async {
    if (customers.isEmpty || services.isEmpty) {
      _message(
        'Customers and services are required before creating an appointment.',
        error: true,
      );
      return;
    }

    int? customerId = _toInt(customers.first['id']);
    int? selectedServiceId = _toInt(services.first['id']);
    int? selectedStaffId;
    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.now();
    final notes = TextEditingController();
    final total = TextEditingController(
      text: _servicePriceById(selectedServiceId).toStringAsFixed(2),
    );
    final advance = TextEditingController(text: '0.00');
    String paymentMethod = 'Cash';
    bool saving = false;

    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          final bottom = MediaQuery.viewInsetsOf(context).bottom;

          Future<void> chooseDate() async {
            final value = await showDatePicker(
              context: context,
              initialDate: selectedDate,
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 730)),
            );
            if (value != null) setSheetState(() => selectedDate = value);
          }

          Future<void> chooseTime() async {
            final value = await showTimePicker(
              context: context,
              initialTime: selectedTime,
            );
            if (value != null) setSheetState(() => selectedTime = value);
          }

          Future<void> save() async {
            final totalValue = double.tryParse(total.text.replaceAll(',', '.'));
            final advanceValue =
                double.tryParse(advance.text.replaceAll(',', '.')) ?? 0;

            if (customerId == null || selectedServiceId == null) {
              _message('Choose a client and service.', error: true);
              return;
            }

            if (totalValue == null || totalValue < 0) {
              _message('Enter a valid total.', error: true);
              return;
            }

            if (advanceValue < 0 || advanceValue > totalValue) {
              _message('Advance cannot be greater than total.', error: true);
              return;
            }

            final start = DateTime(
              selectedDate.year,
              selectedDate.month,
              selectedDate.day,
              selectedTime.hour,
              selectedTime.minute,
            );

            setSheetState(() => saving = true);

            try {
              await api.post(
                '/appointments',
                data: {
                  'customerId': customerId,
                  'serviceId': selectedServiceId,
                  'staffProfileId': selectedStaffId,
                  'startTime': start.toIso8601String(),
                  'notes': notes.text.trim().isEmpty ? null : notes.text.trim(),
                  'totalAmount': totalValue,
                  'advanceAmount': advanceValue > 0 ? advanceValue : null,
                  'advancePaymentMethod':
                      advanceValue > 0 ? paymentMethod : null,
                },
              );

              if (sheetContext.mounted) Navigator.pop(sheetContext, true);
            } catch (_) {
              setSheetState(() => saving = false);
              _message('Could not create appointment.', error: true);
            }
          }

          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * .92,
            ),
            padding: EdgeInsets.fromLTRB(22, 12, 22, 24 + bottom),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE1E2E8),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'New appointment',
                    style: TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w800,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<int>(
                    value: customerId,
                    isExpanded: true,
                    decoration: _input('Client'),
                    items: customers
                        .map(
                          (x) => DropdownMenuItem<int>(
                            value: _toInt(x['id']),
                            child: Text(_customerCatalogName(x)),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setSheetState(() => customerId = v),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    value: selectedServiceId,
                    isExpanded: true,
                    decoration: _input('Service'),
                    items: services
                        .map(
                          (x) => DropdownMenuItem<int>(
                            value: _toInt(x['id']),
                            child: Text('${x['name'] ?? 'Service'} • ${_eur(_money(x['price']))}'),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      setSheetState(() {
                        selectedServiceId = v;
                        total.text = _servicePriceById(v).toStringAsFixed(2);
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int?>(
                    value: selectedStaffId,
                    isExpanded: true,
                    decoration: _input('Team member'),
                    items: <DropdownMenuItem<int?>>[
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('Unassigned'),
                      ),
                      ...staff.map(
                        (x) => DropdownMenuItem<int?>(
                          value: _toInt(x['id']),
                          child: Text(_staffCatalogName(x)),
                        ),
                      ),
                    ],
                    onChanged: (v) => setSheetState(() => selectedStaffId = v),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _pickerField(
                          'Date',
                          '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                          Icons.calendar_today_outlined,
                          chooseDate,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _pickerField(
                          'Time',
                          selectedTime.format(context),
                          Icons.schedule_outlined,
                          chooseTime,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: total,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: _input('Total amount', prefix: '€ '),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: advance,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: _input('Advance / deposit', prefix: '€ '),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: paymentMethod,
                    decoration: _input('Advance payment method'),
                    items: const ['Cash', 'Card', 'BankTransfer', 'Other']
                        .map((x) => DropdownMenuItem(value: x, child: Text(x)))
                        .toList(),
                    onChanged: (v) =>
                        setSheetState(() => paymentMethod = v ?? 'Cash'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: notes,
                    minLines: 3,
                    maxLines: 5,
                    decoration: _input('Notes'),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: saving ? null : save,
                    style: FilledButton.styleFrom(
                      backgroundColor: primary,
                      padding: const EdgeInsets.symmetric(vertical: 17),
                    ),
                    icon: saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check_rounded),
                    label: Text(saving ? 'Saving...' : 'Create appointment'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    notes.dispose();
    total.dispose();
    advance.dispose();

    if (created == true) {
      await _refresh();
      _message('Appointment created.');
    }
  }

  void _details(dynamic a) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DetailsSheet(
        appointment: a,
        clientName: _clientName(a),
        serviceName: _serviceName(a),
        staffName: _staffName(a),
      ),
    );
  }

  Future<bool> _confirm(String title, String message) async {
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Confirm'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Widget _pickerField(
    String label,
    String value,
    IconData icon,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: InputDecorator(
        decoration: _input(label),
        child: Row(
          children: [
            Icon(icon, size: 18, color: primary),
            const SizedBox(width: 8),
            Expanded(child: Text(value)),
          ],
        ),
      ),
    );
  }

  InputDecoration _input(String label, {String? prefix}) {
    return InputDecoration(
      labelText: label,
      prefixText: prefix,
      filled: true,
      fillColor: const Color(0xFFF9FAFC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE3E4EA)),
      ),
    );
  }

  Widget _avatar(String name) {
    final parts = name.trim().split(' ').where((x) => x.isNotEmpty).toList();
    var initials = 'C';
    if (parts.isNotEmpty) {
      initials = parts.first.substring(0, 1);
      if (parts.length > 1) initials += parts.last.substring(0, 1);
    }
    return Container(
      width: 48,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFF0EFFF),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Text(
        initials.toUpperCase(),
        style: const TextStyle(
          color: primary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _empty() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
      decoration: _panelDecoration(radius: 20),
      child: const Column(
        children: [
          Icon(Icons.event_busy_outlined, size: 42, color: primary),
          SizedBox(height: 14),
          Text(
            'No appointments found',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 6),
          Text(
            'Try changing the selected period or filters.',
            style: TextStyle(color: textSecondary),
          ),
        ],
      ),
    );
  }

  BoxDecoration _panelDecoration({double radius = 18}) {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: const Color(0xFFE8E9EF)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: .025),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  String _clientName(dynamic a) {
    final c = a is Map ? a['client'] : null;
    if (c is Map && '${c['fullName'] ?? ''}'.trim().isNotEmpty) {
      return '${c['fullName']}';
    }
    return 'Client';
  }

  String _clientEmail(dynamic a) {
    final c = a is Map ? a['client'] : null;
    return c is Map ? '${c['email'] ?? ''}' : '';
  }

  String _clientPhone(dynamic a) {
    final c = a is Map ? a['client'] : null;
    return c is Map ? '${c['phone'] ?? ''}' : '';
  }

  String _serviceName(dynamic a) {
    final s = a is Map ? a['service'] : null;
    return s is Map ? '${s['name'] ?? 'Service'}' : 'Service';
  }

  String _staffName(dynamic a) {
    final s = a is Map ? a['staff'] : null;
    return s is Map ? '${s['fullName'] ?? 'Unassigned'}' : 'Unassigned';
  }

  int? _staffId(dynamic a) {
    final s = a is Map ? a['staff'] : null;
    return s is Map ? _toInt(s['id']) : null;
  }

  int? _serviceId(dynamic a) {
    final s = a is Map ? a['service'] : null;
    return s is Map ? _toInt(s['id']) : null;
  }

  String _date(dynamic a) {
    final d = DateTime.tryParse('${a['startTime'] ?? ''}');
    if (d == null) return '—';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  String _time(dynamic a) {
    final d = DateTime.tryParse('${a['startTime'] ?? ''}');
    if (d == null) return '—';
    return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  String _staffLabelById(int id) {
    for (final x in staff) {
      if (_toInt(x['id']) == id) return _staffCatalogName(x);
    }
    return 'Team member';
  }

  String _serviceLabelById(int id) {
    for (final x in services) {
      if (_toInt(x['id']) == id) return '${x['name'] ?? 'Service'}';
    }
    return 'Service';
  }

  String _staffCatalogName(dynamic x) {
    final direct = '${x['name'] ?? x['fullName'] ?? ''}'.trim();
    if (direct.isNotEmpty) return direct;
    return 'Team member';
  }

  String _customerCatalogName(dynamic x) {
    final full = '${x['fullName'] ?? ''}'.trim();
    if (full.isNotEmpty) return full;
    final first = '${x['firstName'] ?? ''}'.trim();
    final last = '${x['lastName'] ?? ''}'.trim();
    final name = '$first $last'.trim();
    return name.isEmpty ? 'Customer #${x['id']}' : name;
  }

  double _servicePriceById(int? id) {
    for (final x in services) {
      if (_toInt(x['id']) == id) return _money(x['price']);
    }
    return 0;
  }

  int? _toInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse('$value');
  }

  double _money(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse('$value') ?? 0;
  }

  String _eur(double value) => '€${value.toStringAsFixed(2)}';

  String _normalize(String value) {
    return value
        .replaceAll(' ', '')
        .replaceAll('_', '')
        .replaceAll('-', '')
        .toLowerCase();
  }

  String _displayStatus(String value) {
    switch (_normalize(value)) {
      case 'inprogress':
        return 'In progress';
      case 'noshow':
        return 'No show';
      case 'partiallypaid':
        return 'Partially paid';
      default:
        if (value.isEmpty) return 'Pending';
        return '${value[0].toUpperCase()}${value.substring(1)}';
    }
  }

  void _message(String text, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor:
              error ? const Color(0xFFD94343) : const Color(0xFF292B38),
          content: Text(text),
        ),
      );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final String? subtitle;

  const _SummaryCard(
    this.label,
    this.value,
    this.icon, {
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE9EAF0)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFF0EFFF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: _AppointmentsPageState.primary),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: _AppointmentsPageState.textPrimary,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: _AppointmentsPageState.textSecondary,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: Color(0xFFA0A2AD),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Info extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _Info(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: _AppointmentsPageState.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFFA0A2AD),
                  fontSize: 10.5,
                ),
              ),
              Text(
                value,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF363844),
                  fontWeight: FontWeight.w600,
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String value;

  const _StatusBadge(this.value);

  @override
  Widget build(BuildContext context) {
    final n = value
        .replaceAll(' ', '')
        .replaceAll('_', '')
        .replaceAll('-', '')
        .toLowerCase();

    Color bg;
    Color fg;

    if (n == 'paid' || n == 'completed' || n == 'confirmed') {
      bg = const Color(0xFFEAF8F0);
      fg = const Color(0xFF248A5B);
    } else if (n == 'inprogress') {
      bg = const Color(0xFFEAF4FF);
      fg = const Color(0xFF3478C8);
    } else if (n == 'cancelled' || n == 'noshow') {
      bg = const Color(0xFFFFEEEE);
      fg = const Color(0xFFD94343);
    } else {
      bg = const Color(0xFFFFF6DF);
      fg = const Color(0xFFB87A00);
    }

    String text;
    if (n == 'inprogress') {
      text = 'In progress';
    } else if (n == 'noshow') {
      text = 'No show';
    } else if (n == 'partiallypaid') {
      text = 'Partially paid';
    } else {
      text = value;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _DetailsSheet extends StatelessWidget {
  final dynamic appointment;
  final String clientName;
  final String serviceName;
  final String staffName;

  const _DetailsSheet({
    required this.appointment,
    required this.clientName,
    required this.serviceName,
    required this.staffName,
  });

  double _money(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse('$value') ?? 0;
  }

  String _eur(dynamic value) => '€${_money(value).toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    final client = appointment['client'];
    final start = DateTime.tryParse('${appointment['startTime'] ?? ''}');
    final end = DateTime.tryParse('${appointment['endTime'] ?? ''}');

    return DraggableScrollableSheet(
      initialChildSize: .82,
      minChildSize: .55,
      maxChildSize: .95,
      builder: (context, controller) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 32),
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE1E2E8),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Appointment details',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                _StatusBadge('${appointment['status'] ?? 'Pending'}'),
              ],
            ),
            const SizedBox(height: 20),
            _Detail(Icons.person_outline_rounded, 'Client', clientName),
            if (client is Map)
              _Detail(
                Icons.contact_mail_outlined,
                'Contact',
                '${client['email'] ?? '—'}  ${client['phone'] ?? ''}'.trim(),
              ),
            _Detail(Icons.content_cut_rounded, 'Service', serviceName),
            _Detail(Icons.badge_outlined, 'Team member', staffName),
            _Detail(
              Icons.calendar_today_outlined,
              'Start',
              start == null ? '—' : start.toString().substring(0, 16),
            ),
            _Detail(
              Icons.schedule_outlined,
              'End',
              end == null ? '—' : end.toString().substring(0, 16),
            ),
            _Detail(
              Icons.confirmation_number_outlined,
              'Reference',
              '${appointment['reference'] ?? '—'}',
            ),
            const SizedBox(height: 10),
            const Text(
              'Payment',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            _Detail(Icons.receipt_long_outlined, 'Total', _eur(appointment['totalAmount'])),
            _Detail(Icons.savings_outlined, 'Advance', _eur(appointment['advanceAmount'])),
            _Detail(Icons.payments_outlined, 'Paid', _eur(appointment['paidAmount'])),
            _Detail(
              Icons.account_balance_wallet_outlined,
              'Remaining',
              _eur(appointment['remainingAmount']),
            ),
            _Detail(
              Icons.verified_outlined,
              'Payment status',
              '${appointment['paymentStatus'] ?? 'Unpaid'}',
            ),
            if ('${appointment['notes'] ?? ''}'.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              _Detail(
                Icons.notes_rounded,
                'Notes',
                '${appointment['notes']}',
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _Detail(this.icon, this.title, this.value);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FC),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Icon(icon, color: _AppointmentsPageState.primary, size: 21),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF999BA8),
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    color: Color(0xFF292B38),
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
}
