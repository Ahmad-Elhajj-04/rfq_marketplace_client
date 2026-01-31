import 'package:flutter/material.dart';

import 'landing_page.dart';
import 'login_page.dart';
import 'register_page.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: "/",
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case "/":
            return MaterialPageRoute(builder: (_) => const LandingPage());

          case "/login":
            final expectedRole = settings.arguments as String?;
            return MaterialPageRoute(
              builder: (_) => LoginPage(expectedRole: expectedRole),
            );

          case "/register":
            final role = settings.arguments as String? ?? "user";
            return MaterialPageRoute(
              builder: (_) => RegisterPage(role: role),
            );

          default:
            return MaterialPageRoute(
              builder: (_) => const Scaffold(
                body: Center(child: Text("Page not found")),
              ),
            );
        }
      },
    );
  }
}