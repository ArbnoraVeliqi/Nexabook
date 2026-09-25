// import 'package:flutter/material.dart';import 'package:provider/provider.dart';import '../core/api_client.dart';import '../widgets/page_header.dart';class ExpensesPage extends StatefulWidget{const ExpensesPage({super.key});State<ExpensesPage>createState()=>_S();}class _S extends State<ExpensesPage>{List data=[];bool loading=true;@override void didChangeDependencies(){super.didChangeDependencies();load();}Future load()async{try{final x=await context.read<ApiClient>().get('/finance/expenses');if(mounted)setState((){data=x;loading=false;});}catch(_){if(mounted)setState(()=>loading=false);}}@override Widget build(BuildContext c)=>ListView(padding:const EdgeInsets.all(28),children:[PageHeader('Expenses','Operational expenses and business costs',action:FilledButton.icon(onPressed:()=>showDialog(context:c,builder:(_)=>AlertDialog(title:const Text('New Expense'),content:const Text('Create form is connected through the API layer and can be extended with business-specific fields.'),actions:[TextButton(onPressed:()=>Navigator.pop(c),child:const Text('Close'))])),icon:const Icon(Icons.add),label:const Text('Add new'))),const SizedBox(height:22),Card(child:loading?const Padding(padding:EdgeInsets.all(40),child:Center(child:CircularProgressIndicator())):data.isEmpty?const Padding(padding:EdgeInsets.all(40),child:Center(child:Text('No records found'))):SingleChildScrollView(scrollDirection:Axis.horizontal,child:DataTable(columns:const[DataColumn(label:Text('Name / Reference')),DataColumn(label:Text('Details')),DataColumn(label:Text('Status')),DataColumn(label:Text('Actions'))],rows:data.map((x)=>DataRow(cells:[DataCell(Text((x['description']??'—').toString())),DataCell(Text((x['category']??'—').toString())),DataCell(Text((x['status']??x['paymentStatus']??x['isActive']??'Active').toString())),const DataCell(Icon(Icons.more_horiz))])).toList())))]);}
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api_client.dart';
import '../widgets/page_header.dart';

class ExpensesPage extends StatefulWidget {
  const ExpensesPage({super.key});

  @override
  State<ExpensesPage> createState() => _ExpensesPageState();
}

class _ExpensesPageState extends State<ExpensesPage> {
  final TextEditingController _searchController = TextEditingController();

  bool _initialized = false;
  bool _loading = true;

  List<dynamic> _expenses = [];

  String _search = '';
  String _categoryFilter = 'All categories';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_initialized) {
      _initialized = true;
      _loadExpenses();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadExpenses() async {
    if (mounted) {
      setState(() {
        _loading = true;
      });
    }

    try {
      final result = await context
          .read<ApiClient>()
          .get('/finance/expenses');

      if (!mounted) {
        return;
      }

      setState(() {
        _expenses = result is List
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

      _showMessage(
        'Could not load expenses.',
        error: true,
      );
    }
  }

  List<dynamic> get _filteredExpenses {
    final query = _search.trim().toLowerCase();

    return _expenses.where((expense) {
      final description =
          _text(expense['description']).toLowerCase();

      final category =
          _text(expense['category']).toLowerCase();

      final notes =
          _text(expense['notes']).toLowerCase();

      final matchesSearch = query.isEmpty ||
          description.contains(query) ||
          category.contains(query) ||
          notes.contains(query);

      final matchesCategory =
          _categoryFilter == 'All categories' ||
              category == _categoryFilter.toLowerCase();

      return matchesSearch && matchesCategory;
    }).toList();
  }

  List<String> get _categories {
    final categories = _expenses
        .map(
          (expense) => _text(expense['category']),
        )
        .where(
          (category) => category.isNotEmpty,
        )
        .toSet()
        .toList();

    categories.sort();

    return categories;
  }

  double get _totalExpenses {
    return _expenses.fold<double>(
      0,
      (total, expense) =>
          total + _number(expense['amount']),
    );
  }

  double get _thisMonthExpenses {
    final now = DateTime.now();

    return _expenses.where((expense) {
      final date = _expenseDate(expense);

      if (date == null) {
        return false;
      }

      return date.year == now.year &&
          date.month == now.month;
    }).fold<double>(
      0,
      (total, expense) =>
          total + _number(expense['amount']),
    );
  }

  double get _thisYearExpenses {
    final now = DateTime.now();

    return _expenses.where((expense) {
      final date = _expenseDate(expense);

      return date != null &&
          date.year == now.year;
    }).fold<double>(
      0,
      (total, expense) =>
          total + _number(expense['amount']),
    );
  }

  double get _averageExpense {
    if (_expenses.isEmpty) {
      return 0;
    }

    return _totalExpenses / _expenses.length;
  }

  @override
  Widget build(BuildContext context) {
    final expenses = _filteredExpenses;

    return RefreshIndicator(
      onRefresh: _loadExpenses,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(28),
        children: [
          PageHeader(
            'Expenses',
            'Track operational expenses and business costs',
            action: FilledButton.icon(
              onPressed: _showCreateExpensePlaceholder,
              icon: const Icon(
                Icons.add_rounded,
                size: 19,
              ),
              label: const Text(
                'Add expense',
              ),
            ),
          ),

          const SizedBox(height: 26),

          _buildSummary(),

          const SizedBox(height: 22),

          _buildToolbar(),

          const SizedBox(height: 16),

          if (_loading)
            _buildLoading()
          else if (expenses.isEmpty)
            _buildEmpty()
          else
            _buildExpensesTable(expenses),
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
              title: 'Total expenses',
              value: _currency(_totalExpenses),
              subtitle:
                  '${_expenses.length} ${_expenses.length == 1 ? 'expense' : 'expenses'}',
              icon: Icons.receipt_long_outlined,
              background:
                  const Color(0xFFFFEEEE),
              iconColor:
                  const Color(0xFFD95864),
            ),
            _summaryCard(
              width: cardWidth,
              title: 'This month',
              value:
                  _currency(_thisMonthExpenses),
              subtitle:
                  _monthName(DateTime.now().month),
              icon:
                  Icons.calendar_month_outlined,
              background:
                  const Color(0xFFFFF4E8),
              iconColor:
                  const Color(0xFFE28A36),
            ),
            _summaryCard(
              width: cardWidth,
              title: 'This year',
              value:
                  _currency(_thisYearExpenses),
              subtitle:
                  '${DateTime.now().year}',
              icon:
                  Icons.bar_chart_rounded,
              background:
                  const Color(0xFFEAF6FF),
              iconColor:
                  const Color(0xFF4389C7),
            ),
            _summaryCard(
              width: cardWidth,
              title: 'Average expense',
              value:
                  _currency(_averageExpense),
              subtitle:
                  'Per transaction',
              icon:
                  Icons.analytics_outlined,
              background:
                  const Color(0xFFF0EFFF),
              iconColor:
                  const Color(0xFF6C63FF),
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
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: background,
                borderRadius:
                    BorderRadius.circular(15),
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
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 23,
                      height: 1.1,
                      fontWeight:
                          FontWeight.w800,
                      color:
                          Color(0xFF252631),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight:
                          FontWeight.w600,
                      color:
                          Color(0xFF5E606E),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color:
                          Color(0xFF9698A5),
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
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color:
              const Color(0xFFE9EAF0),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact =
              constraints.maxWidth < 800;

          if (compact) {
            return Column(
              children: [
                _buildSearch(),
                const SizedBox(height: 12),
                _buildCategoryFilter(),
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
                width: 210,
                child:
                    _buildCategoryFilter(),
              ),
              const SizedBox(width: 7),
              IconButton(
                tooltip: 'Refresh',
                onPressed: _loadExpenses,
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
      onChanged: (value) {
        setState(() {
          _search = value;
        });
      },
      decoration: InputDecoration(
        hintText:
            'Search expenses...',
        prefixIcon: const Icon(
          Icons.search_rounded,
          size: 21,
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
        filled: true,
        fillColor:
            const Color(0xFFF8F9FC),
        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(13),
          borderSide: BorderSide.none,
        ),
        enabledBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(13),
          borderSide: BorderSide.none,
        ),
        focusedBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(13),
          borderSide: const BorderSide(
            color:
                Color(0xFF6C63FF),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    final categories = [
      'All categories',
      ..._categories,
    ];

    final selected =
        categories.contains(
          _categoryFilter,
        )
            ? _categoryFilter
            : 'All categories';

    return DropdownButtonFormField<String>(
      value: selected,
      isExpanded: true,
      decoration: InputDecoration(
        prefixIcon: const Icon(
          Icons.category_outlined,
          size: 19,
        ),
        filled: true,
        fillColor:
            const Color(0xFFF8F9FC),
        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(13),
          borderSide: BorderSide.none,
        ),
        enabledBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(13),
          borderSide: BorderSide.none,
        ),
      ),
      items: categories.map((category) {
        return DropdownMenuItem<String>(
          value: category,
          child: Text(
            category,
            overflow:
                TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: (value) {
        if (value == null) {
          return;
        }

        setState(() {
          _categoryFilter = value;
        });
      },
    );
  }

  Widget _buildExpensesTable(
    List<dynamic> expenses,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color:
              const Color(0xFFE9EAF0),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _buildTableHeader(),

          for (int index = 0;
              index < expenses.length;
              index++) ...[
            _buildExpenseRow(
              expenses[index],
            ),
            if (index !=
                expenses.length - 1)
              const Divider(
                height: 1,
                indent: 20,
                endIndent: 20,
                color:
                    Color(0xFFEEEEF2),
              ),
          ],

          _buildTableFooter(
            expenses,
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 14,
      ),
      color:
          const Color(0xFFF8F9FC),
      child: const Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              'EXPENSE',
              style:
                  _expenseHeaderStyle,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'CATEGORY',
              style:
                  _expenseHeaderStyle,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'DATE',
              style:
                  _expenseHeaderStyle,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'AMOUNT',
              style:
                  _expenseHeaderStyle,
            ),
          ),
          SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildExpenseRow(
    dynamic expense,
  ) {
    final description =
        _text(expense['description']);

    final category =
        _text(expense['category']);

    final amount =
        _number(expense['amount']);

    return InkWell(
      onTap: () {
        _showExpenseDetails(
          expense,
        );
      },
      child: Padding(
        padding:
            const EdgeInsets.symmetric(
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
                    decoration:
                        BoxDecoration(
                      color:
                          const Color(
                        0xFFFFEEEE,
                      ),
                      borderRadius:
                          BorderRadius.circular(
                        13,
                      ),
                    ),
                    child: const Icon(
                      Icons
                          .receipt_long_outlined,
                      color:
                          Color(0xFFD95864),
                      size: 20,
                    ),
                  ),
                  const SizedBox(
                      width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: [
                        Text(
                          description
                                  .isEmpty
                              ? 'Expense'
                              : description,
                          maxLines: 1,
                          overflow:
                              TextOverflow
                                  .ellipsis,
                          style:
                              const TextStyle(
                            fontSize: 13,
                            fontWeight:
                                FontWeight
                                    .w700,
                            color:
                                Color(
                              0xFF292A35,
                            ),
                          ),
                        ),
                        const SizedBox(
                            height: 4),
                        Text(
                          _expenseReference(
                            expense,
                          ),
                          maxLines: 1,
                          overflow:
                              TextOverflow
                                  .ellipsis,
                          style:
                              const TextStyle(
                            color:
                                Color(
                              0xFF9294A2,
                            ),
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
              flex: 2,
              child: Align(
                alignment:
                    Alignment.centerLeft,
                child:
                    _categoryBadge(
                  category.isEmpty
                      ? 'Other'
                      : category,
                ),
              ),
            ),

            Expanded(
              flex: 2,
              child: Text(
                _formatDate(
                  _expenseDateValue(
                    expense,
                  ),
                ),
                style: const TextStyle(
                  color:
                      Color(0xFF666875),
                  fontSize: 12,
                ),
              ),
            ),

            Expanded(
              flex: 2,
              child: Text(
                _currency(amount),
                style: const TextStyle(
                  color:
                      Color(0xFFD14E57),
                  fontSize: 14,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),
            ),

            SizedBox(
              width: 48,
              child:
                  PopupMenuButton<String>(
                tooltip: 'Actions',
                icon: const Icon(
                  Icons
                      .more_horiz_rounded,
                  color:
                      Color(0xFF777986),
                ),
                onSelected: (value) {
                  if (value ==
                      'view') {
                    _showExpenseDetails(
                      expense,
                    );
                  }

                  if (value ==
                      'edit') {
                    _showEditPlaceholder(
                      expense,
                    );
                  }
                },
                itemBuilder: (_) =>
                    const [
                  PopupMenuItem(
                    value: 'view',
                    child: Row(
                      children: [
                        Icon(
                          Icons
                              .visibility_outlined,
                          size: 18,
                        ),
                        SizedBox(
                            width: 10),
                        Text(
                            'View details'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(
                          Icons
                              .edit_outlined,
                          size: 18,
                        ),
                        SizedBox(
                            width: 10),
                        Text(
                            'Edit expense'),
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

  Widget _categoryBadge(
    String category,
  ) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color:
            const Color(0xFFF2F2F7),
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Text(
        category,
        maxLines: 1,
        overflow:
            TextOverflow.ellipsis,
        style: const TextStyle(
          color:
              Color(0xFF5F6170),
          fontSize: 11,
          fontWeight:
              FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildTableFooter(
    List<dynamic> expenses,
  ) {
    final total =
        expenses.fold<double>(
      0,
      (sum, expense) =>
          sum +
          _number(
            expense['amount'],
          ),
    );

    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 13,
      ),
      color:
          const Color(0xFFFBFBFD),
      child: Row(
        children: [
          Text(
            '${expenses.length} ${expenses.length == 1 ? 'expense' : 'expenses'} shown',
            style: const TextStyle(
              color:
                  Color(0xFF77798A),
              fontSize: 12,
            ),
          ),
          const Spacer(),
          Text(
            'Total ${_currency(total)}',
            style: const TextStyle(
              color:
                  Color(0xFF555766),
              fontSize: 12,
              fontWeight:
                  FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  void _showExpenseDetails(
    dynamic expense,
  ) {
    final description =
        _text(expense['description']);

    final category =
        _text(expense['category']);

    final notes =
        _text(expense['notes']);

    final amount =
        _number(expense['amount']);

    showDialog(
      context: context,
      barrierColor:
          Colors.black.withValues(
        alpha: 0.35,
      ),
      builder: (dialogContext) {
        return Dialog(
          backgroundColor:
              Colors.transparent,
          insetPadding:
              const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(
              maxWidth: 570,
            ),
            child: Material(
              color: Colors.white,
              borderRadius:
                  BorderRadius.circular(
                22,
              ),
              clipBehavior:
                  Clip.antiAlias,
              child: Column(
                mainAxisSize:
                    MainAxisSize.min,
                children: [
                  Container(
                    padding:
                        const EdgeInsets
                            .symmetric(
                      horizontal: 22,
                      vertical: 17,
                    ),
                    decoration:
                        const BoxDecoration(
                      color:
                          Color(0xFFFAFAFC),
                      border: Border(
                        bottom:
                            BorderSide(
                          color:
                              Color(
                            0xFFE9EAF0,
                          ),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration:
                              BoxDecoration(
                            color:
                                const Color(
                              0xFFFFEEEE,
                            ),
                            borderRadius:
                                BorderRadius
                                    .circular(
                              13,
                            ),
                          ),
                          child:
                              const Icon(
                            Icons
                                .receipt_long_outlined,
                            color:
                                Color(
                              0xFFD95864,
                            ),
                          ),
                        ),
                        const SizedBox(
                            width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,
                            children: [
                              const Text(
                                'Expense details',
                                style:
                                    TextStyle(
                                  fontSize:
                                      17,
                                  fontWeight:
                                      FontWeight
                                          .w800,
                                ),
                              ),
                              const SizedBox(
                                  height: 3),
                              Text(
                                _expenseReference(
                                  expense,
                                ),
                                style:
                                    const TextStyle(
                                  color:
                                      Color(
                                    0xFF858795,
                                  ),
                                  fontSize:
                                      11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            Navigator.pop(
                              dialogContext,
                            );
                          },
                          icon:
                              const Icon(
                            Icons
                                .close_rounded,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Flexible(
                    child:
                        SingleChildScrollView(
                      padding:
                          const EdgeInsets
                              .all(26),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                        children: [
                          Container(
                            width:
                                double.infinity,
                            padding:
                                const EdgeInsets
                                    .all(18),
                            decoration:
                                BoxDecoration(
                              gradient:
                                  const LinearGradient(
                                colors: [
                                  Color(
                                    0xFFFFF5F5,
                                  ),
                                  Color(
                                    0xFFFFFAFA,
                                  ),
                                ],
                              ),
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                16,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,
                              children: [
                                const Text(
                                  'AMOUNT',
                                  style:
                                      TextStyle(
                                    color:
                                        Color(
                                      0xFF999BA7,
                                    ),
                                    fontSize:
                                        10,
                                    fontWeight:
                                        FontWeight
                                            .w700,
                                    letterSpacing:
                                        0.8,
                                  ),
                                ),
                                const SizedBox(
                                    height: 6),
                                Text(
                                  _currency(
                                    amount,
                                  ),
                                  style:
                                      const TextStyle(
                                    color:
                                        Color(
                                      0xFFD14E57,
                                    ),
                                    fontSize:
                                        28,
                                    fontWeight:
                                        FontWeight
                                            .w900,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(
                              height: 20),

                          _detailItem(
                            icon: Icons
                                .description_outlined,
                            title:
                                'Description',
                            value: description
                                    .isEmpty
                                ? '—'
                                : description,
                          ),

                          const SizedBox(
                              height: 11),

                          _detailItem(
                            icon: Icons
                                .category_outlined,
                            title:
                                'Category',
                            value: category
                                    .isEmpty
                                ? 'Other'
                                : category,
                          ),

                          const SizedBox(
                              height: 11),

                          _detailItem(
                            icon: Icons
                                .calendar_today_outlined,
                            title: 'Date',
                            value:
                                _formatDate(
                              _expenseDateValue(
                                expense,
                              ),
                            ),
                          ),

                          if (notes
                              .isNotEmpty) ...[
                            const SizedBox(
                                height: 20),
                            const Text(
                              'Notes',
                              style:
                                  TextStyle(
                                color:
                                    Color(
                                  0xFF858795,
                                ),
                                fontSize: 11,
                                fontWeight:
                                    FontWeight
                                        .w700,
                              ),
                            ),
                            const SizedBox(
                                height: 7),
                            Container(
                              width: double
                                  .infinity,
                              padding:
                                  const EdgeInsets
                                      .all(15),
                              decoration:
                                  BoxDecoration(
                                color:
                                    const Color(
                                  0xFFF8F9FC,
                                ),
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  13,
                                ),
                              ),
                              child: Text(
                                notes,
                                style:
                                    const TextStyle(
                                  color:
                                      Color(
                                    0xFF5F6170,
                                  ),
                                  fontSize: 12,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  Container(
                    padding:
                        const EdgeInsets
                            .symmetric(
                      horizontal: 22,
                      vertical: 14,
                    ),
                    decoration:
                        const BoxDecoration(
                      color:
                          Color(0xFFFAFAFC),
                      border: Border(
                        top: BorderSide(
                          color:
                              Color(
                            0xFFE9EAF0,
                          ),
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment:
                          MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(
                              dialogContext,
                            );
                          },
                          child: const Text(
                            'Close',
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
      },
    );
  }

  Widget _detailItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:
            const Color(0xFFF8F9FC),
        borderRadius:
            BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color:
                  const Color(0xFFF0EFFF),
              borderRadius:
                  BorderRadius.circular(
                11,
              ),
            ),
            child: Icon(
              icon,
              size: 18,
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
                    color:
                        Color(0xFF9294A2),
                    fontSize: 10,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    color:
                        Color(0xFF353641),
                    fontSize: 13,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateExpensePlaceholder() {
    _showExpenseFormPlaceholder(
      title: 'Add expense',
      message:
          'The expense form is ready to be connected after confirming the finance expense POST endpoint.',
    );
  }

  void _showEditPlaceholder(
    dynamic expense,
  ) {
    _showExpenseFormPlaceholder(
      title: 'Edit expense',
      message:
          'The edit form will use the expense update endpoint from FinanceController.',
    );
  }

  void _showExpenseFormPlaceholder({
    required String title,
    required String message,
  }) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              20,
            ),
          ),
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(
              maxWidth: 470,
            ),
            child: Padding(
              padding:
                  const EdgeInsets.all(
                24,
              ),
              child: Column(
                mainAxisSize:
                    MainAxisSize.min,
                children: [
                  Container(
                    width: 55,
                    height: 55,
                    decoration:
                        BoxDecoration(
                      color:
                          const Color(
                        0xFFFFEEEE,
                      ),
                      borderRadius:
                          BorderRadius
                              .circular(
                        16,
                      ),
                    ),
                    child: const Icon(
                      Icons
                          .payments_outlined,
                      color:
                          Color(
                        0xFFD95864,
                      ),
                    ),
                  ),
                  const SizedBox(
                      height: 16),
                  Text(
                    title,
                    style:
                        const TextStyle(
                      fontSize: 19,
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),
                  const SizedBox(
                      height: 8),
                  Text(
                    message,
                    textAlign:
                        TextAlign.center,
                    style:
                        const TextStyle(
                      color:
                          Color(0xFF77798A),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(
                      height: 22),
                  FilledButton(
                    onPressed: () {
                      Navigator.pop(
                        dialogContext,
                      );
                    },
                    child:
                        const Text('Close'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoading() {
    return Container(
      height: 320,
      decoration: BoxDecoration(
        color:
            Theme.of(context).cardColor,
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

  Widget _buildEmpty() {
    final filtered =
        _search.isNotEmpty ||
            _categoryFilter !=
                'All categories';

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 70,
      ),
      decoration: BoxDecoration(
        color:
            Theme.of(context).cardColor,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color:
              const Color(0xFFE9EAF0),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color:
                  const Color(0xFFFFEEEE),
              borderRadius:
                  BorderRadius.circular(
                21,
              ),
            ),
            child: const Icon(
              Icons
                  .receipt_long_outlined,
              size: 31,
              color:
                  Color(0xFFD95864),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            filtered
                ? 'No expenses found'
                : 'No expenses yet',
            style: const TextStyle(
              fontSize: 18,
              fontWeight:
                  FontWeight.w800,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            filtered
                ? 'Try changing your search or category filter.'
                : 'Business expenses will appear here.',
            textAlign:
                TextAlign.center,
            style: const TextStyle(
              color:
                  Color(0xFF77798A),
              fontSize: 13,
            ),
          ),
          if (!filtered) ...[
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed:
                  _showCreateExpensePlaceholder,
              icon: const Icon(
                Icons.add_rounded,
                size: 18,
              ),
              label: const Text(
                'Add expense',
              ),
            ),
          ],
        ],
      ),
    );
  }

  dynamic _expenseDateValue(
    dynamic expense,
  ) {
    return expense['expenseDate'] ??
        expense['date'] ??
        expense['createdAt'];
  }

  DateTime? _expenseDate(
    dynamic expense,
  ) {
    return DateTime.tryParse(
      _expenseDateValue(expense)
              ?.toString() ??
          '',
    );
  }

  String _expenseReference(
    dynamic expense,
  ) {
    final reference =
        _text(
      expense['reference'],
    );

    if (reference.isNotEmpty) {
      return reference;
    }

    final id = expense['id'];

    if (id != null) {
      return 'EXP-${id.toString().padLeft(5, '0')}';
    }

    return 'Expense';
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
    final date =
        DateTime.tryParse(
      value?.toString() ?? '',
    );

    if (date == null) {
      return '—';
    }

    return '${_two(date.day)}.${_two(date.month)}.${date.year}';
  }

  String _two(int value) {
    return value
        .toString()
        .padLeft(2, '0');
  }

  String _monthName(int month) {
    const months = [
      '',
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

    if (month < 1 ||
        month >= months.length) {
      return '';
    }

    return months[month];
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

const TextStyle _expenseHeaderStyle =
    TextStyle(
  color: Color(0xFF858795),
  fontSize: 10,
  fontWeight: FontWeight.w700,
  letterSpacing: 0.6,
);