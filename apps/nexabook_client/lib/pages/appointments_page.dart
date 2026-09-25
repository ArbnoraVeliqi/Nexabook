import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api_client.dart';

class AppointmentsPage extends StatefulWidget {
  const AppointmentsPage({super.key});

  @override
  State<AppointmentsPage> createState() => _AppointmentsPageState();
}

class _AppointmentsPageState extends State<AppointmentsPage> {
  List<dynamic> _appointments = [];

  bool _loading = true;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_initialized) {
      _initialized = true;
      _loadAppointments();
    }
  }

  Future<void> _loadAppointments() async {
    setState(() {
      _loading = true;
    });

    try {
      final response = await context
          .read<ApiClient>()
          .get('/appointments');

      if (!mounted) {
        return;
      }

      setState(() {
        if (response is List) {
          _appointments = List<dynamic>.from(response);
        } else {
          _appointments = [];
        }

        _loading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _appointments = [];
        _loading = false;
      });

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text(
              'Could not load appointments.',
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadAppointments,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            20,
            22,
            20,
            110,
          ),
          children: [
            _buildHeader(),

            const SizedBox(height: 22),

            if (_loading)
              _buildLoading()
            else if (_appointments.isEmpty)
              _buildEmpty()
            else
              ..._appointments.map(
                (appointment) => _buildAppointmentCard(
                  appointment,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'My appointments',
          style: TextStyle(
            color: Color(0xFF20212A),
            fontSize: 27,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          '${_appointments.length} upcoming and previous bookings',
          style: const TextStyle(
            color: Color(0xFF8A8C99),
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildAppointmentCard(
    dynamic appointment,
  ) {
    if (appointment is! Map) {
      return const SizedBox.shrink();
    }

    final serviceName = _getServiceName(
      appointment,
    );

    final staffName = _getStaffName(
      appointment,
    );

    final status = _text(
      appointment['status'],
      fallback: 'Pending',
    );

    final paymentStatus = _text(
      appointment['paymentStatus'],
      fallback: 'Pending',
    );

    final startAt = _getDateTime(
      appointment['startAt'] ??
          appointment['startTime'] ??
          appointment['appointmentDate'] ??
          appointment['date'],
    );

    final service = appointment['service'];

    dynamic priceValue =
        appointment['totalAmount'] ??
        appointment['total'] ??
        appointment['amount'] ??
        appointment['price'];

    dynamic durationValue =
        appointment['durationMinutes'] ??
        appointment['duration'];

    dynamic depositValue =
        appointment['depositAmount'] ??
        appointment['deposit'];

    if (service is Map) {
      priceValue ??=
          service['price'] ??
          service['amount'];

      durationValue ??=
          service['durationMinutes'] ??
          service['duration'];

      depositValue ??=
          service['depositAmount'] ??
          service['deposit'];
    }

    final total = _money(
      priceValue,
    );

    final deposit = _money(
      depositValue,
    );

    final duration = _number(
      durationValue,
    );

    return Container(
      margin: const EdgeInsets.only(
        bottom: 12,
      ),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFEBEBF0),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x07000000),
            blurRadius: 15,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0EFFF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.spa_outlined,
                  color: Color(0xFF6C63FF),
                  size: 20,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Text(
                  serviceName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF292A32),
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              const SizedBox(width: 8),

              _buildStatus(
                status,
              ),
            ],
          ),

          if (startAt != null) ...[
            const SizedBox(height: 13),

            _buildDateTimeRow(
              startAt,
              duration,
            ),
          ],

          if (staffName.isNotEmpty) ...[
            const SizedBox(height: 8),

            Row(
              children: [
                const Icon(
                  Icons.person_outline_rounded,
                  size: 16,
                  color: Color(0xFF8D8E99),
                ),

                const SizedBox(width: 6),

                Expanded(
                  child: Text(
                    staffName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF777884),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],

          if (total.isNotEmpty ||
              (deposit.isNotEmpty &&
                  deposit != '0.00') ||
              paymentStatus.isNotEmpty) ...[
            const SizedBox(height: 13),

            const Divider(
              height: 1,
              color: Color(0xFFF0F0F4),
            ),

            const SizedBox(height: 11),

            _buildPaymentRow(
              total: total,
              deposit: deposit,
              paymentStatus: paymentStatus,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDateTimeRow(
    DateTime startAt,
    String duration,
  ) {
    return Row(
      children: [
        const Icon(
          Icons.calendar_today_outlined,
          size: 14,
          color: Color(0xFF8D8E99),
        ),

        const SizedBox(width: 6),

        Flexible(
          child: Text(
            _formatDate(startAt),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF62636E),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),

        _dot(),

        const Icon(
          Icons.schedule_rounded,
          size: 14,
          color: Color(0xFF8D8E99),
        ),

        const SizedBox(width: 5),

        Text(
          _formatTime(startAt),
          style: const TextStyle(
            color: Color(0xFF62636E),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),

        if (duration.isNotEmpty) ...[
          _dot(),

          const Icon(
            Icons.timelapse_rounded,
            size: 14,
            color: Color(0xFF8D8E99),
          ),

          const SizedBox(width: 5),

          Text(
            '$duration min',
            style: const TextStyle(
              color: Color(0xFF62636E),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  Widget _dot() {
    return const Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 7,
      ),
      child: Text(
        '•',
        style: TextStyle(
          color: Color(0xFFB5B6BE),
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _buildPaymentRow({
    required String total,
    required String deposit,
    required String paymentStatus,
  }) {
    return Row(
      children: [
        if (total.isNotEmpty)
          Text(
            '€$total',
            style: const TextStyle(
              color: Color(0xFF292A32),
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),

        if (deposit.isNotEmpty &&
            deposit != '0.00') ...[
          const SizedBox(width: 12),

          Flexible(
            child: Text(
              'Deposit €$deposit',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF858691),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],

        const Spacer(),

        _paymentBadge(
          paymentStatus,
        ),
      ],
    );
  }

  Widget _buildStatus(
    String status,
  ) {
    final normalized = status
        .toLowerCase()
        .replaceAll(' ', '');

    Color background;
    Color foreground;

    if (normalized == 'confirmed') {
      background = const Color(0xFFE9F8F0);
      foreground = const Color(0xFF258A58);
    } else if (normalized == 'completed') {
      background = const Color(0xFFECEBFF);
      foreground = const Color(0xFF6259D7);
    } else if (normalized == 'cancelled' ||
        normalized == 'canceled') {
      background = const Color(0xFFFFECEC);
      foreground = const Color(0xFFC74C4C);
    } else if (normalized == 'inprogress') {
      background = const Color(0xFFFFF5DF);
      foreground = const Color(0xFFA36A13);
    } else {
      background = const Color(0xFFF2F2F5);
      foreground = const Color(0xFF737580);
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: foreground,
          fontSize: 9,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _paymentBadge(
    String status,
  ) {
    final normalized = status
        .toLowerCase()
        .replaceAll(' ', '');

    Color background;
    Color foreground;

    if (normalized == 'paid') {
      background = const Color(0xFFE9F8F0);
      foreground = const Color(0xFF258A58);
    } else if (normalized == 'partiallypaid' ||
        normalized == 'partial') {
      background = const Color(0xFFFFF5DF);
      foreground = const Color(0xFFA36A13);
    } else if (normalized == 'refunded') {
      background = const Color(0xFFECEBFF);
      foreground = const Color(0xFF6259D7);
    } else if (normalized == 'failed') {
      background = const Color(0xFFFFECEC);
      foreground = const Color(0xFFC74C4C);
    } else {
      background = const Color(0xFFFFF1E8);
      foreground = const Color(0xFFB86724);
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: foreground,
          fontSize: 9,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return const Padding(
      padding: EdgeInsets.symmetric(
        vertical: 80,
      ),
      child: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildEmpty() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 30,
        vertical: 50,
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
          CircleAvatar(
            radius: 30,
            backgroundColor: Color(0xFFF0EFFF),
            child: Icon(
              Icons.calendar_month_outlined,
              color: Color(0xFF6C63FF),
              size: 28,
            ),
          ),

          SizedBox(height: 16),

          Text(
            'No appointments yet',
            style: TextStyle(
              color: Color(0xFF292A32),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),

          SizedBox(height: 6),

          Text(
            'Your bookings will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF8C8E9A),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  String _getServiceName(
    Map appointment,
  ) {
    final service = appointment['service'];

    if (service is Map) {
      return _text(
        service['name'],
        fallback: 'Service',
      );
    }

    if (service is String &&
        service.trim().isNotEmpty) {
      return service.trim();
    }

    return _text(
      appointment['serviceName'],
      fallback: _text(
        appointment['title'],
        fallback: 'Service',
      ),
    );
  }

  String _getStaffName(
    Map appointment,
  ) {
    final staff =
        appointment['staff'] ??
        appointment['staffProfile'];

    if (staff is Map) {
      final directName = _text(
        staff['name'],
      );

      if (directName.isNotEmpty) {
        return directName;
      }

      final user = staff['user'];

      if (user is Map) {
        final firstName = _text(
          user['firstName'],
        );

        final lastName = _text(
          user['lastName'],
        );

        return '$firstName $lastName'.trim();
      }

      final firstName = _text(
        staff['firstName'],
      );

      final lastName = _text(
        staff['lastName'],
      );

      return '$firstName $lastName'.trim();
    }

    if (staff is String) {
      return staff.trim();
    }

    return _text(
      appointment['staffName'],
    );
  }

  String _text(
    dynamic value, {
    String fallback = '',
  }) {
    if (value == null) {
      return fallback;
    }

    if (value is String) {
      final text = value.trim();

      return text.isEmpty
          ? fallback
          : text;
    }

    if (value is num ||
        value is bool) {
      return value.toString();
    }

    return fallback;
  }

  DateTime? _getDateTime(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      return DateTime.tryParse(
        value,
      );
    }

    return DateTime.tryParse(
      value.toString(),
    );
  }

  String _money(
    dynamic value,
  ) {
    if (value == null) {
      return '';
    }

    if (value is num) {
      return value
          .toDouble()
          .toStringAsFixed(2);
    }

    final parsed = double.tryParse(
      value.toString(),
    );

    if (parsed == null) {
      return '';
    }

    return parsed.toStringAsFixed(2);
  }

  String _number(
    dynamic value,
  ) {
    if (value == null) {
      return '';
    }

    if (value is int) {
      return value.toString();
    }

    if (value is num) {
      return value
          .toInt()
          .toString();
    }

    final parsed = int.tryParse(
      value.toString(),
    );

    return parsed?.toString() ?? '';
  }

  String _formatDate(
    DateTime value,
  ) {
    const months = [
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

    return '${value.day} '
        '${months[value.month - 1]} '
        '${value.year}';
  }

  String _formatTime(
    DateTime value,
  ) {
    final hour = value.hour
        .toString()
        .padLeft(2, '0');

    final minute = value.minute
        .toString()
        .padLeft(2, '0');

    return '$hour:$minute';
  }
}