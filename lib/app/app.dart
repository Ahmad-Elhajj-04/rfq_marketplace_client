import 'package:flutter/material.dart';

import 'routes.dart';

class RFQApp extends StatelessWidget {
  const RFQApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: "/",
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}