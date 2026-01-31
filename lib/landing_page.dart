import 'package:flutter/material.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),

                  // App Title
                  const Text(
                    "RFQ Marketplace",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 10),

                  // Subtitle
                  const Text(
                    "Post requests, receive quotations, and choose the best offer — in real time.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, height: 1.3),
                  ),

                  const SizedBox(height: 26),

                  // User button
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        // Next branch: route to login/register user
                        // Navigator.pushNamed(context, "/login?role=user");
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Next: User Login/Register")),
                        );
                      },
                      child: const Text("Continue as User"),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Company button
                  SizedBox(
                    height: 50,
                    child: OutlinedButton(
                      onPressed: () {
                        // Next branch: route to login/register company
                        // Navigator.pushNamed(context, "/login?role=company");
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Next: Company Login/Register")),
                        );
                      },
                      child: const Text("Continue as Company"),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Guest/browse option (optional)
                  TextButton(
                    onPressed: () {
                      // Next branch: browse offers/requests as guest (optional)
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Next: Guest Browse (optional)")),
                      );
                    },
                    child: const Text("Browse as Guest"),
                  ),

                  const SizedBox(height: 18),

                  // Footer hint
                  const Text(
                    "Tip: Companies subscribe to categories to get instant RFQ alerts.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}