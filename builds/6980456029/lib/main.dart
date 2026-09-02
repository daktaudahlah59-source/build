import 'package:flutter/material.dart';
import 'login_page.dart';
import 'dashboard_page.dart';
import 'home_page.dart';
import 'seller_page.dart';
import 'admin_page.dart';
import 'owner_page.dart';
import 'landing.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ATOMIC',
      theme: ThemeData(
        brightness: Brightness.dark,
        fontFamily: 'ShareTechMono',
        scaffoldBackgroundColor: const Color(0xFF050510), // bgDark (Ungu Gelap)
        primaryColor: const Color(0xFFBB86FC), // accentPurple (Ungu Terang)
        cardColor: const Color(0xFF1A1025), // darkPurple (Kartu)
        dividerColor: const Color(0xFF381A4A), // softPurple (Pembatas)
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFBB86FC), // accentPurple
          secondary: Color(0xFFAB47BC), // Ungu Sekunder dari Gradient
          surface: Color(0xFF1A1025), // darkPurple
          background: Color(0xFF050510), // bgDark
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: Colors.white,
        ),
      ),
      initialRoute: '/',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/':
            return MaterialPageRoute(builder: (_) => const LandingPage());
          case '/login':
            return MaterialPageRoute(builder: (_) => const LoginPage());
          case '/dashboard':
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (_) => DashboardPage(
                username: args['username'],
                password: args['password'],
                role: args['role'],
                sessionKey: args['key'],
                expiredDate: args['expiredDate'],
                listBug: List<Map<String, dynamic>>.from(args['listBug'] ?? []),
                listDoos: List<Map<String, dynamic>>.from(args['listDoos'] ?? []),
                news: List<Map<String, dynamic>>.from(args['news'] ?? []),
              ),
            );

          case '/home':
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (_) => HomePage(
                username: args['username'],
                password: args['password'],
                listBug: List<Map<String, dynamic>>.from(args['listBug'] ?? []),
                role: args['role'],
                expiredDate: args['expiredDate'],
                sessionKey: args['sessionKey'],
              ),
            );

          case '/seller':
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (_) => SellerPage(
                keyToken: args['keyToken'],
              ),
            );

          case '/admin':
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (_) => AdminPage(
                sessionKey: args['sessionKey'],
              ),
            );

          case '/owner':
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (_) => OwnerPage(
                sessionKey: args['sessionKey'],
                username: args['username'],
              ),
            );

          default:
            return MaterialPageRoute(
              builder: (_) => Scaffold(
                backgroundColor: const Color(0xFF050510),
                body: Center(
                  child: Text(
                    "404 - Not Found",
                    style: TextStyle(color: Color(0xFFBB86FC)),
                  ),
                ),
              ),
            );
        }
      },
    );
  }
}