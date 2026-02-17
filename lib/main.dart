import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/jules_provider.dart';
import 'screens/dashboard_screen.dart';
import 'screens/setup_screen.dart';
import 'services/api_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const JulesApp());
}

class JulesApp extends StatelessWidget {
  const JulesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..loadApiKey()),
        ChangeNotifierProxyProvider<AuthProvider, JulesProvider>(
          create: (_) => JulesProvider(),
          update: (_, auth, jules) {
            final provider = jules ?? JulesProvider();
            if (auth.isAuthenticated) {
              provider.updateApiService(ApiService(auth.apiKey!));
            } else {
              provider.updateApiService(null);
            }
            return provider;
          },
        ),
      ],
      child: MaterialApp(
        title: 'Jules Agent Manager',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (!auth.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (auth.isAuthenticated) {
      return const DashboardScreen();
    } else {
      return const SetupScreen();
    }
  }
}
