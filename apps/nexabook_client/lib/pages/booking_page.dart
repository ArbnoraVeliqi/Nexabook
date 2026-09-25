// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';

// import '../core/api_client.dart';

// class BookingPage extends StatefulWidget {
//   final Map service;

//   const BookingPage({
//     super.key,
//     required this.service,
//   });

//   @override
//   State<BookingPage> createState() => _BookingPageState();
// }

// class _BookingPageState extends State<BookingPage> {
//   List<dynamic> _staff = [];
//   List<DateTime> _slots = [];

//   int? _staffId;
//   DateTime? _selectedSlot;

//   DateTime _selectedDate = DateTime.now().add(
//     const Duration(days: 1),
//   );

//   bool _initialized = false;
//   bool _loadingStaff = true;
//   bool _loadingSlots = false;
//   bool _booking = false;

//   @override
//   void didChangeDependencies() {
//     super.didChangeDependencies();

//     if (!_initialized) {
//       _initialized = true;
//       _loadStaff();
//     }
//   }

//   Future<void> _loadStaff() async {
//     setState(() {
//       _loadingStaff = true;
//     });

//     try {
//       final response = await context
//           .read<ApiClient>()
//           .get('/catalog/staff');
// debugPrint('========== STAFF DEBUG ==========');
// debugPrint('Response type: ${response.runtimeType}');
// debugPrint('Response: $response');

// if (response is List) {
//   for (final item in response) {
//     debugPrint('Item type: ${item.runtimeType}');
//     debugPrint('Item: $item');

//     if (item is Map) {
//       debugPrint('Name type: ${item['name']?.runtimeType}');
//       debugPrint('Name: ${item['name']}');
//     }
//   }
// }

// debugPrint('=================================');
//       if (!mounted) {
//         return;
//       }

//       List<dynamic> result = [];

//       if (response is List) {
//         result = List<dynamic>.from(response);
//       } else if (response is Map) {
//         if (response['items'] is List) {
//           result = List<dynamic>.from(
//             response['items'],
//           );
//         } else if (response['data'] is List) {
//           result = List<dynamic>.from(
//             response['data'],
//           );
//         } else if (response['staff'] is List) {
//           result = List<dynamic>.from(
//             response['staff'],
//           );
//         }
//       }

//       setState(() {
//         _staff = result;
//         _loadingStaff = false;
//       });
//     } catch (e) {
//       if (!mounted) {
//         return;
//       }

//       setState(() {
//         _loadingStaff = false;
//       });

//       _showMessage(
//         'Could not load specialists.',
//         error: true,
//       );
//     }
//   }

//   Future<void> _loadAvailability() async {
//     if (_staffId == null) {
//       return;
//     }

//     setState(() {
//       _loadingSlots = true;
//       _selectedSlot = null;
//       _slots = [];
//     });

//     try {
//       final response = await context
//           .read<ApiClient>()
//           .get(
//         '/catalog/availability',
//         query: {
//           'staffId': _staffId,
//           'serviceId': widget.service['id'],
//           'date': _dateForApi(_selectedDate),
//         },
//       );

//       if (!mounted) {
//         return;
//       }

//       final slots = _parseSlots(response);

//       setState(() {
//         _slots = slots;
//         _loadingSlots = false;
//       });
//     } catch (e) {
//       if (!mounted) {
//         return;
//       }

//       setState(() {
//         _slots = [];
//         _loadingSlots = false;
//       });

//       _showMessage(
//         'Could not load available times.',
//         error: true,
//       );
//     }
//   }

//   List<DateTime> _parseSlots(dynamic response) {
//     dynamic rawSlots = response;

//     if (response is Map) {
//       rawSlots = response['slots'] ??
//           response['items'] ??
//           response['data'] ??
//           [];
//     }

//     if (rawSlots is! List) {
//       return [];
//     }

//     final result = <DateTime>[];

//     for (final item in rawSlots) {
//       DateTime? parsed;

//       if (item is String) {
//         parsed = DateTime.tryParse(item);
//       } else if (item is Map) {
//         final value = item['startAt'] ??
//             item['start'] ??
//             item['dateTime'] ??
//             item['time'];

//         if (value is String) {
//           parsed = DateTime.tryParse(value);
//         }
//       }

//       if (parsed != null) {
//         result.add(parsed);
//       }
//     }

//     result.sort();

//     return result;
//   }

//   Future<void> _chooseDate() async {
//     final now = DateTime.now();

//     final picked = await showDatePicker(
//       context: context,
//       initialDate: _selectedDate,
//       firstDate: DateTime(
//         now.year,
//         now.month,
//         now.day,
//       ),
//       lastDate: now.add(
//         const Duration(days: 90),
//       ),
//       helpText: 'Select appointment date',
//     );

//     if (picked == null || !mounted) {
//       return;
//     }

//     setState(() {
//       _selectedDate = picked;
//       _selectedSlot = null;
//     });

//     if (_staffId != null) {
//       await _loadAvailability();
//     }
//   }

//   Future<void> _confirmBooking() async {
//     if (_staffId == null ||
//         _selectedSlot == null ||
//         _booking) {
//       return;
//     }

//     setState(() {
//       _booking = true;
//     });

//     try {
//       await context.read<ApiClient>().post(
//         '/appointments',
//         data: {
//           // TEMPORARY.
//           // This must later come from the logged-in client.
//           'customerId': 1,
//           'serviceId': widget.service['id'],
//           'staffProfileId': _staffId,
//           'startAt':
//               _selectedSlot!.toIso8601String(),
//           'status': 'Confirmed',
//           'paymentStatus': 'Pending',
//           'totalAmount': _servicePrice,
//           'depositAmount': 0,
//         },
//       );

//       if (!mounted) {
//         return;
//       }

//       setState(() {
//         _booking = false;
//       });

//       _showMessage(
//         'Appointment booked successfully.',
//       );

//       Navigator.pop(context, true);
//     } catch (e) {
//       if (!mounted) {
//         return;
//       }

//       setState(() {
//         _booking = false;
//       });

//       _showMessage(
//         'Could not book appointment.',
//         error: true,
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF8F8FB),
//       appBar: AppBar(
//         backgroundColor: const Color(0xFFF8F8FB),
//         elevation: 0,
//         scrolledUnderElevation: 0,
//         title: const Text(
//           'Book appointment',
//           style: TextStyle(
//             fontSize: 17,
//             fontWeight: FontWeight.w700,
//           ),
//         ),
//         centerTitle: true,
//       ),
//       body: SafeArea(
//         child: ListView(
//           padding: const EdgeInsets.fromLTRB(
//             20,
//             12,
//             20,
//             130,
//           ),
//           children: [
//             _buildServiceCard(),

//             const SizedBox(height: 30),

//             _buildStepHeader(
//               number: '1',
//               title: 'Choose specialist',
//               subtitle:
//                   'Select who you would like to book with',
//             ),

//             const SizedBox(height: 15),

//             _buildStaffSection(),

//             const SizedBox(height: 30),

//             _buildStepHeader(
//               number: '2',
//               title: 'Choose a date',
//               subtitle:
//                   'Select your preferred appointment date',
//             ),

//             const SizedBox(height: 15),

//             _buildDateCard(),

//             const SizedBox(height: 30),

//             _buildStepHeader(
//               number: '3',
//               title: 'Available times',
//               subtitle: _staffId == null
//                   ? 'Choose a specialist first'
//                   : 'Select a time that works for you',
//             ),

//             const SizedBox(height: 15),

//             _buildAvailability(),
//           ],
//         ),
//       ),
//       bottomNavigationBar: _buildBottomBar(),
//     );
//   }

//   Widget _buildServiceCard() {
//     return Container(
//       padding: const EdgeInsets.all(18),
//       decoration: BoxDecoration(
//         gradient: const LinearGradient(
//           colors: [
//             Color(0xFF6C63FF),
//             Color(0xFF8A81F7),
//           ],
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//         ),
//         borderRadius: BorderRadius.circular(23),
//         boxShadow: const [
//           BoxShadow(
//             color: Color(0x286C63FF),
//             blurRadius: 25,
//             offset: Offset(0, 10),
//           ),
//         ],
//       ),
//       child: Row(
//         children: [
//           Container(
//             width: 58,
//             height: 58,
//             decoration: BoxDecoration(
//               color: Colors.white.withValues(
//                 alpha: 0.16,
//               ),
//               borderRadius: BorderRadius.circular(17),
//             ),
//             child: const Icon(
//               Icons.spa_outlined,
//               color: Colors.white,
//               size: 27,
//             ),
//           ),
//           const SizedBox(width: 15),
//           Expanded(
//             child: Column(
//               crossAxisAlignment:
//                   CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   _serviceName,
//                   maxLines: 2,
//                   overflow: TextOverflow.ellipsis,
//                   style: const TextStyle(
//                     color: Colors.white,
//                     fontSize: 18,
//                     fontWeight: FontWeight.w800,
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//                 Row(
//                   children: [
//                     const Icon(
//                       Icons.schedule_rounded,
//                       color: Color(0xFFDAD7FF),
//                       size: 15,
//                     ),
//                     const SizedBox(width: 5),
//                     Text(
//                       '$_serviceDuration min',
//                       style: const TextStyle(
//                         color: Color(0xFFE6E4FF),
//                         fontSize: 12,
//                       ),
//                     ),
//                     const SizedBox(width: 14),
//                     const Icon(
//                       Icons.payments_outlined,
//                       color: Color(0xFFDAD7FF),
//                       size: 15,
//                     ),
//                     const SizedBox(width: 5),
//                     Text(
//                       '€${_formatPrice(_servicePrice)}',
//                       style: const TextStyle(
//                         color: Color(0xFFE6E4FF),
//                         fontSize: 12,
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildStepHeader({
//     required String number,
//     required String title,
//     required String subtitle,
//   }) {
//     return Row(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Container(
//           width: 34,
//           height: 34,
//           alignment: Alignment.center,
//           decoration: BoxDecoration(
//             color: const Color(0xFFF0EFFF),
//             borderRadius: BorderRadius.circular(11),
//           ),
//           child: Text(
//             number,
//             style: const TextStyle(
//               color: Color(0xFF6259D7),
//               fontSize: 13,
//               fontWeight: FontWeight.w800,
//             ),
//           ),
//         ),
//         const SizedBox(width: 12),
//         Expanded(
//           child: Column(
//             crossAxisAlignment:
//                 CrossAxisAlignment.start,
//             children: [
//               Text(
//                 title,
//                 style: const TextStyle(
//                   color: Color(0xFF282931),
//                   fontSize: 16,
//                   fontWeight: FontWeight.w700,
//                 ),
//               ),
//               const SizedBox(height: 3),
//               Text(
//                 subtitle,
//                 style: const TextStyle(
//                   color: Color(0xFF8C8E9A),
//                   fontSize: 11,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildStaffSection() {
//     if (_loadingStaff) {
//       return _loadingBox(
//         height: 92,
//       );
//     }

//     if (_staff.isEmpty) {
//       return _messageBox(
//         icon: Icons.person_off_outlined,
//         text: 'No specialists available.',
//       );
//     }

//     return SizedBox(
//       height: 100,
//       child: ListView.separated(
//         scrollDirection: Axis.horizontal,
//         itemCount: _staff.length,
//         separatorBuilder: (_, __) =>
//             const SizedBox(width: 10),
//         itemBuilder: (context, index) {
//           final member = _staff[index];

//           final id = _staffIdFrom(member);
//           final name = _staffName(member);

//           final selected =
//               id != null && id == _staffId;

//           return InkWell(
//             borderRadius: BorderRadius.circular(17),
//             onTap: id == null
//                 ? null
//                 : () {
//                     setState(() {
//                       _staffId = id;
//                       _selectedSlot = null;
//                     });

//                     _loadAvailability();
//                   },
//             child: AnimatedContainer(
//               duration:
//                   const Duration(milliseconds: 180),
//               width: 145,
//               padding: const EdgeInsets.all(13),
//               decoration: BoxDecoration(
//                 color: selected
//                     ? const Color(0xFF6C63FF)
//                     : Colors.white,
//                 borderRadius:
//                     BorderRadius.circular(17),
//                 border: Border.all(
//                   color: selected
//                       ? const Color(0xFF6C63FF)
//                       : const Color(0xFFE8E8EE),
//                 ),
//               ),
//               child: Row(
//                 children: [
//                   CircleAvatar(
//                     radius: 20,
//                     backgroundColor: selected
//                         ? Colors.white.withValues(
//                             alpha: 0.17,
//                           )
//                         : const Color(0xFFF0EFFF),
//                     child: Text(
//                       _initials(name),
//                       style: TextStyle(
//                         color: selected
//                             ? Colors.white
//                             : const Color(
//                                 0xFF6259D7,
//                               ),
//                         fontWeight: FontWeight.w800,
//                         fontSize: 12,
//                       ),
//                     ),
//                   ),
//                   const SizedBox(width: 10),
//                   Expanded(
//                     child: Text(
//                       name,
//                       maxLines: 2,
//                       overflow: TextOverflow.ellipsis,
//                       style: TextStyle(
//                         color: selected
//                             ? Colors.white
//                             : const Color(
//                                 0xFF35363E,
//                               ),
//                         fontSize: 12,
//                         height: 1.3,
//                         fontWeight: FontWeight.w700,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }

//   Widget _buildDateCard() {
//     return Material(
//       color: Colors.white,
//       borderRadius: BorderRadius.circular(17),
//       child: InkWell(
//         onTap: _chooseDate,
//         borderRadius: BorderRadius.circular(17),
//         child: Container(
//           padding: const EdgeInsets.all(16),
//           decoration: BoxDecoration(
//             borderRadius: BorderRadius.circular(17),
//             border: Border.all(
//               color: const Color(0xFFE8E8EE),
//             ),
//           ),
//           child: Row(
//             children: [
//               Container(
//                 width: 45,
//                 height: 45,
//                 decoration: BoxDecoration(
//                   color: const Color(0xFFF0EFFF),
//                   borderRadius:
//                       BorderRadius.circular(13),
//                 ),
//                 child: const Icon(
//                   Icons.calendar_month_rounded,
//                   color: Color(0xFF6C63FF),
//                   size: 21,
//                 ),
//               ),
//               const SizedBox(width: 13),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment:
//                       CrossAxisAlignment.start,
//                   children: [
//                     const Text(
//                       'Appointment date',
//                       style: TextStyle(
//                         color: Color(0xFF8B8D99),
//                         fontSize: 11,
//                       ),
//                     ),
//                     const SizedBox(height: 4),
//                     Text(
//                       _formattedDate(
//                         _selectedDate,
//                       ),
//                       style: const TextStyle(
//                         color: Color(0xFF303139),
//                         fontSize: 14,
//                         fontWeight: FontWeight.w700,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               const Icon(
//                 Icons.chevron_right_rounded,
//                 color: Color(0xFF9698A4),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildAvailability() {
//     if (_staffId == null) {
//       return _messageBox(
//         icon: Icons.touch_app_outlined,
//         text:
//             'Choose a specialist to see available times.',
//       );
//     }

//     if (_loadingSlots) {
//       return _loadingBox(
//         height: 100,
//       );
//     }

//     if (_slots.isEmpty) {
//       return _messageBox(
//         icon: Icons.event_busy_outlined,
//         text:
//             'No available times for this date.',
//       );
//     }

//     return Wrap(
//       spacing: 9,
//       runSpacing: 9,
//       children: _slots.map((time) {
//         final selected =
//             _selectedSlot == time;

//         return InkWell(
//           borderRadius: BorderRadius.circular(13),
//           onTap: () {
//             setState(() {
//               _selectedSlot = time;
//             });
//           },
//           child: AnimatedContainer(
//             duration:
//                 const Duration(milliseconds: 160),
//             padding: const EdgeInsets.symmetric(
//               horizontal: 18,
//               vertical: 12,
//             ),
//             decoration: BoxDecoration(
//               color: selected
//                   ? const Color(0xFF6C63FF)
//                   : Colors.white,
//               borderRadius: BorderRadius.circular(13),
//               border: Border.all(
//                 color: selected
//                     ? const Color(0xFF6C63FF)
//                     : const Color(0xFFE5E5EB),
//               ),
//             ),
//             child: Text(
//               _formatTime(time),
//               style: TextStyle(
//                 color: selected
//                     ? Colors.white
//                     : const Color(0xFF4F515C),
//                 fontSize: 12,
//                 fontWeight: FontWeight.w700,
//               ),
//             ),
//           ),
//         );
//       }).toList(),
//     );
//   }

//   Widget _buildBottomBar() {
//     final canBook = _staffId != null &&
//         _selectedSlot != null &&
//         !_booking;

//     return Container(
//       padding: EdgeInsets.fromLTRB(
//         20,
//         14,
//         20,
//         14 + MediaQuery.paddingOf(context).bottom,
//       ),
//       decoration: const BoxDecoration(
//         color: Colors.white,
//         boxShadow: [
//           BoxShadow(
//             color: Color(0x10000000),
//             blurRadius: 20,
//             offset: Offset(0, -5),
//           ),
//         ],
//       ),
//       child: Row(
//         children: [
//           Expanded(
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               crossAxisAlignment:
//                   CrossAxisAlignment.start,
//               children: [
//                 const Text(
//                   'Total',
//                   style: TextStyle(
//                     color: Color(0xFF92939F),
//                     fontSize: 11,
//                   ),
//                 ),
//                 const SizedBox(height: 2),
//                 Text(
//                   '€${_formatPrice(_servicePrice)}',
//                   style: const TextStyle(
//                     fontSize: 19,
//                     fontWeight: FontWeight.w800,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           SizedBox(
//             height: 50,
//             child: FilledButton(
//               onPressed:
//                   canBook ? _confirmBooking : null,
//               style: FilledButton.styleFrom(
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 25,
//                 ),
//                 shape: RoundedRectangleBorder(
//                   borderRadius:
//                       BorderRadius.circular(15),
//                 ),
//               ),
//               child: _booking
//                   ? const SizedBox(
//                       width: 19,
//                       height: 19,
//                       child:
//                           CircularProgressIndicator(
//                         strokeWidth: 2,
//                         color: Colors.white,
//                       ),
//                     )
//                   : const Row(
//                       mainAxisSize:
//                           MainAxisSize.min,
//                       children: [
//                         Text(
//                           'Confirm booking',
//                           style: TextStyle(
//                             fontWeight:
//                                 FontWeight.w700,
//                           ),
//                         ),
//                         SizedBox(width: 8),
//                         Icon(
//                           Icons.arrow_forward_rounded,
//                           size: 18,
//                         ),
//                       ],
//                     ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _loadingBox({
//     required double height,
//   }) {
//     return Container(
//       height: height,
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(17),
//         border: Border.all(
//           color: const Color(0xFFE8E8EE),
//         ),
//       ),
//       child: const Center(
//         child: SizedBox(
//           width: 22,
//           height: 22,
//           child: CircularProgressIndicator(
//             strokeWidth: 2.3,
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _messageBox({
//     required IconData icon,
//     required String text,
//   }) {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(22),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(17),
//         border: Border.all(
//           color: const Color(0xFFE8E8EE),
//         ),
//       ),
//       child: Column(
//         children: [
//           Icon(
//             icon,
//             color: const Color(0xFF989AA6),
//             size: 27,
//           ),
//           const SizedBox(height: 9),
//           Text(
//             text,
//             textAlign: TextAlign.center,
//             style: const TextStyle(
//               color: Color(0xFF7E808C),
//               fontSize: 12,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   int? _staffIdFrom(dynamic member) {
//     if (member is! Map) {
//       return null;
//     }

//     final value =
//         member['id'] ??
//         member['staffProfileId'] ??
//         member['userId'];

//     if (value is int) {
//       return value;
//     }

//     return int.tryParse(
//       value?.toString() ?? '',
//     );
//   }

//   String _staffName(dynamic member) {
//     if (member is! Map) {
//       return 'Specialist';
//     }

//     final name = member['name'];

//     // API can sometimes return name as an object.
//     if (name is String &&
//         name.trim().isNotEmpty) {
//       return name.trim();
//     }

//     if (name is Map) {
//       final firstName =
//           name['firstName']?.toString() ?? '';

//       final lastName =
//           name['lastName']?.toString() ?? '';

//       final fullName =
//           '$firstName $lastName'.trim();

//       if (fullName.isNotEmpty) {
//         return fullName;
//       }
//     }

//     final firstName =
//         member['firstName']?.toString() ?? '';

//     final lastName =
//         member['lastName']?.toString() ?? '';

//     final fullName =
//         '$firstName $lastName'.trim();

//     if (fullName.isNotEmpty) {
//       return fullName;
//     }

//     final user = member['user'];

//     if (user is Map) {
//       final userFirstName =
//           user['firstName']?.toString() ?? '';

//       final userLastName =
//           user['lastName']?.toString() ?? '';

//       final userFullName =
//           '$userFirstName $userLastName'.trim();

//       if (userFullName.isNotEmpty) {
//         return userFullName;
//       }
//     }

//     return 'Specialist';
//   }

//   String get _serviceName {
//     final value = widget.service['name'];

//     if (value is String) {
//       return value;
//     }

//     if (value is Map) {
//       final name =
//           value['name'] ??
//           value['title'];

//       if (name != null) {
//         return name.toString();
//       }
//     }

//     return 'Service';
//   }

//   int get _serviceDuration {
//     final value =
//         widget.service['durationMinutes'];

//     if (value is int) {
//       return value;
//     }

//     return int.tryParse(
//           value?.toString() ?? '',
//         ) ??
//         0;
//   }

//   double get _servicePrice {
//     final value = widget.service['price'];

//     if (value is num) {
//       return value.toDouble();
//     }

//     return double.tryParse(
//           value?.toString() ?? '',
//         ) ??
//         0;
//   }

//   String _formatPrice(double price) {
//     return price.toStringAsFixed(2);
//   }

//   String _formatTime(DateTime time) {
//     final hour =
//         time.hour.toString().padLeft(2, '0');

//     final minute =
//         time.minute.toString().padLeft(2, '0');

//     return '$hour:$minute';
//   }

//   String _formattedDate(DateTime value) {
//     const months = [
//       'January',
//       'February',
//       'March',
//       'April',
//       'May',
//       'June',
//       'July',
//       'August',
//       'September',
//       'October',
//       'November',
//       'December',
//     ];

//     return '${value.day} '
//         '${months[value.month - 1]} '
//         '${value.year}';
//   }

//   String _dateForApi(DateTime value) {
//     final month =
//         value.month.toString().padLeft(2, '0');

//     final day =
//         value.day.toString().padLeft(2, '0');

//     return '${value.year}-$month-$day';
//   }

//   String _initials(String name) {
//     final parts = name
//         .trim()
//         .split(' ')
//         .where((x) => x.isNotEmpty)
//         .toList();

//     if (parts.isEmpty) {
//       return 'S';
//     }

//     if (parts.length == 1) {
//       return parts.first[0].toUpperCase();
//     }

//     return '${parts.first[0]}${parts.last[0]}'
//         .toUpperCase();
//   }

//   void _showMessage(
//     String message, {
//     bool error = false,
//   }) {
//     ScaffoldMessenger.of(context)
//       ..hideCurrentSnackBar()
//       ..showSnackBar(
//         SnackBar(
//           behavior: SnackBarBehavior.floating,
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

class BookingPage extends StatefulWidget {
  final Map service;

  const BookingPage({
    super.key,
    required this.service,
  });

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  List<dynamic> _staff = [];
  List<DateTime> _availableSlots = [];

  int? _selectedStaffId;
  DateTime _selectedDate = DateTime.now().add(
    const Duration(days: 1),
  );
  DateTime? _selectedSlot;

  bool _loadingStaff = true;
  bool _loadingSlots = false;
  bool _booking = false;
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_loaded) {
      _loaded = true;
      _loadStaff();
    }
  }

  Future<void> _loadStaff() async {
    try {
      final response = await context
          .read<ApiClient>()
          .get('/catalog/staff');

      if (!mounted) {
        return;
      }

      setState(() {
        if (response is List) {
          _staff = List<dynamic>.from(response);
        } else {
          _staff = [];
        }

        _loadingStaff = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _staff = [];
        _loadingStaff = false;
      });

      _showMessage(
        'Could not load specialists.',
        isError: true,
      );
    }
  }

  Future<void> _loadAvailability() async {
    if (_selectedStaffId == null) {
      return;
    }

    setState(() {
      _loadingSlots = true;
      _availableSlots = [];
      _selectedSlot = null;
    });

    try {
      final response = await context
          .read<ApiClient>()
          .get(
        '/catalog/availability',
        query: {
          'staffId': _selectedStaffId,
          'serviceId': _serviceId,
          'date': _apiDate(_selectedDate),
        },
      );

      final slots = <DateTime>[];

      if (response is List) {
        for (final value in response) {
          final parsed = DateTime.tryParse(
            value.toString(),
          );

          if (parsed != null) {
            slots.add(parsed);
          }
        }
      }

      slots.sort();

      if (!mounted) {
        return;
      }

      setState(() {
        _availableSlots = slots;
        _loadingSlots = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _availableSlots = [];
        _loadingSlots = false;
      });

      _showMessage(
        'Could not load available times.',
        isError: true,
      );
    }
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();

    final result = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(
        now.year,
        now.month,
        now.day,
      ),
      lastDate: now.add(
        const Duration(days: 90),
      ),
    );

    if (result == null || !mounted) {
      return;
    }

    setState(() {
      _selectedDate = result;
      _selectedSlot = null;
      _availableSlots = [];
    });

    if (_selectedStaffId != null) {
      await _loadAvailability();
    }
  }

  Future<void> _confirmBooking() async {
    if (_selectedStaffId == null ||
        _selectedSlot == null ||
        _booking) {
      return;
    }

    setState(() {
      _booking = true;
    });

    try {
      await context.read<ApiClient>().post(
        '/appointments',
        data: {
          'customerId': 1,
          'serviceId': _serviceId,
          'staffProfileId': _selectedStaffId,
          'startAt': _selectedSlot!.toIso8601String(),
          'status': 'Confirmed',
          'paymentStatus': 'Pending',
          'totalAmount': _servicePrice,
          'depositAmount': 0,
        },
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _booking = false;
      });

      _showMessage(
        'Appointment booked successfully.',
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _booking = false;
      });

      _showMessage(
        'Could not book appointment.',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F8FB),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: const Text(
          'Book appointment',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            20,
            10,
            20,
            130,
          ),
          children: [
            _serviceCard(),

            const SizedBox(height: 30),

            _sectionTitle(
              number: '1',
              title: 'Choose specialist',
              subtitle: 'Who would you like to book with?',
            ),

            const SizedBox(height: 15),

            _staffSection(),

            const SizedBox(height: 30),

            _sectionTitle(
              number: '2',
              title: 'Choose date',
              subtitle: 'Select your appointment date',
            ),

            const SizedBox(height: 15),

            _dateCard(),

            const SizedBox(height: 30),

            _sectionTitle(
              number: '3',
              title: 'Available times',
              subtitle: _selectedStaffId == null
                  ? 'Choose a specialist first'
                  : 'Choose a time that works for you',
            ),

            const SizedBox(height: 15),

            _slotsSection(),
          ],
        ),
      ),
      bottomNavigationBar: _bottomBar(),
    );
  }

  Widget _serviceCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF6C63FF),
            Color(0xFF8A81F7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x286C63FF),
            blurRadius: 25,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white.withValues(
                alpha: 0.16,
              ),
              borderRadius: BorderRadius.circular(17),
            ),
            child: const Icon(
              Icons.spa_outlined,
              color: Colors.white,
              size: 28,
            ),
          ),

          const SizedBox(width: 15),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _serviceName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 9),

                Row(
                  children: [
                    const Icon(
                      Icons.schedule_rounded,
                      color: Color(0xFFE5E3FF),
                      size: 15,
                    ),

                    const SizedBox(width: 5),

                    Text(
                      '$_serviceDuration min',
                      style: const TextStyle(
                        color: Color(0xFFE5E3FF),
                        fontSize: 12,
                      ),
                    ),

                    const SizedBox(width: 15),

                    const Icon(
                      Icons.payments_outlined,
                      color: Color(0xFFE5E3FF),
                      size: 15,
                    ),

                    const SizedBox(width: 5),

                    Text(
                      '€${_servicePrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Color(0xFFE5E3FF),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle({
    required String number,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 35,
          height: 35,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFF0EFFF),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Text(
            number,
            style: const TextStyle(
              color: Color(0xFF6259D7),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF282931),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 3),

              Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xFF8C8E9A),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _staffSection() {
    if (_loadingStaff) {
      return _loadingContainer();
    }

    if (_staff.isEmpty) {
      return _emptyContainer(
        icon: Icons.person_off_outlined,
        text: 'No specialists available.',
      );
    }

    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _staff.length,
        separatorBuilder: (_, __) {
          return const SizedBox(width: 10);
        },
        itemBuilder: (context, index) {
          final member = _staff[index];

          if (member is! Map) {
            return const SizedBox.shrink();
          }

          final id = _toInt(member['id']);
          final name = _text(
            member['name'],
            fallback: 'Specialist',
          );

          final selected =
              id != null && id == _selectedStaffId;

          return InkWell(
            borderRadius: BorderRadius.circular(17),
            onTap: id == null
                ? null
                : () {
                    setState(() {
                      _selectedStaffId = id;
                      _selectedSlot = null;
                    });

                    _loadAvailability();
                  },
            child: AnimatedContainer(
              duration: const Duration(
                milliseconds: 180,
              ),
              width: 150,
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xFF6C63FF)
                    : Colors.white,
                borderRadius: BorderRadius.circular(17),
                border: Border.all(
                  color: selected
                      ? const Color(0xFF6C63FF)
                      : const Color(0xFFE8E8EE),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: selected
                        ? Colors.white.withValues(
                            alpha: 0.17,
                          )
                        : const Color(0xFFF0EFFF),
                    child: Text(
                      _initials(name),
                      style: TextStyle(
                        color: selected
                            ? Colors.white
                            : const Color(0xFF6259D7),
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: selected
                            ? Colors.white
                            : const Color(0xFF35363E),
                        fontSize: 12,
                        height: 1.3,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _dateCard() {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        onTap: _selectDate,
        borderRadius: BorderRadius.circular(17),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(17),
            border: Border.all(
              color: const Color(0xFFE8E8EE),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0EFFF),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.calendar_month_rounded,
                  color: Color(0xFF6C63FF),
                ),
              ),

              const SizedBox(width: 13),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Appointment date',
                      style: TextStyle(
                        color: Color(0xFF8B8D99),
                        fontSize: 11,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      _displayDate(_selectedDate),
                      style: const TextStyle(
                        color: Color(0xFF303139),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),

              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF9698A4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _slotsSection() {
    if (_selectedStaffId == null) {
      return _emptyContainer(
        icon: Icons.touch_app_outlined,
        text:
            'Choose a specialist to see available times.',
      );
    }

    if (_loadingSlots) {
      return _loadingContainer();
    }

    if (_availableSlots.isEmpty) {
      return _emptyContainer(
        icon: Icons.event_busy_outlined,
        text: 'No available times for this date.',
      );
    }

    return Wrap(
      spacing: 9,
      runSpacing: 9,
      children: _availableSlots.map((time) {
        final selected = _selectedSlot == time;

        return InkWell(
          borderRadius: BorderRadius.circular(13),
          onTap: () {
            setState(() {
              _selectedSlot = time;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(
              milliseconds: 160,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: selected
                  ? const Color(0xFF6C63FF)
                  : Colors.white,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: selected
                    ? const Color(0xFF6C63FF)
                    : const Color(0xFFE5E5EB),
              ),
            ),
            child: Text(
              _timeText(time),
              style: TextStyle(
                color: selected
                    ? Colors.white
                    : const Color(0xFF4F515C),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _bottomBar() {
    final enabled = _selectedStaffId != null &&
        _selectedSlot != null &&
        !_booking;

    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        14,
        20,
        14 + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 20,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(
                    color: Color(0xFF92939F),
                    fontSize: 11,
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  '€${_servicePrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(
            height: 50,
            child: FilledButton(
              onPressed: enabled
                  ? _confirmBooking
                  : null,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 25,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: _booking
                  ? const SizedBox(
                      width: 19,
                      height: 19,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Confirm booking',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 18,
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _loadingContainer() {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: const Color(0xFFE8E8EE),
        ),
      ),
      alignment: Alignment.center,
      child: const SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2.3,
        ),
      ),
    );
  }

  Widget _emptyContainer({
    required IconData icon,
    required String text,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: const Color(0xFFE8E8EE),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: const Color(0xFF989AA6),
            size: 27,
          ),
          const SizedBox(height: 9),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF7E808C),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  int get _serviceId {
    return _toInt(widget.service['id']) ?? 0;
  }

  String get _serviceName {
    return _text(
      widget.service['name'],
      fallback: 'Service',
    );
  }

  int get _serviceDuration {
    return _toInt(
          widget.service['durationMinutes'],
        ) ??
        0;
  }

  double get _servicePrice {
    final value = widget.service['price'];

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  String _text(
    dynamic value, {
    String fallback = '',
  }) {
    if (value == null) {
      return fallback;
    }

    if (value is String) {
      final result = value.trim();

      return result.isEmpty
          ? fallback
          : result;
    }

    return value.toString();
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

  String _initials(String name) {
    final parts = name
        .trim()
        .split(' ')
        .where((value) => value.isNotEmpty)
        .toList();

    if (parts.isEmpty) {
      return 'S';
    }

    if (parts.length == 1) {
      return parts.first[0].toUpperCase();
    }

    return '${parts.first[0]}${parts.last[0]}'
        .toUpperCase();
  }

  String _timeText(DateTime value) {
    final hour = value.hour
        .toString()
        .padLeft(2, '0');

    final minute = value.minute
        .toString()
        .padLeft(2, '0');

    return '$hour:$minute';
  }

  String _apiDate(DateTime value) {
    final month = value.month
        .toString()
        .padLeft(2, '0');

    final day = value.day
        .toString()
        .padLeft(2, '0');

    return '${value.year}-$month-$day';
  }

  String _displayDate(DateTime value) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return '${value.day} '
        '${months[value.month - 1]} '
        '${value.year}';
  }

  void _showMessage(
    String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: isError
              ? const Color(0xFFD94343)
              : const Color(0xFF292B38),
          content: Text(message),
        ),
      );
  }
}