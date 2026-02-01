import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rfq_marketplace_flutter/app/routes.dart';
import 'package:rfq_marketplace_flutter/core/ui/app_messenger.dart';

class RFQApp extends StatelessWidget {
  const RFQApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: "RFQ Marketplace",
      scaffoldMessengerKey: messengerKey,
      initialRoute: "/",
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}