import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/api_client.dart';
import 'core/auth_provider.dart';
import 'core/theme.dart';
import 'pages/login_page.dart';
import 'pages/business_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final api = ApiClient();
  final auth = AuthProvider(api);
  await auth.restore();
  runApp(MultiProvider(providers: [
    Provider.value(value: api),
    ChangeNotifierProvider.value(value: auth)
  ], child: const App()));
}

class App extends StatelessWidget {
  const App({super.key});
  @override
  Widget build(BuildContext c) => MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NexaBook Business',
      theme: AppTheme.light,
      home: Consumer<AuthProvider>(
          builder: (_, a, __) =>
              a.loggedIn ? const BusinessShell() : const LoginPage()));
}
