import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/auth_provider.dart';

import 'dashboard_page.dart';
import 'appointments_page.dart';
import 'customers_page.dart';
import 'staff_page.dart';
import 'services_page.dart';
import 'payments_page.dart';
import 'invoices_page.dart';
import 'expenses_page.dart';
import 'reports_page.dart';
import 'settings_page.dart';

class BusinessShell extends StatefulWidget {
  const BusinessShell({
    super.key,
  });

  @override
  State<BusinessShell> createState() => _BusinessShellState();
}

class _BusinessShellState extends State<BusinessShell> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    DashboardPage(),
    AppointmentsPage(),
    CustomersPage(),
    StaffPage(),
    ServicesPage(),
    PaymentsPage(),
    InvoicesPage(),
    ExpensesPage(),
    ReportsPage(),
    SettingsPage(),
  ];

  final List<String> _labels = const [
    'Dashboard',
    'Appointments',
    'Customers',
    'Team',
    'Services',
    'Payments & Deposits',
    'Invoices',
    'Expenses',
    'Reports',
    'Settings',
  ];

  final List<IconData> _icons = const [
    Icons.dashboard_outlined,
    Icons.calendar_month_outlined,
    Icons.people_outline,
    Icons.badge_outlined,
    Icons.design_services_outlined,
    Icons.payments_outlined,
    Icons.receipt_long_outlined,
    Icons.account_balance_wallet_outlined,
    Icons.bar_chart_outlined,
    Icons.settings_outlined,
  ];

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 900;

    if (!isWide) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            _labels[_selectedIndex],
          ),
        ),
        drawer: Drawer(
          child: _buildNavigation(),
        ),
        body: _pages[_selectedIndex],
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      body: Row(
        children: [
          SizedBox(
            width: 250,
            child: Material(
              color: Colors.white,
              child: _buildNavigation(),
            ),
          ),
          const VerticalDivider(
            width: 1,
            thickness: 1,
            color: Color(0xFFE9EAF0),
          ),
          Expanded(
            child: _pages[_selectedIndex],
          ),
        ],
      ),
    );
  }

  Widget _buildNavigation() {
    return SafeArea(
      child: Column(
        children: [
          _buildLogo(),

          const SizedBox(height: 6),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
              ),
              itemCount: _labels.length,
              itemBuilder: (context, index) {
                return _buildNavigationItem(
                  index,
                );
              },
            ),
          ),

          _buildBottomSection(),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(
        22,
        22,
        22,
        18,
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Color(0xFF6C63FF),
            foregroundColor: Colors.white,
            child: Icon(
              Icons.calendar_month_rounded,
              size: 20,
            ),
          ),
          SizedBox(width: 12),
          Text(
            'NexaBook',
            style: TextStyle(
              color: Color(0xFF292A35),
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationItem(
    int itemIndex,
  ) {
    final selected = _selectedIndex == itemIndex;

    return Padding(
      padding: const EdgeInsets.only(
        bottom: 4,
      ),
      child: Material(
        color: selected
            ? const Color(0xFFF0EFFF)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            setState(() {
              _selectedIndex = itemIndex;
            });

            _closeDrawerIfNeeded();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            child: Row(
              children: [
                Icon(
                  _icons[itemIndex],
                  size: 21,
                  color: selected
                      ? const Color(0xFF6C63FF)
                      : const Color(0xFF777986),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Text(
                    _labels[itemIndex],
                    style: TextStyle(
                      color: selected
                          ? const Color(0xFF5F57E8)
                          : const Color(0xFF4C4E5A),
                      fontSize: 13,
                      fontWeight: selected
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        12,
        8,
        12,
        16,
      ),
      child: Column(
        children: [
          const Divider(
            height: 1,
            color: Color(0xFFE9EAF0),
          ),

          const SizedBox(height: 10),

          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: _confirmLogout,
              child: const Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.logout_rounded,
                      size: 21,
                      color: Color(0xFFD95864),
                    ),
                    SizedBox(width: 13),
                    Expanded(
                      child: Text(
                        'Sign out',
                        style: TextStyle(
                          color: Color(0xFFD95864),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _closeDrawerIfNeeded() {
    final scaffold = Scaffold.maybeOf(context);

    if (scaffold?.isDrawerOpen ?? false) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.logout_rounded,
                color: Color(0xFFD95864),
              ),
              SizedBox(width: 10),
              Text(
                'Sign out',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          content: const Text(
            'Are you sure you want to sign out of your account?',
            style: TextStyle(
              color: Color(0xFF6F7180),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text(
                'Cancel',
              ),
            ),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              icon: const Icon(
                Icons.logout_rounded,
                size: 17,
              ),
              label: const Text(
                'Sign out',
              ),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFD95864),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    await context.read<AuthProvider>().logout();
  }
}