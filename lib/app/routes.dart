import 'package:flutter/material.dart';

import 'package:rfq_marketplace_flutter/app/landing_page.dart';
import 'package:rfq_marketplace_flutter/features/auth/presentation/login_page.dart';
import 'package:rfq_marketplace_flutter/features/auth/presentation/register_page.dart';
import 'package:rfq_marketplace_flutter/requests/presentation/requests_page.dart';
import 'package:rfq_marketplace_flutter/requests/presentation/company_requests_page.dart';
import 'package:rfq_marketplace_flutter/notifications/presentation/notifications_page.dart';

class AppRoutes {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
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

      case "/requests":
        return MaterialPageRoute(builder: (_) => const RequestsPage());

      case "/company-requests":
        return MaterialPageRoute(builder: (_) => const CompanyRequestsPage());

      case "/notifications":
        return MaterialPageRoute(builder: (_) => const NotificationsPage());

      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text("Page not found")),
          ),
        );
    }
  }
}