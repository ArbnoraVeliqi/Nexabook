// import 'package:flutter/material.dart';import 'package:provider/provider.dart';import '../core/api_client.dart';import '../widgets/page_header.dart';class PaymentsPage extends StatefulWidget{const PaymentsPage({super.key});State<PaymentsPage>createState()=>_S();}class _S extends State<PaymentsPage>{List data=[];bool loading=true;@override void didChangeDependencies(){super.didChangeDependencies();load();}Future load()async{try{final x=await context.read<ApiClient>().get('/finance/payments');if(mounted)setState((){data=x;loading=false;});}catch(_){if(mounted)setState(()=>loading=false);}}@override Widget build(BuildContext c)=>ListView(padding:const EdgeInsets.all(28),children:[PageHeader('Payments & Deposits','Track payments, deposits and transaction history',action:FilledButton.icon(onPressed:()=>showDialog(context:c,builder:(_)=>AlertDialog(title:const Text('New Payments & Deposit'),content:const Text('Create form is connected through the API layer and can be extended with business-specific fields.'),actions:[TextButton(onPressed:()=>Navigator.pop(c),child:const Text('Close'))])),icon:const Icon(Icons.add),label:const Text('Add new'))),const SizedBox(height:22),Card(child:loading?const Padding(padding:EdgeInsets.all(40),child:Center(child:CircularProgressIndicator())):data.isEmpty?const Padding(padding:EdgeInsets.all(40),child:Center(child:Text('No records found'))):SingleChildScrollView(scrollDirection:Axis.horizontal,child:DataTable(columns:const[DataColumn(label:Text('Name / Reference')),DataColumn(label:Text('Details')),DataColumn(label:Text('Status')),DataColumn(label:Text('Actions'))],rows:data.map((x)=>DataRow(cells:[DataCell(Text((x['transactionReference']??'—').toString())),DataCell(Text((x['amount']??'—').toString())),DataCell(Text((x['status']??x['paymentStatus']??x['isActive']??'Active').toString())),const DataCell(Icon(Icons.more_horiz))])).toList())))]);}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api_client.dart';
import '../widgets/page_header.dart';

class PaymentsPage extends StatefulWidget {
  const PaymentsPage({super.key});

  @override
  State<PaymentsPage> createState() => _PaymentsPageState();
}

class _PaymentsPageState extends State<PaymentsPage> {
  final TextEditingController _searchController = TextEditingController();

  bool _initialized = false;
  bool _loading = true;

  List<dynamic> _payments = [];

  String _search = '';
  String _typeFilter = 'All';
  String _methodFilter = 'All methods';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_initialized) {
      _initialized = true;
      _loadPayments();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPayments() async {
    if (mounted) {
      setState(() {
        _loading = true;
      });
    }

    try {
      final result =
          await context.read<ApiClient>().get('/finance/payments');

      if (!mounted) {
        return;
      }

      setState(() {
        _payments =
            result is List ? List<dynamic>.from(result) : [];

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
        'Could not load payments.',
        error: true,
      );
    }
  }

  List<dynamic> get _filteredPayments {
    final query = _search.trim().toLowerCase();

    return _payments.where((payment) {
      final reference = _reference(payment).toLowerCase();
      final type = _paymentType(payment).toLowerCase();
      final method = _paymentMethod(payment).toLowerCase();
      final customer = _customerName(payment).toLowerCase();
      final notes = _text(payment['notes']).toLowerCase();

      final matchesSearch = query.isEmpty ||
          reference.contains(query) ||
          type.contains(query) ||
          method.contains(query) ||
          customer.contains(query) ||
          notes.contains(query);

      final matchesType = _typeFilter == 'All' ||
          type == _typeFilter.toLowerCase();

      final matchesMethod = _methodFilter == 'All methods' ||
          method == _methodFilter.toLowerCase();

      return matchesSearch &&
          matchesType &&
          matchesMethod;
    }).toList();
  }

  List<String> get _methods {
    final methods = _payments
        .map(_paymentMethod)
        .where((method) => method.isNotEmpty && method != '—')
        .toSet()
        .toList();

    methods.sort();

    return methods;
  }

  double get _paymentsTotal {
    return _payments
        .where(
          (payment) =>
              _paymentType(payment).toLowerCase() == 'payment',
        )
        .fold<double>(
          0,
          (total, payment) =>
              total + _amount(payment),
        );
  }

  double get _advancesTotal {
    return _payments
        .where(
          (payment) =>
              _paymentType(payment).toLowerCase() == 'advance',
        )
        .fold<double>(
          0,
          (total, payment) =>
              total + _amount(payment),
        );
  }

  double get _refundsTotal {
    return _payments
        .where(
          (payment) =>
              _paymentType(payment).toLowerCase() == 'refund',
        )
        .fold<double>(
          0,
          (total, payment) =>
              total + _amount(payment),
        );
  }

  double get _netCollected {
    return _paymentsTotal + _advancesTotal - _refundsTotal;
  }

  @override
  Widget build(BuildContext context) {
    final payments = _filteredPayments;

    return RefreshIndicator(
      onRefresh: _loadPayments,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(28),
        children: [
          PageHeader(
            'Payments & Deposits',
            'Track payments, deposits and transaction history',
            action: OutlinedButton.icon(
              onPressed: _loadPayments,
              icon: const Icon(
                Icons.refresh_rounded,
                size: 19,
              ),
              label: const Text('Refresh'),
            ),
          ),

          const SizedBox(height: 26),

          _buildSummary(),

          const SizedBox(height: 22),

          _buildToolbar(),

          const SizedBox(height: 16),

          if (_loading)
            _buildLoading()
          else if (payments.isEmpty)
            _buildEmpty()
          else
            _buildPaymentsTable(payments),
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
              width: cardWidth,
              title: 'Net collected',
              value: _money(_netCollected),
              icon: Icons.account_balance_wallet_outlined,
              background: const Color(0xFFF0EFFF),
              iconColor: const Color(0xFF6C63FF),
            ),
            _summaryCard(
              width: cardWidth,
              title: 'Payments',
              value: _money(_paymentsTotal),
              icon: Icons.payments_outlined,
              background: const Color(0xFFEAF8F0),
              iconColor: const Color(0xFF279466),
            ),
            _summaryCard(
              width: cardWidth,
              title: 'Deposits',
              value: _money(_advancesTotal),
              icon: Icons.savings_outlined,
              background: const Color(0xFFFFF4E8),
              iconColor: const Color(0xFFE28A36),
            ),
            _summaryCard(
              width: cardWidth,
              title: 'Refunds',
              value: _money(_refundsTotal),
              icon: Icons.keyboard_return_rounded,
              background: const Color(0xFFFFECEE),
              iconColor: const Color(0xFFD95864),
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
    required Color background,
    required Color iconColor,
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
                color: background,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                icon,
                color: iconColor,
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF77798A),
                      fontSize: 13,
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
          final compact = constraints.maxWidth < 950;

          if (compact) {
            return Column(
              children: [
                _buildSearch(),
                const SizedBox(height: 12),
                _buildMethodFilter(),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: _buildTypeFilters(),
                  ),
                ),
              ],
            );
          }

          return Row(
            children: [
              Expanded(
                child: _buildSearch(),
              ),
              const SizedBox(width: 14),
              SizedBox(
                width: 190,
                child: _buildMethodFilter(),
              ),
              const SizedBox(width: 14),
              _buildTypeFilters(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSearch() {
    return TextField(
      controller: _searchController,
      onChanged: (value) {
        setState(() {
          _search = value;
        });
      },
      decoration: InputDecoration(
        hintText: 'Search transaction, customer or notes...',
        prefixIcon: const Icon(
          Icons.search_rounded,
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
      ),
    );
  }

  Widget _buildMethodFilter() {
    final values = [
      'All methods',
      ..._methods,
    ];

    if (!values.contains(_methodFilter)) {
      _methodFilter = 'All methods';
    }

    return DropdownButtonFormField<String>(
      value: _methodFilter,
      isExpanded: true,
      decoration: InputDecoration(
        prefixIcon: const Icon(
          Icons.credit_card_rounded,
          size: 19,
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
      ),
      items: values.map((method) {
        return DropdownMenuItem<String>(
          value: method,
          child: Text(
            _prettyMethod(method),
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: (value) {
        if (value == null) {
          return;
        }

        setState(() {
          _methodFilter = value;
        });
      },
    );
  }

  Widget _buildTypeFilters() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _typeButton('All'),
        const SizedBox(width: 7),
        _typeButton('Payment'),
        const SizedBox(width: 7),
        _typeButton('Advance'),
        const SizedBox(width: 7),
        _typeButton('Refund'),
      ],
    );
  }

  Widget _typeButton(String value) {
    final selected = _typeFilter == value;

    return InkWell(
      borderRadius: BorderRadius.circular(11),
      onTap: () {
        setState(() {
          _typeFilter = value;
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
          value == 'Advance' ? 'Deposit' : value,
          style: TextStyle(
            color: selected
                ? Colors.white
                : const Color(0xFF555766),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentsTable(
    List<dynamic> payments,
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
          _buildTableHeader(),

          for (int index = 0;
              index < payments.length;
              index++) ...[
            _buildPaymentRow(payments[index]),
            if (index != payments.length - 1)
              const Divider(
                height: 1,
                indent: 20,
                endIndent: 20,
              ),
          ],

          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 13,
            ),
            color: const Color(0xFFFBFBFD),
            child: Text(
              '${payments.length} ${payments.length == 1 ? 'transaction' : 'transactions'} shown',
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
            flex: 3,
            child: Text(
              'TRANSACTION',
              style: _paymentHeaderStyle,
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              'APPOINTMENT / CUSTOMER',
              style: _paymentHeaderStyle,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'METHOD',
              style: _paymentHeaderStyle,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'DATE',
              style: _paymentHeaderStyle,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'AMOUNT',
              style: _paymentHeaderStyle,
            ),
          ),
          SizedBox(width: 50),
        ],
      ),
    );
  }

  Widget _buildPaymentRow(dynamic payment) {
    final type = _paymentType(payment);
    final amount = _amount(payment);
    final method = _paymentMethod(payment);
    final customer = _customerName(payment);
    final appointmentReference =
        _appointmentReference(payment);

    return InkWell(
      onTap: () {
        _showPaymentDetails(payment);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 17,
        ),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  _transactionIcon(type),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          _displayType(type),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _reference(payment),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF9092A1),
                            fontSize: 11,
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    customer.isEmpty
                        ? 'Customer not available'
                        : customer,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    appointmentReference,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF9092A1),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: _methodBadge(method),
              ),
            ),

            Expanded(
              flex: 2,
              child: Text(
                _formatDate(payment['createdAt']),
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF666875),
                ),
              ),
            ),

            Expanded(
              flex: 2,
              child: Text(
                '${type.toLowerCase() == 'refund' ? '-' : ''}${_money(amount)}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: type.toLowerCase() == 'refund'
                      ? const Color(0xFFD95864)
                      : const Color(0xFF252631),
                ),
              ),
            ),

            SizedBox(
              width: 50,
              child: IconButton(
                tooltip: 'View details',
                onPressed: () {
                  _showPaymentDetails(payment);
                },
                icon: const Icon(
                  Icons.more_horiz_rounded,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _transactionIcon(String type) {
    IconData icon;
    Color background;
    Color foreground;

    switch (type.toLowerCase()) {
      case 'advance':
        icon = Icons.savings_outlined;
        background = const Color(0xFFFFF4E8);
        foreground = const Color(0xFFE28A36);
        break;

      case 'refund':
        icon = Icons.keyboard_return_rounded;
        background = const Color(0xFFFFECEE);
        foreground = const Color(0xFFD95864);
        break;

      default:
        icon = Icons.payments_outlined;
        background = const Color(0xFFEAF8F0);
        foreground = const Color(0xFF279466);
    }

    return Container(
      width: 43,
      height: 43,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Icon(
        icon,
        size: 20,
        color: foreground,
      ),
    );
  }

  Widget _methodBadge(String method) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _prettyMethod(method),
        style: const TextStyle(
          color: Color(0xFF5F6170),
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _showPaymentDetails(dynamic payment) {
    final type = _paymentType(payment);
    final customer = _customerName(payment);
    final notes = _text(payment['notes']);

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
              maxWidth: 570,
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
                      _transactionIcon(type),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              _displayType(type),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _reference(payment),
                              style: const TextStyle(
                                color: Color(0xFF858795),
                                fontSize: 12,
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

                  const SizedBox(height: 22),
                  const Divider(),
                  const SizedBox(height: 18),

                  Row(
                    children: [
                      Expanded(
                        child: _detailBox(
                          'Amount',
                          _money(_amount(payment)),
                          Icons.euro_rounded,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _detailBox(
                          'Method',
                          _prettyMethod(
                            _paymentMethod(payment),
                          ),
                          Icons.credit_card_rounded,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: _detailBox(
                          'Customer',
                          customer.isEmpty ? '—' : customer,
                          Icons.person_outline_rounded,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _detailBox(
                          'Appointment',
                          _appointmentReference(payment),
                          Icons.event_outlined,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  _detailBox(
                    'Created',
                    _formatDateTime(payment['createdAt']),
                    Icons.schedule_rounded,
                  ),

                  if (notes.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const Text(
                      'Notes',
                      style: TextStyle(
                        color: Color(0xFF858795),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      notes,
                      style: const TextStyle(
                        color: Color(0xFF555766),
                        height: 1.5,
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton(
                      onPressed: () {
                        Navigator.pop(dialogContext);
                      },
                      child: const Text('Close'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _detailBox(
    String label,
    String value,
    IconData icon,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FC),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 19,
            color: const Color(0xFF6C63FF),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF9092A1),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
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

  Widget _buildEmpty() {
    final filtered =
        _search.isNotEmpty ||
        _typeFilter != 'All' ||
        _methodFilter != 'All methods';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 70,
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
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: const Color(0xFFF0EFFF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.payments_outlined,
              color: Color(0xFF6C63FF),
              size: 31,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            filtered
                ? 'No transactions found'
                : 'No payments yet',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            filtered
                ? 'Try changing your search or filters.'
                : 'Payments and deposits will appear here.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF77798A),
            ),
          ),
        ],
      ),
    );
  }

  String _paymentType(dynamic payment) {
    final value = payment['type'];

    if (value is int) {
      switch (value) {
        case 0:
          return 'Advance';
        case 1:
          return 'Payment';
        case 2:
          return 'Refund';
      }
    }

    final text = _text(value);

    if (text == '0') {
      return 'Advance';
    }

    if (text == '1') {
      return 'Payment';
    }

    if (text == '2') {
      return 'Refund';
    }

    return text.isEmpty ? 'Payment' : text;
  }

  String _paymentMethod(dynamic payment) {
    final value = payment['method'];

    if (value is int) {
      switch (value) {
        case 0:
          return 'Cash';
        case 1:
          return 'Card';
        case 2:
          return 'BankTransfer';
        case 3:
          return 'Other';
      }
    }

    final text = _text(value);

    if (text == '0') {
      return 'Cash';
    }

    if (text == '1') {
      return 'Card';
    }

    if (text == '2') {
      return 'BankTransfer';
    }

    if (text == '3') {
      return 'Other';
    }

    return text.isEmpty ? '—' : text;
  }

  String _prettyMethod(String method) {
    if (method == 'All methods') {
      return method;
    }

    if (method.toLowerCase() == 'banktransfer') {
      return 'Bank transfer';
    }

    return method;
  }

  String _displayType(String type) {
    if (type.toLowerCase() == 'advance') {
      return 'Deposit';
    }

    return type;
  }

  double _amount(dynamic payment) {
    return _toDouble(payment['amount']);
  }

  String _reference(dynamic payment) {
    final transactionReference =
        _text(payment['transactionReference']);

    if (transactionReference.isNotEmpty) {
      return transactionReference;
    }

    final id = payment['id'];

    if (id != null) {
      return 'PAY-${id.toString().padLeft(5, '0')}';
    }

    return 'Payment';
  }

  String _appointmentReference(dynamic payment) {
    final appointment = payment['appointment'];

    if (appointment is Map) {
      final reference = _text(appointment['reference']);

      if (reference.isNotEmpty) {
        return reference;
      }
    }

    final reference =
        _text(payment['appointmentReference']);

    if (reference.isNotEmpty) {
      return reference;
    }

    final appointmentId = payment['appointmentId'];

    if (appointmentId != null) {
      return 'Appointment #$appointmentId';
    }

    return '—';
  }

  String _customerName(dynamic payment) {
    final appointment = payment['appointment'];

    if (appointment is Map) {
      final customer = appointment['customer'];

      if (customer is Map) {
        final fullName = _text(customer['fullName']);

        if (fullName.isNotEmpty) {
          return fullName;
        }

        final firstName = _text(customer['firstName']);
        final lastName = _text(customer['lastName']);

        final name = '$firstName $lastName'.trim();

        if (name.isNotEmpty) {
          return name;
        }
      }

      final client = appointment['client'];

      if (client is Map) {
        final fullName = _text(client['fullName']);

        if (fullName.isNotEmpty) {
          return fullName;
        }
      }
    }

    final direct =
        _text(payment['customerName']);

    return direct;
  }

  String _formatDate(dynamic value) {
    final date = DateTime.tryParse(
      value?.toString() ?? '',
    );

    if (date == null) {
      return '—';
    }

    return '${_two(date.day)}.${_two(date.month)}.${date.year}';
  }

  String _formatDateTime(dynamic value) {
    final date = DateTime.tryParse(
      value?.toString() ?? '',
    );

    if (date == null) {
      return '—';
    }

    return '${_two(date.day)}.${_two(date.month)}.${date.year} '
        '${_two(date.hour)}:${_two(date.minute)}';
  }

  String _two(int value) {
    return value.toString().padLeft(2, '0');
  }

  String _money(double value) {
    return '€${value.toStringAsFixed(2)}';
  }

  String _text(dynamic value) {
    if (value == null) {
      return '';
    }

    return value.toString().trim();
  }

  double _toDouble(dynamic value) {
    if (value == null) {
      return 0;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString()) ?? 0;
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

const TextStyle _paymentHeaderStyle = TextStyle(
  color: Color(0xFF858795),
  fontSize: 10,
  fontWeight: FontWeight.w700,
  letterSpacing: 0.6,
);