import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/api_client.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});
  State<NotificationsPage> createState() => _S();
}

class _S extends State<NotificationsPage> {
  List data = [];
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    context
        .read<ApiClient>()
        .get('/notifications')
        .then((x) => setState(() => data = x));
  }

  @override
  Widget build(BuildContext c) => SafeArea(
          child: ListView(padding: const EdgeInsets.all(20), children: [
        Text('Notifications',
            style: Theme.of(c)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        if (data.isEmpty)
          const Card(
              child: Padding(
                  padding: EdgeInsets.all(30),
                  child: Center(child: Text('Nothing here yet')))),
        ...data.map((x) => Card(
            child: ListTile(
                leading:
                    const CircleAvatar(child: Icon(Icons.notifications_none)),
                title:
                    Text(x['reference'] ?? x['number'] ?? x['title'] ?? 'Item'),
                subtitle: Text(x['service'] ??
                    x['message'] ??
                    x['issuedAt']?.toString() ??
                    ''),
                trailing: x['status'] != null
                    ? Chip(label: Text(x['status'].toString()))
                    : null)))
      ]));
}
