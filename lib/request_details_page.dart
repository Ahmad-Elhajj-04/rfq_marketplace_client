import 'package:flutter/material.dart';
import 'quotations_page.dart';

class RequestDetailsPage extends StatelessWidget {
  final Map<String, dynamic> request;
  const RequestDetailsPage({super.key, required this.request});

  @override
  Widget build(BuildContext context) {
    final id = request["id"];
    final title = request["title"]?.toString() ?? "Request";

    return Scaffold(
      appBar: AppBar(title: Text("Request #$id")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text("Status: ${request["status"]}"),
            const SizedBox(height: 8),
            Text("City: ${request["delivery_city"]}"),
            const SizedBox(height: 8),
            Text("Quantity: ${request["quantity"]} ${request["unit"]}"),
            const SizedBox(height: 8),
            Text("Budget: ${request["budget_min"]} - ${request["budget_max"]}"),
            const SizedBox(height: 16),

            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => QuotationsPage(requestId: id),
                    ),
                  );
                },
                child: const Text("View Quotations"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}