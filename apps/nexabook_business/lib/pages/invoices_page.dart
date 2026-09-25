// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';

// import '../core/api_client.dart';
// import '../widgets/page_header.dart';

// class InvoicesPage extends StatefulWidget {
//   const InvoicesPage({super.key});

//   @override
//   State<InvoicesPage> createState() =>
//       _InvoicesPageState();
// }

// class _InvoicesPageState
//     extends State<InvoicesPage> {
//   bool _initialized = false;
//   bool _loading = true;

//   List<dynamic> _invoices = [];
//   List<dynamic> _appointments = [];

//   final TextEditingController
//       _searchController =
//       TextEditingController();

//   @override
//   void didChangeDependencies() {
//     super.didChangeDependencies();

//     if (!_initialized) {
//       _initialized = true;
//       _load();
//     }
//   }

//   @override
//   void dispose() {
//     _searchController.dispose();
//     super.dispose();
//   }

//   Future<void> _load() async {
//     setState(() {
//       _loading = true;
//     });

//     try {
//       final results = await Future.wait([
//         context
//             .read<ApiClient>()
//             .get('/finance/invoices'),
//         context
//             .read<ApiClient>()
//             .get('/appointments'),
//       ]);

//       if (!mounted) {
//         return;
//       }

//       setState(() {
//         _invoices = results[0] is List
//             ? List<dynamic>.from(
//                 results[0] as List,
//               )
//             : [];

//         _appointments = results[1] is List
//             ? List<dynamic>.from(
//                 results[1] as List,
//               )
//             : [];

//         _loading = false;
//       });
//     } catch (_) {
//       if (!mounted) {
//         return;
//       }

//       setState(() {
//         _loading = false;
//       });

//       _showMessage(
//         'Could not load invoices.',
//         error: true,
//       );
//     }
//   }

//   List<dynamic> get _filteredInvoices {
//     final search = _searchController.text
//         .trim()
//         .toLowerCase();

//     if (search.isEmpty) {
//       return _invoices;
//     }

//     return _invoices.where(
//       (invoice) {
//         final appointment =
//             invoice['appointment'];

//         final reference =
//             appointment is Map
//                 ? appointment['reference']
//                         ?.toString() ??
//                     ''
//                 : '';

//         final number =
//             invoice['number']
//                     ?.toString() ??
//                 '';

//         return number
//                 .toLowerCase()
//                 .contains(search) ||
//             reference
//                 .toLowerCase()
//                 .contains(search);
//       },
//     ).toList();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return RefreshIndicator(
//       onRefresh: _load,
//       child: ListView(
//         physics:
//             const AlwaysScrollableScrollPhysics(),
//         padding: const EdgeInsets.all(28),
//         children: [
//           PageHeader(
//             'Invoices',
//             'Issued invoices and payment information',
//             action: FilledButton.icon(
//               onPressed:
//                   _openCreateInvoice,
//               icon:
//                   const Icon(Icons.add),
//               label: const Text(
//                 'Create invoice',
//               ),
//             ),
//           ),

//           const SizedBox(height: 22),

//           _buildSearch(),

//           const SizedBox(height: 18),

//           if (_loading)
//             const Padding(
//               padding:
//                   EdgeInsets.symmetric(
//                 vertical: 100,
//               ),
//               child: Center(
//                 child:
//                     CircularProgressIndicator(),
//               ),
//             )
//           else if (_filteredInvoices.isEmpty)
//             _buildEmpty()
//           else
//             _buildInvoices(),
//         ],
//       ),
//     );
//   }

//   Widget _buildSearch() {
//     return TextField(
//       controller: _searchController,
//       onChanged: (_) {
//         setState(() {});
//       },
//       decoration: InputDecoration(
//         hintText:
//             'Search invoice or appointment reference...',
//         prefixIcon:
//             const Icon(Icons.search),
//         suffixIcon:
//             _searchController.text.isEmpty
//                 ? null
//                 : IconButton(
//                     onPressed: () {
//                       _searchController
//                           .clear();

//                       setState(() {});
//                     },
//                     icon: const Icon(
//                       Icons.close,
//                     ),
//                   ),
//         filled: true,
//         fillColor: Colors.white,
//         border: OutlineInputBorder(
//           borderRadius:
//               BorderRadius.circular(14),
//           borderSide: const BorderSide(
//             color: Color(0xFFE4E5EB),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildInvoices() {
//     return Card(
//       clipBehavior: Clip.antiAlias,
//       child: SingleChildScrollView(
//         scrollDirection:
//             Axis.horizontal,
//         child: DataTable(
//           columnSpacing: 40,
//           columns: const [
//             DataColumn(
//               label: Text('Invoice'),
//             ),
//             DataColumn(
//               label: Text(
//                 'Appointment',
//               ),
//             ),
//             DataColumn(
//               label: Text('Issued'),
//             ),
//             DataColumn(
//               label: Text('Subtotal'),
//             ),
//             DataColumn(
//               label: Text('Paid'),
//             ),
//             DataColumn(
//               label: Text('Remaining'),
//             ),
//             DataColumn(
//               label: Text('Status'),
//             ),
//             DataColumn(
//               label: Text('Actions'),
//             ),
//           ],
//           rows: _filteredInvoices
//               .map(
//                 (invoice) =>
//                     _invoiceRow(invoice),
//               )
//               .toList(),
//         ),
//       ),
//     );
//   }

//   DataRow _invoiceRow(
//     dynamic invoice,
//   ) {
//     final appointment =
//         invoice['appointment'];

//     final reference =
//         appointment is Map
//             ? appointment['reference']
//                     ?.toString() ??
//                 '—'
//             : '—';

//     final total =
//         _number(invoice['total']);

//     final paid =
//         _number(
//       invoice['paidAmount'],
//     );

//     final remaining =
//         (total - paid)
//             .clamp(
//               0,
//               double.infinity,
//             )
//             .toDouble();

//     final status =
//         paid <= 0
//             ? 'Unpaid'
//             : remaining <= 0
//                 ? 'Paid'
//                 : 'Partially paid';

//     return DataRow(
//       cells: [
//         DataCell(
//           Text(
//             invoice['number']
//                     ?.toString() ??
//                 '—',
//             style: const TextStyle(
//               fontWeight:
//                   FontWeight.w700,
//             ),
//           ),
//         ),
//         DataCell(
//           Text(reference),
//         ),
//         DataCell(
//           Text(
//             _formatDate(
//               invoice['issuedAt'],
//             ),
//           ),
//         ),
//         DataCell(
//           Text(
//             _currency(
//               invoice['subtotal'],
//             ),
//           ),
//         ),
//         DataCell(
//           Text(
//             _currency(
//               invoice['paidAmount'],
//             ),
//           ),
//         ),
//         DataCell(
//           Text(
//             _currency(remaining),
//           ),
//         ),
//         DataCell(
//           _statusBadge(status),
//         ),
//         DataCell(
//           IconButton(
//             tooltip: 'View invoice',
//             onPressed: () {
//               _showInvoice(
//                 invoice,
//               );
//             },
//             icon: const Icon(
//               Icons
//                   .visibility_outlined,
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   Future<void>
//       _openCreateInvoice() async {
//     final available =
//         _appointments.where(
//       (appointment) {
//         final id =
//             appointment['id'];

//         return !_invoices.any(
//           (invoice) =>
//               invoice['appointmentId']
//                   ?.toString() ==
//               id?.toString(),
//         );
//       },
//     ).toList();

//     if (available.isEmpty) {
//       _showMessage(
//         'There are no appointments without an invoice.',
//       );
//       return;
//     }

//     int? appointmentId;

//     final result =
//         await showDialog<bool>(
//       context: context,
//       builder: (dialogContext) {
//         return StatefulBuilder(
//           builder: (
//             context,
//             setDialogState,
//           ) {
//             return AlertDialog(
//               title: const Text(
//                 'Create invoice',
//               ),
//               content: SizedBox(
//                 width: 460,
//                 child:
//                     DropdownButtonFormField<
//                         int>(
//                   value:
//                       appointmentId,
//                   isExpanded: true,
//                   decoration:
//                       const InputDecoration(
//                     labelText:
//                         'Appointment',
//                     border:
//                         OutlineInputBorder(),
//                   ),
//                   items: available
//                       .map<
//                           DropdownMenuItem<
//                               int>>(
//                         (appointment) {
//                           final id =
//                               _toInt(
//                             appointment[
//                                 'id'],
//                           );

//                           final client =
//                               appointment[
//                                   'client'];

//                           final clientName =
//                               client is Map
//                                   ? client[
//                                               'fullName']
//                                           ?.toString() ??
//                                       'Client'
//                                   : 'Client';

//                           final reference =
//                               appointment[
//                                           'reference']
//                                       ?.toString() ??
//                                   '—';

//                           return DropdownMenuItem<
//                               int>(
//                             value: id,
//                             child: Text(
//                               '$reference • $clientName',
//                             ),
//                           );
//                         },
//                       )
//                       .toList(),
//                   onChanged: (value) {
//                     setDialogState(
//                       () {
//                         appointmentId =
//                             value;
//                       },
//                     );
//                   },
//                 ),
//               ),
//               actions: [
//                 TextButton(
//                   onPressed: () {
//                     Navigator.pop(
//                       dialogContext,
//                       false,
//                     );
//                   },
//                   child:
//                       const Text('Cancel'),
//                 ),
//                 FilledButton(
//                   onPressed:
//                       appointmentId ==
//                               null
//                           ? null
//                           : () {
//                               Navigator.pop(
//                                 dialogContext,
//                                 true,
//                               );
//                             },
//                   child: const Text(
//                     'Create',
//                   ),
//                 ),
//               ],
//             );
//           },
//         );
//       },
//     );

//     if (result != true ||
//         appointmentId == null) {
//       return;
//     }

//     try {
//       await context
//           .read<ApiClient>()
//           .post(
//         '/finance/invoices/$appointmentId',
//       );

//       await _load();

//       if (!mounted) {
//         return;
//       }

//       _showMessage(
//         'Invoice created successfully.',
//       );
//     } catch (_) {
//       if (!mounted) {
//         return;
//       }

//       _showMessage(
//         'Could not create invoice.',
//         error: true,
//       );
//     }
//   }

//   void _showInvoice(
//     dynamic invoice,
//   ) {
//     final total =
//         _number(invoice['total']);

//     final paid =
//         _number(
//       invoice['paidAmount'],
//     );

//     final remaining =
//         (total - paid)
//             .clamp(
//               0,
//               double.infinity,
//             )
//             .toDouble();

//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor:
//           Colors.transparent,
//       builder: (sheetContext) {
//         return Container(
//           padding:
//               const EdgeInsets.all(24),
//           decoration:
//               const BoxDecoration(
//             color: Colors.white,
//             borderRadius:
//                 BorderRadius.vertical(
//               top:
//                   Radius.circular(28),
//             ),
//           ),
//           child: SafeArea(
//             top: false,
//             child: Column(
//               mainAxisSize:
//                   MainAxisSize.min,
//               crossAxisAlignment:
//                   CrossAxisAlignment.start,
//               children: [
//                 Row(
//                   children: [
//                     const Expanded(
//                       child: Text(
//                         'Invoice details',
//                         style:
//                             TextStyle(
//                           fontSize: 22,
//                           fontWeight:
//                               FontWeight
//                                   .w800,
//                         ),
//                       ),
//                     ),
//                     IconButton(
//                       onPressed: () {
//                         Navigator.pop(
//                           sheetContext,
//                         );
//                       },
//                       icon: const Icon(
//                         Icons.close,
//                       ),
//                     ),
//                   ],
//                 ),

//                 const SizedBox(
//                   height: 20,
//                 ),

//                 _detail(
//                   'Invoice',
//                   invoice['number']
//                           ?.toString() ??
//                       '—',
//                 ),
//                 _detail(
//                   'Issued',
//                   _formatDate(
//                     invoice['issuedAt'],
//                   ),
//                 ),
//                 _detail(
//                   'Subtotal',
//                   _currency(
//                     invoice['subtotal'],
//                   ),
//                 ),
//                 _detail(
//                   'Total',
//                   _currency(
//                     invoice['total'],
//                   ),
//                 ),
//                 _detail(
//                   'Paid',
//                   _currency(
//                     invoice['paidAmount'],
//                   ),
//                 ),
//                 _detail(
//                   'Remaining',
//                   _currency(
//                     remaining,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }

//   Widget _detail(
//     String title,
//     String value,
//   ) {
//     return Container(
//       width: double.infinity,
//       margin:
//           const EdgeInsets.only(
//         bottom: 10,
//       ),
//       padding:
//           const EdgeInsets.all(15),
//       decoration: BoxDecoration(
//         color: const Color(
//           0xFFF8F9FC,
//         ),
//         borderRadius:
//             BorderRadius.circular(14),
//       ),
//       child: Row(
//         children: [
//           Expanded(
//             child: Text(
//               title,
//               style: const TextStyle(
//                 color:
//                     Color(0xFF77798A),
//               ),
//             ),
//           ),
//           Text(
//             value,
//             style: const TextStyle(
//               fontWeight:
//                   FontWeight.w700,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _statusBadge(
//     String status,
//   ) {
//     Color background;
//     Color foreground;

//     switch (status) {
//       case 'Paid':
//         background =
//             const Color(0xFFEAF8F0);
//         foreground =
//             const Color(0xFF248A5B);
//         break;

//       case 'Partially paid':
//         background =
//             const Color(0xFFFFF6DF);
//         foreground =
//             const Color(0xFFB87A00);
//         break;

//       default:
//         background =
//             const Color(0xFFFFEEEE);
//         foreground =
//             const Color(0xFFD94343);
//     }

//     return Container(
//       padding:
//           const EdgeInsets.symmetric(
//         horizontal: 10,
//         vertical: 6,
//       ),
//       decoration: BoxDecoration(
//         color: background,
//         borderRadius:
//             BorderRadius.circular(20),
//       ),
//       child: Text(
//         status,
//         style: TextStyle(
//           color: foreground,
//           fontSize: 11,
//           fontWeight:
//               FontWeight.w700,
//         ),
//       ),
//     );
//   }

//   Widget _buildEmpty() {
//     return Card(
//       child: Padding(
//         padding:
//             const EdgeInsets.symmetric(
//           vertical: 60,
//         ),
//         child: Center(
//           child: Column(
//             children: [
//               Icon(
//                 Icons
//                     .receipt_long_outlined,
//                 size: 44,
//                 color:
//                     Colors.grey.shade400,
//               ),
//               const SizedBox(height: 14),
//               const Text(
//                 'No invoices found',
//                 style: TextStyle(
//                   fontSize: 17,
//                   fontWeight:
//                       FontWeight.w700,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   double _number(dynamic value) {
//     if (value is num) {
//       return value.toDouble();
//     }

//     return double.tryParse(
//           value?.toString() ?? '',
//         ) ??
//         0;
//   }

//   int? _toInt(dynamic value) {
//     if (value is int) {
//       return value;
//     }

//     return int.tryParse(
//       value?.toString() ?? '',
//     );
//   }

//   String _currency(dynamic value) {
//     return '€${_number(value).toStringAsFixed(2)}';
//   }

//   String _formatDate(dynamic value) {
//     final date =
//         DateTime.tryParse(
//       value?.toString() ?? '',
//     );

//     if (date == null) {
//       return '—';
//     }

//     return '${date.day.toString().padLeft(2, '0')}/'
//         '${date.month.toString().padLeft(2, '0')}/'
//         '${date.year}';
//   }

//   void _showMessage(
//     String message, {
//     bool error = false,
//   }) {
//     ScaffoldMessenger.of(context)
//       ..hideCurrentSnackBar()
//       ..showSnackBar(
//         SnackBar(
//           behavior:
//               SnackBarBehavior.floating,
//           backgroundColor: error
//               ? const Color(0xFFD94343)
//               : const Color(0xFF292B38),
//           content: Text(message),
//         ),
//       );
//   }
// }
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api_client.dart';
import '../widgets/page_header.dart';

class InvoicesPage extends StatefulWidget {
  const InvoicesPage({super.key});

  @override
  State<InvoicesPage> createState() => _InvoicesPageState();
}

class _InvoicesPageState extends State<InvoicesPage> {
  final TextEditingController _searchController = TextEditingController();

  bool _initialized = false;
  bool _loading = true;
  bool _creatingInvoice = false;

  List<dynamic> _invoices = [];
  List<dynamic> _appointments = [];

  String _statusFilter = 'All';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_initialized) {
      _initialized = true;
      _load();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
      });
    }

    try {
      final api = context.read<ApiClient>();

      final results = await Future.wait([
        api.get('/finance/invoices'),
        api.get('/appointments'),
      ]);

      if (!mounted) {
        return;
      }

      setState(() {
        _invoices = results[0] is List
            ? List<dynamic>.from(results[0])
            : [];

        _appointments = results[1] is List
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
        'Could not load invoices.',
        error: true,
      );
    }
  }

  List<dynamic> get _filteredInvoices {
    final search = _searchController.text.trim().toLowerCase();

    return _invoices.where((invoice) {
      final number = _text(invoice['number']).toLowerCase();
      final reference = _appointmentReference(invoice).toLowerCase();
      final customer = _customerName(invoice).toLowerCase();
      final service = _serviceName(invoice).toLowerCase();
      final status = _invoiceStatus(invoice);

      final matchesSearch = search.isEmpty ||
          number.contains(search) ||
          reference.contains(search) ||
          customer.contains(search) ||
          service.contains(search);

      final matchesStatus =
          _statusFilter == 'All' || status == _statusFilter;

      return matchesSearch && matchesStatus;
    }).toList();
  }

  int get _paidCount {
    return _invoices.where((invoice) {
      return _invoiceStatus(invoice) == 'Paid';
    }).length;
  }

  int get _unpaidCount {
    return _invoices.where((invoice) {
      return _invoiceStatus(invoice) == 'Unpaid';
    }).length;
  }

  int get _partialCount {
    return _invoices.where((invoice) {
      return _invoiceStatus(invoice) == 'Partially paid';
    }).length;
  }

  double get _totalInvoiced {
    return _invoices.fold<double>(
      0,
      (total, invoice) => total + _number(invoice['total']),
    );
  }

  double get _totalPaid {
    return _invoices.fold<double>(
      0,
      (total, invoice) => total + _number(invoice['paidAmount']),
    );
  }

  double get _totalOutstanding {
    return _invoices.fold<double>(
      0,
      (total, invoice) => total + _remaining(invoice),
    );
  }

  @override
  Widget build(BuildContext context) {
    final invoices = _filteredInvoices;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(28),
        children: [
          PageHeader(
            'Invoices',
            'Create, review and manage customer invoices',
            action: FilledButton.icon(
              onPressed: _creatingInvoice ? null : _openCreateInvoice,
              icon: const Icon(
                Icons.add_rounded,
                size: 19,
              ),
              label: const Text('Create invoice'),
            ),
          ),
          const SizedBox(height: 26),
          _buildSummary(),
          const SizedBox(height: 22),
          _buildToolbar(),
          const SizedBox(height: 16),
          if (_loading)
            _buildLoading()
          else if (invoices.isEmpty)
            _buildEmpty()
          else
            _buildInvoiceTable(invoices),
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
              title: 'Total invoiced',
              value: _currency(_totalInvoiced),
              subtitle: '${_invoices.length} invoices',
              icon: Icons.receipt_long_outlined,
              background: const Color(0xFFF0EFFF),
              iconColor: const Color(0xFF6C63FF),
            ),
            _summaryCard(
              width: cardWidth,
              title: 'Collected',
              value: _currency(_totalPaid),
              subtitle: '$_paidCount fully paid',
              icon: Icons.payments_outlined,
              background: const Color(0xFFEAF8F0),
              iconColor: const Color(0xFF279466),
            ),
            _summaryCard(
              width: cardWidth,
              title: 'Outstanding',
              value: _currency(_totalOutstanding),
              subtitle: '$_unpaidCount unpaid',
              icon: Icons.account_balance_wallet_outlined,
              background: const Color(0xFFFFF4E8),
              iconColor: const Color(0xFFE28A36),
            ),
            _summaryCard(
              width: cardWidth,
              title: 'Partially paid',
              value: '$_partialCount',
              subtitle: 'Invoices with balance',
              icon: Icons.pie_chart_outline_rounded,
              background: const Color(0xFFEAF6FF),
              iconColor: const Color(0xFF4389C7),
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
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFFE9EAF0),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
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
            const SizedBox(width: 15),
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
                      height: 1.1,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF252631),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF5E606E),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF9698A5),
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
          final compact = constraints.maxWidth < 900;

          if (compact) {
            return Column(
              children: [
                _buildSearch(),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: _buildStatusFilters(),
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
              const SizedBox(width: 16),
              _buildStatusFilters(),
              const SizedBox(width: 6),
              IconButton(
                tooltip: 'Refresh',
                onPressed: _load,
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

  Widget _buildSearch() {
    return TextField(
      controller: _searchController,
      onChanged: (_) {
        setState(() {});
      },
      decoration: InputDecoration(
        hintText: 'Search invoice, customer or appointment...',
        prefixIcon: const Icon(
          Icons.search_rounded,
          size: 21,
        ),
        suffixIcon: _searchController.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Clear',
                onPressed: () {
                  _searchController.clear();

                  setState(() {});
                },
                icon: const Icon(
                  Icons.close_rounded,
                  size: 19,
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
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(
            color: Color(0xFF6C63FF),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusFilters() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _statusFilterButton('All'),
        const SizedBox(width: 7),
        _statusFilterButton('Paid'),
        const SizedBox(width: 7),
        _statusFilterButton('Partially paid'),
        const SizedBox(width: 7),
        _statusFilterButton('Unpaid'),
      ],
    );
  }

  Widget _statusFilterButton(String value) {
    final selected = _statusFilter == value;

    return InkWell(
      borderRadius: BorderRadius.circular(11),
      onTap: () {
        setState(() {
          _statusFilter = value;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
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
                : const Color(0xFF5F6170),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildInvoiceTable(
    List<dynamic> invoices,
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
              index < invoices.length;
              index++) ...[
            _buildInvoiceRow(
              invoices[index],
            ),
            if (index != invoices.length - 1)
              const Divider(
                height: 1,
                indent: 20,
                endIndent: 20,
                color: Color(0xFFEEEEF2),
              ),
          ],
          _buildTableFooter(
            invoices.length,
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
              'INVOICE',
              style: _tableHeaderStyle,
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              'CUSTOMER',
              style: _tableHeaderStyle,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'ISSUED',
              style: _tableHeaderStyle,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'TOTAL',
              style: _tableHeaderStyle,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'PAID',
              style: _tableHeaderStyle,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'STATUS',
              style: _tableHeaderStyle,
            ),
          ),
          SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildInvoiceRow(dynamic invoice) {
    final number = _text(invoice['number']).isEmpty
        ? 'Invoice'
        : _text(invoice['number']);

    final reference = _appointmentReference(invoice);
    final customer = _customerName(invoice);
    final service = _serviceName(invoice);

    final total = _number(invoice['total']);
    final paid = _number(invoice['paidAmount']);
    final status = _invoiceStatus(invoice);

    return InkWell(
      onTap: () {
        _showInvoice(invoice);
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
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0EFFF),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(
                      Icons.receipt_long_outlined,
                      color: Color(0xFF6C63FF),
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
                          number,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF292A35),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          reference,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF9294A2),
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
                    customer,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    service,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF9294A2),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                _formatDate(invoice['issuedAt']),
                style: const TextStyle(
                  color: Color(0xFF666875),
                  fontSize: 12,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                _currency(total),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                _currency(paid),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: paid > 0
                      ? const Color(0xFF27875D)
                      : const Color(0xFF7C7E8B),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: _statusBadge(status),
              ),
            ),
            SizedBox(
              width: 48,
              child: PopupMenuButton<String>(
                tooltip: 'Actions',
                icon: const Icon(
                  Icons.more_horiz_rounded,
                  color: Color(0xFF777986),
                ),
                onSelected: (value) {
                  if (value == 'view') {
                    _showInvoice(invoice);
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'view',
                    child: Row(
                      children: [
                        Icon(
                          Icons.visibility_outlined,
                          size: 18,
                        ),
                        SizedBox(width: 10),
                        Text('View invoice'),
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
      child: Row(
        children: [
          Text(
            '$count ${count == 1 ? 'invoice' : 'invoices'} shown',
            style: const TextStyle(
              color: Color(0xFF77798A),
              fontSize: 12,
            ),
          ),
          const Spacer(),
          Text(
            'Outstanding ${_currency(_totalOutstanding)}',
            style: const TextStyle(
              color: Color(0xFF77798A),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openCreateInvoice() async {
    final available = _appointments.where((appointment) {
      final id = _toInt(appointment['id']);

      if (id == null) {
        return false;
      }

      return !_invoices.any(
        (invoice) =>
            invoice['appointmentId']?.toString() ==
            id.toString(),
      );
    }).toList();

    if (available.isEmpty) {
      _showMessage(
        'There are no appointments available for a new invoice.',
      );
      return;
    }

    final appointmentId = await showDialog<int>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return _CreateInvoiceDialog(
          appointments: available,
        );
      },
    );

    if (appointmentId == null) {
      return;
    }

    if (mounted) {
      setState(() {
        _creatingInvoice = true;
      });
    }

    try {
      await context.read<ApiClient>().post(
            '/finance/invoices/$appointmentId',
          );

      await _load();

      if (!mounted) {
        return;
      }

      setState(() {
        _creatingInvoice = false;
      });

      _showMessage(
        'Invoice created successfully.',
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _creatingInvoice = false;
      });

      _showMessage(
        'Could not create invoice.',
        error: true,
      );
    }
  }

  void _showInvoice(dynamic invoice) {
    final appointment = invoice['appointment'];

    final subtotal = _number(invoice['subtotal']);
    final total = _number(invoice['total']);
    final paid = _number(invoice['paidAmount']);
    final remaining = _remaining(invoice);
    final status = _invoiceStatus(invoice);

    final number = _text(invoice['number']).isEmpty
        ? '—'
        : _text(invoice['number']);

    final reference = _appointmentReference(invoice);
    final customer = _customerName(invoice);
    final email = _customerEmail(invoice);
    final phone = _customerPhone(invoice);
    final service = _serviceName(invoice);
    final staff = _staffName(invoice);

    final startTime = appointment is Map
        ? appointment['startTime']
        : null;

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(
        alpha: 0.35,
      ),
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 24,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 780,
              maxHeight: 880,
            ),
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 16,
                    ),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFAFAFC),
                      border: Border(
                        bottom: BorderSide(
                          color: Color(0xFFE9EAF0),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0EFFF),
                            borderRadius:
                                BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.receipt_long_rounded,
                            color: Color(0xFF6C63FF),
                            size: 21,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Invoice',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Invoice preview',
                                style: TextStyle(
                                  color: Color(0xFF8A8C99),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _statusBadge(status),
                        const SizedBox(width: 8),
                        IconButton(
                          tooltip: 'Close',
                          onPressed: () {
                            Navigator.pop(dialogContext);
                          },
                          icon: const Icon(
                            Icons.close_rounded,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(34),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _buildInvoiceBrand(),
                              ),
                              const SizedBox(width: 30),
                              Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.end,
                                children: [
                                  const Text(
                                    'INVOICE',
                                    style: TextStyle(
                                      color: Color(0xFF6C63FF),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                  const SizedBox(height: 7),
                                  Text(
                                    number,
                                    style: const TextStyle(
                                      fontSize: 21,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF252631),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Issued ${_formatDate(invoice['issuedAt'])}',
                                    style: const TextStyle(
                                      color: Color(0xFF858795),
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),
                          const Divider(
                            color: Color(0xFFE9EAF0),
                          ),
                          const SizedBox(height: 28),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              if (constraints.maxWidth < 580) {
                                return Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    _buildBillTo(
                                      customer,
                                      email,
                                      phone,
                                    ),
                                    const SizedBox(height: 25),
                                    _buildAppointmentInfo(
                                      reference,
                                      service,
                                      staff,
                                      startTime,
                                    ),
                                  ],
                                );
                              }

                              return Row(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: _buildBillTo(
                                      customer,
                                      email,
                                      phone,
                                    ),
                                  ),
                                  const SizedBox(width: 50),
                                  Expanded(
                                    child: _buildAppointmentInfo(
                                      reference,
                                      service,
                                      staff,
                                      startTime,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 34),
                          _invoiceItemsHeader(),
                          _invoiceItem(
                            service,
                            subtotal,
                          ),
                          const SizedBox(height: 28),
                          Align(
                            alignment: Alignment.centerRight,
                            child: SizedBox(
                              width: 330,
                              child: Column(
                                children: [
                                  _totalRow(
                                    'Subtotal',
                                    _currency(subtotal),
                                  ),
                                  const SizedBox(height: 11),
                                  _totalRow(
                                    'Paid',
                                    _currency(paid),
                                    valueColor:
                                        const Color(0xFF27875D),
                                  ),
                                  const Padding(
                                    padding:
                                        EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    child: Divider(
                                      height: 1,
                                    ),
                                  ),
                                  _totalRow(
                                    'Total',
                                    _currency(total),
                                    strong: true,
                                  ),
                                  const SizedBox(height: 12),
                                  Container(
                                    padding:
                                        const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 13,
                                    ),
                                    decoration: BoxDecoration(
                                      color: remaining > 0
                                          ? const Color(0xFFFFF6DF)
                                          : const Color(0xFFEAF8F0),
                                      borderRadius:
                                          BorderRadius.circular(12),
                                    ),
                                    child: _totalRow(
                                      'Remaining',
                                      _currency(remaining),
                                      strong: true,
                                      valueColor: remaining > 0
                                          ? const Color(0xFFA66E00)
                                          : const Color(0xFF237C57),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 34),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(17),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8F9FC),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Row(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.info_outline_rounded,
                                  size: 18,
                                  color: Color(0xFF6C63FF),
                                ),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'This invoice is generated from the appointment and its recorded payment information.',
                                    style: TextStyle(
                                      color: Color(0xFF70727F),
                                      fontSize: 11,
                                      height: 1.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Center(
                            child: Text(
                              'Thank you for your business.',
                              style: TextStyle(
                                color: Color(0xFF999BA7),
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 14,
                    ),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFAFAFC),
                      border: Border(
                        top: BorderSide(
                          color: Color(0xFFE9EAF0),
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(dialogContext);
                          },
                          child: const Text('Close'),
                        ),
                      ],
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

  Widget _buildInvoiceBrand() {
    return Row(
      children: [
        Container(
          width: 55,
          height: 55,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF6C63FF),
                Color(0xFF857EFF),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(17),
          ),
          child: const Icon(
            Icons.calendar_month_rounded,
            color: Colors.white,
            size: 26,
          ),
        ),
        const SizedBox(width: 14),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'NexaBook',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Color(0xFF252631),
              ),
            ),
            SizedBox(height: 3),
            Text(
              'Business Management',
              style: TextStyle(
                color: Color(0xFF858795),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBillTo(
    String customer,
    String email,
    String phone,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'BILL TO',
          style: TextStyle(
            color: Color(0xFF9A9CA8),
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 11),
        Text(
          customer,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: Color(0xFF292A35),
          ),
        ),
        if (email != '—') ...[
          const SizedBox(height: 8),
          _invoiceInfoLine(
            Icons.mail_outline_rounded,
            email,
          ),
        ],
        if (phone != '—') ...[
          const SizedBox(height: 6),
          _invoiceInfoLine(
            Icons.phone_outlined,
            phone,
          ),
        ],
      ],
    );
  }

  Widget _buildAppointmentInfo(
    String reference,
    String service,
    String staff,
    dynamic startTime,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'APPOINTMENT',
          style: TextStyle(
            color: Color(0xFF9A9CA8),
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 11),
        _invoiceInfoLine(
          Icons.confirmation_number_outlined,
          reference,
        ),
        const SizedBox(height: 7),
        _invoiceInfoLine(
          Icons.design_services_outlined,
          service,
        ),
        if (staff != '—') ...[
          const SizedBox(height: 7),
          _invoiceInfoLine(
            Icons.person_outline_rounded,
            staff,
          ),
        ],
        if (startTime != null) ...[
          const SizedBox(height: 7),
          _invoiceInfoLine(
            Icons.schedule_outlined,
            _formatDateTime(startTime),
          ),
        ],
      ],
    );
  }

  Widget _invoiceInfoLine(
    IconData icon,
    String value,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 15,
          color: const Color(0xFF8A8C99),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF626471),
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _invoiceItemsHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFF7F7FA),
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(12),
        ),
      ),
      child: const Row(
        children: [
          Expanded(
            child: Text(
              'DESCRIPTION',
              style: _invoiceHeaderStyle,
            ),
          ),
          SizedBox(
            width: 70,
            child: Text(
              'QTY',
              textAlign: TextAlign.center,
              style: _invoiceHeaderStyle,
            ),
          ),
          SizedBox(
            width: 120,
            child: Text(
              'AMOUNT',
              textAlign: TextAlign.right,
              style: _invoiceHeaderStyle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _invoiceItem(
    String service,
    double amount,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 18,
      ),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFE9EAF0),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              service,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(
            width: 70,
            child: Text(
              '1',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
              ),
            ),
          ),
          SizedBox(
            width: 120,
            child: Text(
              _currency(amount),
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _totalRow(
    String label,
    String value, {
    bool strong = false,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: strong
                  ? const Color(0xFF292A35)
                  : const Color(0xFF777986),
              fontSize: strong ? 14 : 12,
              fontWeight:
                  strong ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? const Color(0xFF292A35),
            fontSize: strong ? 15 : 13,
            fontWeight:
                strong ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _statusBadge(String status) {
    Color background;
    Color foreground;
    Color dot;

    switch (status) {
      case 'Paid':
        background = const Color(0xFFEAF8F0);
        foreground = const Color(0xFF237C57);
        dot = const Color(0xFF279466);
        break;

      case 'Partially paid':
        background = const Color(0xFFFFF6DF);
        foreground = const Color(0xFFA66E00);
        dot = const Color(0xFFE1A62A);
        break;

      default:
        background = const Color(0xFFFFEEEE);
        foreground = const Color(0xFFC6464E);
        dot = const Color(0xFFD95864);
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: dot,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            status,
            style: TextStyle(
              color: foreground,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return Container(
      height: 330,
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
    final filtered = _searchController.text.trim().isNotEmpty ||
        _statusFilter != 'All';

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
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: const Color(0xFFF0EFFF),
              borderRadius: BorderRadius.circular(21),
            ),
            child: const Icon(
              Icons.receipt_long_outlined,
              size: 31,
              color: Color(0xFF6C63FF),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            filtered
                ? 'No invoices found'
                : 'No invoices yet',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            filtered
                ? 'Try changing your search or filters.'
                : 'Create an invoice from one of your appointments.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF77798A),
              fontSize: 13,
            ),
          ),
          if (!filtered) ...[
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _openCreateInvoice,
              icon: const Icon(
                Icons.add_rounded,
                size: 18,
              ),
              label: const Text(
                'Create invoice',
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _invoiceStatus(dynamic invoice) {
    final total = _number(invoice['total']);
    final paid = _number(invoice['paidAmount']);
    final remaining =
        (total - paid).clamp(0, double.infinity).toDouble();

    if (paid <= 0) {
      return 'Unpaid';
    }

    if (remaining <= 0) {
      return 'Paid';
    }

    return 'Partially paid';
  }

  double _remaining(dynamic invoice) {
    final total = _number(invoice['total']);
    final paid = _number(invoice['paidAmount']);

    return (total - paid)
        .clamp(0, double.infinity)
        .toDouble();
  }

  String _appointmentReference(dynamic invoice) {
    final appointment = invoice['appointment'];

    if (appointment is Map) {
      final reference = _text(
        appointment['reference'],
      );

      if (reference.isNotEmpty) {
        return reference;
      }
    }

    final reference = _text(
      invoice['appointmentReference'],
    );

    if (reference.isNotEmpty) {
      return reference;
    }

    final id = invoice['appointmentId'];

    if (id != null) {
      return 'Appointment #$id';
    }

    return '—';
  }

  String _customerName(dynamic invoice) {
    final appointment = invoice['appointment'];

    if (appointment is Map) {
      final client =
          appointment['client'] ?? appointment['customer'];

      if (client is Map) {
        final fullName = _text(client['fullName']);

        if (fullName.isNotEmpty) {
          return fullName;
        }

        final firstName = _text(client['firstName']);
        final lastName = _text(client['lastName']);

        final name = '$firstName $lastName'.trim();

        if (name.isNotEmpty) {
          return name;
        }
      }
    }

    return 'Customer';
  }

  String _customerEmail(dynamic invoice) {
    final appointment = invoice['appointment'];

    if (appointment is Map) {
      final client =
          appointment['client'] ?? appointment['customer'];

      if (client is Map) {
        final value = _text(client['email']);

        if (value.isNotEmpty) {
          return value;
        }
      }
    }

    return '—';
  }

  String _customerPhone(dynamic invoice) {
    final appointment = invoice['appointment'];

    if (appointment is Map) {
      final client =
          appointment['client'] ?? appointment['customer'];

      if (client is Map) {
        final value = _text(client['phone']);

        if (value.isNotEmpty) {
          return value;
        }
      }
    }

    return '—';
  }

  String _serviceName(dynamic invoice) {
    final appointment = invoice['appointment'];

    if (appointment is Map) {
      final service = appointment['service'];

      if (service is Map) {
        final name = _text(service['name']);

        if (name.isNotEmpty) {
          return name;
        }
      }
    }

    return 'Service';
  }

  String _staffName(dynamic invoice) {
    final appointment = invoice['appointment'];

    if (appointment is Map) {
      final staff = appointment['staff'];

      if (staff is Map) {
        final name = _text(staff['fullName']);

        if (name.isNotEmpty) {
          return name;
        }
      }
    }

    return '—';
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

  String _currency(dynamic value) {
    return '€${_number(value).toStringAsFixed(2)}';
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
          behavior: SnackBarBehavior.floating,
          backgroundColor: error
              ? const Color(0xFFD94343)
              : const Color(0xFF292B38),
          content: Text(message),
        ),
      );
  }
}

class _CreateInvoiceDialog extends StatefulWidget {
  final List<dynamic> appointments;

  const _CreateInvoiceDialog({
    required this.appointments,
  });

  @override
  State<_CreateInvoiceDialog> createState() =>
      _CreateInvoiceDialogState();
}

class _CreateInvoiceDialogState
    extends State<_CreateInvoiceDialog> {
  int? _appointmentId;

  dynamic get _selectedAppointment {
    if (_appointmentId == null) {
      return null;
    }

    for (final appointment in widget.appointments) {
      if (_toIntValue(appointment['id']) == _appointmentId) {
        return appointment;
      }
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selectedAppointment;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 620,
          maxHeight: 760,
        ),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                decoration: const BoxDecoration(
                  color: Color(0xFFFAFAFC),
                  border: Border(
                    bottom: BorderSide(
                      color: Color(0xFFE9EAF0),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0EFFF),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.receipt_long_outlined,
                        color: Color(0xFF6C63FF),
                      ),
                    ),
                    const SizedBox(width: 13),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Create invoice',
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Choose an appointment to generate an invoice',
                            style: TextStyle(
                              color: Color(0xFF858795),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: const Icon(
                        Icons.close_rounded,
                      ),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(26),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Appointment',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF555766),
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<int>(
                        value: _appointmentId,
                        isExpanded: true,
                        decoration: InputDecoration(
                          hintText: 'Select appointment',
                          prefixIcon: const Icon(
                            Icons.event_outlined,
                            size: 20,
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF8F9FC),
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(13),
                            borderSide: const BorderSide(
                              color: Color(0xFFE6E7EC),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(13),
                            borderSide: const BorderSide(
                              color: Color(0xFFE6E7EC),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(13),
                            borderSide: const BorderSide(
                              color: Color(0xFF6C63FF),
                            ),
                          ),
                        ),
                        items: widget.appointments
                            .where(
                              (appointment) =>
                                  _toIntValue(
                                    appointment['id'],
                                  ) !=
                                  null,
                            )
                            .map<DropdownMenuItem<int>>(
                          (appointment) {
                            final id = _toIntValue(
                              appointment['id'],
                            )!;

                            final reference =
                                _stringValue(
                              appointment['reference'],
                            );

                            final client =
                                appointment['client'];

                            String clientName = 'Customer';

                            if (client is Map) {
                              clientName = _stringValue(
                                client['fullName'],
                              );

                              if (clientName.isEmpty) {
                                clientName = 'Customer';
                              }
                            }

                            return DropdownMenuItem<int>(
                              value: id,
                              child: Text(
                                '$reference  •  $clientName',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          },
                        ).toList(),
                        onChanged: (value) {
                          setState(() {
                            _appointmentId = value;
                          });
                        },
                      ),
                      if (selected != null) ...[
                        const SizedBox(height: 22),
                        _AppointmentPreview(
                          appointment: selected,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                decoration: const BoxDecoration(
                  color: Color(0xFFFAFAFC),
                  border: Border(
                    top: BorderSide(
                      color: Color(0xFFE9EAF0),
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 10),
                    FilledButton.icon(
                      onPressed: _appointmentId == null
                          ? null
                          : () {
                              Navigator.pop(
                                context,
                                _appointmentId,
                              );
                            },
                      icon: const Icon(
                        Icons.receipt_long_rounded,
                        size: 18,
                      ),
                      label: const Text(
                        'Create invoice',
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
}

class _AppointmentPreview extends StatelessWidget {
  final dynamic appointment;

  const _AppointmentPreview({
    required this.appointment,
  });

  @override
  Widget build(BuildContext context) {
    final client = appointment['client'];
    final service = appointment['service'];
    final staff = appointment['staff'];

    String clientName = '—';
    String serviceName = '—';
    String staffName = '—';

    if (client is Map) {
      clientName = _stringValue(
        client['fullName'],
      );

      if (clientName.isEmpty) {
        clientName = '—';
      }
    }

    if (service is Map) {
      serviceName = _stringValue(
        service['name'],
      );

      if (serviceName.isEmpty) {
        serviceName = '—';
      }
    }

    if (staff is Map) {
      staffName = _stringValue(
        staff['fullName'],
      );

      if (staffName.isEmpty) {
        staffName = '—';
      }
    }

    final total = _doubleValue(
      appointment['totalAmount'],
    );

    final paid = _doubleValue(
      appointment['paidAmount'],
    );

    final remaining = _doubleValue(
      appointment['remainingAmount'],
    );

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FC),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: const Color(0xFFE7E8EE),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(17),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF6FF),
                    borderRadius:
                        BorderRadius.circular(13),
                  ),
                  child: const Icon(
                    Icons.event_available_outlined,
                    color: Color(0xFF4389C7),
                    size: 21,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        _stringValue(
                          appointment['reference'],
                        ),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        clientName,
                        style: const TextStyle(
                          color: Color(0xFF77798A),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(17),
            child: Column(
              children: [
                _previewRow(
                  'Service',
                  serviceName,
                ),
                const SizedBox(height: 11),
                _previewRow(
                  'Staff',
                  staffName,
                ),
                const SizedBox(height: 11),
                _previewRow(
                  'Appointment total',
                  '€${total.toStringAsFixed(2)}',
                  strong: true,
                ),
                if (paid > 0) ...[
                  const SizedBox(height: 11),
                  _previewRow(
                    'Already paid',
                    '€${paid.toStringAsFixed(2)}',
                  ),
                ],
                if (remaining > 0) ...[
                  const SizedBox(height: 11),
                  _previewRow(
                    'Remaining',
                    '€${remaining.toStringAsFixed(2)}',
                    strong: true,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _previewRow(
    String label,
    String value, {
    bool strong = false,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF858795),
              fontSize: 12,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight:
                strong ? FontWeight.w800 : FontWeight.w600,
            color: const Color(0xFF353641),
          ),
        ),
      ],
    );
  }
}

int? _toIntValue(dynamic value) {
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

double _doubleValue(dynamic value) {
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

String _stringValue(dynamic value) {
  if (value == null) {
    return '';
  }

  return value.toString().trim();
}

const TextStyle _tableHeaderStyle = TextStyle(
  color: Color(0xFF858795),
  fontSize: 10,
  fontWeight: FontWeight.w700,
  letterSpacing: 0.6,
);

const TextStyle _invoiceHeaderStyle = TextStyle(
  color: Color(0xFF858795),
  fontSize: 9,
  fontWeight: FontWeight.w800,
  letterSpacing: 0.7,
);