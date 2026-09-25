// import 'package:flutter/material.dart';import 'package:provider/provider.dart';import '../core/api_client.dart';import '../widgets/page_header.dart';class DashboardPage extends StatefulWidget{const DashboardPage({super.key});State<DashboardPage>createState()=>_S();}class _S extends State<DashboardPage>{Map d={};List a=[];@override void didChangeDependencies(){super.didChangeDependencies();Future.wait([context.read<ApiClient>().get('/dashboard'),context.read<ApiClient>().get('/appointments',query:{'from':DateTime.now().toIso8601String()})]).then((x)=>setState((){d=x[0] as Map;a=x[1] as List;}));}@override Widget build(BuildContext c)=>ListView(padding:const EdgeInsets.all(28),children:[const PageHeader('Dashboard','Overview of your business today'),const SizedBox(height:24),Wrap(spacing:14,runSpacing:14,children:[metric('Today appointments','${d['todayAppointments']??0}',Icons.calendar_today),metric('Monthly revenue','€${d['monthRevenue']??0}',Icons.trending_up),metric('Customers','${d['customers']??0}',Icons.people_outline),metric('Net income','€${d['net']??0}',Icons.account_balance_wallet_outlined)]),const SizedBox(height:28),Text('Upcoming appointments',style:Theme.of(c).textTheme.titleLarge?.copyWith(fontWeight:FontWeight.bold)),const SizedBox(height:12),Card(child:Column(children:a.take(7).map((x)=>ListTile(leading:const CircleAvatar(child:Icon(Icons.person_outline)),title:Text(x['customer']??''),subtitle:Text('${x['service']} · ${x['staff']}'),trailing:Chip(label:Text(x['status']??'')))).toList()))]);Widget metric(String t,String v,IconData i)=>SizedBox(width:230,child:Card(child:Padding(padding:const EdgeInsets.all(20),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Icon(i),const SizedBox(height:18),Text(v,style:const TextStyle(fontSize:28,fontWeight:FontWeight.bold)),Text(t)]))));}
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api_client.dart';
import '../widgets/page_header.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool _initialized = false;
  bool _loading = true;

  Map<String, dynamic> _dashboard = {};
  List<dynamic> _appointments = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_initialized) {
      _initialized = true;
      _loadDashboard();
    }
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _loading = true;
    });

    try {
      final now = DateTime.now();

      final todayStart = DateTime(
        now.year,
        now.month,
        now.day,
      );

      final tomorrow = todayStart.add(
        const Duration(days: 1),
      );

      final results = await Future.wait([
        context.read<ApiClient>().get(
          '/dashboard',
        ),
        context.read<ApiClient>().get(
          '/appointments',
          query: {
            'from': todayStart.toIso8601String(),
            'to': tomorrow.toIso8601String(),
          },
        ),
      ]);

      if (!mounted) {
        return;
      }

      setState(() {
        _dashboard = Map<String, dynamic>.from(
          results[0] as Map,
        );

        _appointments = results[1] is List
            ? List<dynamic>.from(
                results[1] as List,
              )
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
        'Could not load dashboard.',
        error: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadDashboard,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(28),
        children: [
          const PageHeader(
            'Dashboard',
            'Overview of your business today',
          ),

          const SizedBox(height: 24),

          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(
                vertical: 100,
              ),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          else ...[
            _buildMetrics(),

            const SizedBox(height: 28),

            _buildTodaySection(),

            const SizedBox(height: 28),

            _buildUpcomingAppointments(),
          ],
        ],
      ),
    );
  }

  Widget _buildMetrics() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        double itemWidth;

        if (width >= 1100) {
          itemWidth = (width - 42) / 4;
        } else if (width >= 600) {
          itemWidth = (width - 14) / 2;
        } else {
          itemWidth = width;
        }

        return Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            _metric(
              width: itemWidth,
              title: 'Today appointments',
              value:
                  '${_dashboard['todayAppointments'] ?? 0}',
              icon: Icons.calendar_today_outlined,
            ),
            _metric(
              width: itemWidth,
              title: 'Monthly revenue',
              value: _currency(
                _dashboard['monthRevenue'],
              ),
              icon: Icons.trending_up_rounded,
            ),
            _metric(
              width: itemWidth,
              title: 'Customers',
              value:
                  '${_dashboard['customers'] ?? 0}',
              icon: Icons.people_outline_rounded,
            ),
            _metric(
              width: itemWidth,
              title: 'Net income',
              value: _currency(
                _dashboard['net'],
              ),
              icon:
                  Icons.account_balance_wallet_outlined,
            ),
          ],
        );
      },
    );
  }

  Widget _buildTodaySection() {
    final today = _dashboard['today'] is Map
        ? Map<String, dynamic>.from(
            _dashboard['today'] as Map,
          )
        : <String, dynamic>{};

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Text(
              'Today',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 18),

            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _smallMetric(
                  'Pending',
                  '${today['pending'] ?? 0}',
                  Icons.schedule_outlined,
                ),
                _smallMetric(
                  'Confirmed',
                  '${today['confirmed'] ?? 0}',
                  Icons.check_circle_outline,
                ),
                _smallMetric(
                  'In progress',
                  '${today['inProgress'] ?? 0}',
                  Icons.play_circle_outline,
                ),
                _smallMetric(
                  'Completed',
                  '${today['completed'] ?? 0}',
                  Icons.task_alt_rounded,
                ),
              ],
            ),

            const SizedBox(height: 22),

            const Divider(),

            const SizedBox(height: 16),

            Wrap(
              spacing: 30,
              runSpacing: 16,
              children: [
                _financeValue(
                  'Expected revenue',
                  _currency(
                    _dashboard[
                        'expectedMonthRevenue'],
                  ),
                ),
                _financeValue(
                  'Outstanding',
                  _currency(
                    _dashboard[
                        'outstandingAmount'],
                  ),
                ),
                _financeValue(
                  'Expenses',
                  _currency(
                    _dashboard['monthExpenses'],
                  ),
                ),
                _financeValue(
                  'Refunds',
                  _currency(
                    _dashboard['refunds'],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingAppointments() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const Text(
          'Today appointments',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),

        const SizedBox(height: 12),

        if (_appointments.isEmpty)
          Card(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(
                vertical: 45,
                horizontal: 20,
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons
                          .event_available_outlined,
                      size: 40,
                      color:
                          Colors.grey.shade400,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'No appointments today',
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: _appointments
                  .take(7)
                  .map(
                    (appointment) =>
                        _appointmentTile(
                      appointment,
                    ),
                  )
                  .toList(),
            ),
          ),
      ],
    );
  }

  Widget _appointmentTile(
    dynamic appointment,
  ) {
    final client =
        appointment['client'] is Map
            ? appointment['client'] as Map
            : {};

    final service =
        appointment['service'] is Map
            ? appointment['service'] as Map
            : {};

    final staff =
        appointment['staff'] is Map
            ? appointment['staff'] as Map
            : {};

    final startTime = DateTime.tryParse(
      appointment['startTime']?.toString() ??
          '',
    );

    final clientName =
        client['fullName']?.toString() ??
            'Unknown client';

    final serviceName =
        service['name']?.toString() ??
            'Unknown service';

    final staffName =
        staff['fullName']?.toString() ??
            'Unassigned';

    return Column(
      children: [
        ListTile(
          contentPadding:
              const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 8,
          ),
          leading: CircleAvatar(
            backgroundColor:
                const Color(0xFFF0EFFF),
            child: Text(
              _initials(clientName),
              style: const TextStyle(
                color: Color(0xFF6C63FF),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          title: Text(
            clientName,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
            ),
          ),
          subtitle: Padding(
            padding:
                const EdgeInsets.only(top: 4),
            child: Text(
              '$serviceName • $staffName',
            ),
          ),
          trailing: SizedBox(
            width: 150,
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              crossAxisAlignment:
                  CrossAxisAlignment.end,
              children: [
                Text(
                  startTime == null
                      ? '—'
                      : _formatTime(startTime),
                  style: const TextStyle(
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                _statusBadge(
                  appointment['status']
                          ?.toString() ??
                      'Pending',
                ),
              ],
            ),
          ),
        ),
        const Divider(height: 1),
      ],
    );
  }

  Widget _metric({
    required double width,
    required String title,
    required String value,
    required IconData icon,
  }) {
    return SizedBox(
      width: width,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color:
                      const Color(0xFFF0EFFF),
                  borderRadius:
                      BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color:
                      const Color(0xFF6C63FF),
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
                      style:
                          const TextStyle(
                        fontSize: 23,
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      title,
                      style:
                          const TextStyle(
                        color:
                            Color(0xFF77798A),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _smallMetric(
    String label,
    String value,
    IconData icon,
  ) {
    return Container(
      width: 165,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FC),
        borderRadius:
            BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: const Color(0xFF6C63FF),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color:
                      Color(0xFF77798A),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _financeValue(
    String label,
    String value,
  ) {
    return SizedBox(
      width: 180,
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF77798A),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 17,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    final normalized = status
        .replaceAll(' ', '')
        .toLowerCase();

    Color background;
    Color foreground;

    switch (normalized) {
      case 'completed':
      case 'confirmed':
        background =
            const Color(0xFFEAF8F0);
        foreground =
            const Color(0xFF248A5B);
        break;

      case 'inprogress':
        background =
            const Color(0xFFEAF4FF);
        foreground =
            const Color(0xFF3478C8);
        break;

      case 'cancelled':
      case 'noshow':
        background =
            const Color(0xFFFFEEEE);
        foreground =
            const Color(0xFFD94343);
        break;

      default:
        background =
            const Color(0xFFFFF6DF);
        foreground =
            const Color(0xFFB87A00);
    }

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Text(
        status == 'InProgress'
            ? 'In progress'
            : status,
        style: TextStyle(
          color: foreground,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name
        .trim()
        .split(' ')
        .where((x) => x.isNotEmpty)
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

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  String _currency(dynamic value) {
    final amount = value is num
        ? value.toDouble()
        : double.tryParse(
              value?.toString() ?? '',
            ) ??
            0;

    return '€${amount.toStringAsFixed(2)}';
  }

  void _showMessage(
    String message, {
    bool error = false,
  }) {
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