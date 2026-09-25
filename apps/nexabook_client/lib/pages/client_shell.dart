import 'package:flutter/material.dart';
import 'home_page.dart';
import 'appointments_page.dart';
import 'invoices_page.dart';
import 'notifications_page.dart';
import 'profile_page.dart';

class ClientShell extends StatefulWidget {
  const ClientShell({super.key});
  State<ClientShell> createState() => _S();
}

class _S extends State<ClientShell> {

  int i = 0;
  final pages = const [
    HomePage(),
    AppointmentsPage(),
    InvoicesPage(),
    NotificationsPage(),
    ProfilePage()
  ];

  @override
  Widget build(BuildContext c) => Scaffold(
      body: pages[i],
      bottomNavigationBar: NavigationBar(
          selectedIndex: i,
          onDestinationSelected: (v) => setState(() => i = v),
          destinations: const [
            NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'Home'),
            NavigationDestination(
                icon: Icon(Icons.calendar_month_outlined), label: 'Bookings'),
            NavigationDestination(
                icon: Icon(Icons.receipt_long_outlined), label: 'Invoices'),
            NavigationDestination(
                icon: Icon(Icons.notifications_none), label: 'Alerts'),
            NavigationDestination(
                icon: Icon(Icons.person_outline), label: 'Profile')
          ]
        )
    );
}
