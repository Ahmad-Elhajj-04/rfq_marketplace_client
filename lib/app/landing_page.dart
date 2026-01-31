import 'package:flutter/material.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final _search = TextEditingController();

  final List<_CardItem> _cards = const [
    _CardItem("Iron Supply", "Materials", "assets/images/iron.JPG"),
    _CardItem("Cement Supply", "Materials", "assets/images/cement.JPG"),
    _CardItem("Electrical Services", "Service", "assets/images/electrical.JPG"),
    _CardItem("Plumbing Services", "Service", "assets/images/plumbing.JPG"),
    _CardItem("Logistics Delivery", "Service", "assets/images/logistics.JPG"),
  ];

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

    int columns = 2;
    if (w >= 750) columns = 3;
    if (w >= 1050) columns = 4;
    if (w >= 1350) columns = 5;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(
              controller: _search,
              onExplore: () {},
              onSearch: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Search: ${_search.text.trim()} (next feature)")),
                );
              },
              onLoginUser: () => Navigator.pushNamed(context, "/login", arguments: "user"),
              onLoginCompany: () => Navigator.pushNamed(context, "/login", arguments: "company"),
              onSignup: () => Navigator.pushNamed(context, "/register", arguments: "user"),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      height: w > 900 ? 290 : 220,
                      child: _HeroSection(),
                    ),
                    const SizedBox(height: 18),

                    const Text(
                      "Explore categories",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),

                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _cards.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.92,
                      ),
                      itemBuilder: (context, i) {
                        final c = _cards[i];
                        return _ImageCard(
                          title: c.title,
                          subtitle: c.subtitle,
                          assetPath: c.assetPath,
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Open: ${c.title} (next feature)")),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------- UI Components ----------------

class _TopBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSearch;
  final VoidCallback onExplore;
  final VoidCallback onLoginUser;
  final VoidCallback onLoginCompany;
  final VoidCallback onSignup;

  const _TopBar({
    required this.controller,
    required this.onSearch,
    required this.onExplore,
    required this.onLoginUser,
    required this.onLoginCompany,
    required this.onSignup,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.black.withOpacity(0.08))),
      ),
      child: Row(
        children: [
          const Icon(Icons.storefront, size: 22),
          const SizedBox(width: 8),
          const Text("RFQ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(width: 12),

          TextButton(
            onPressed: onExplore,
            child: const Text("Explore"),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: TextField(
              controller: controller,
              onSubmitted: (_) => onSearch(),
              decoration: InputDecoration(
                hintText: "Search for materials or services",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.black.withOpacity(0.04),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(999),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // ✅ Top-right buttons only
          if (w > 700) ...[
            _PillButton(
              text: "Login as User",
              style: _PillStyle.light,
              onPressed: onLoginUser,
            ),
            const SizedBox(width: 8),
            _PillButton(
              text: "Login as Company",
              style: _PillStyle.dark,
              onPressed: onLoginCompany,
            ),
            const SizedBox(width: 8),
            _PillButton(
              text: "Sign up",
              style: _PillStyle.primary,
              onPressed: onSignup,
            ),
          ] else ...[
            // Small screens: keep just two clean buttons
            _PillButton(text: "Login", style: _PillStyle.light, onPressed: onLoginUser),
            const SizedBox(width: 8),
            _PillButton(text: "Sign up", style: _PillStyle.primary, onPressed: onSignup),
          ],
        ],
      ),
    );
  }
}

enum _PillStyle { light, dark, primary }

class _PillButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final _PillStyle style;

  const _PillButton({
    required this.text,
    required this.onPressed,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    switch (style) {
      case _PillStyle.primary:
        return ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE53935), // red
            foregroundColor: Colors.white,
            shape: const StadiumBorder(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            elevation: 0,
          ),
          child: Text(text),
        );

      case _PillStyle.dark:
        return OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.black87,
            side: BorderSide(color: Colors.black.withOpacity(0.35)),
            shape: const StadiumBorder(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          child: Text(text),
        );

      case _PillStyle.light:
      default:
        return OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.black87,
            side: BorderSide(color: Colors.black.withOpacity(0.18)),
            shape: const StadiumBorder(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          child: Text(text),
        );
    }
  }
}

class _HeroSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            "assets/images/hero.JPG",
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: Colors.black12,
              child: const Center(child: Icon(Icons.image, size: 64)),
            ),
          ),
          Container(color: Colors.black.withOpacity(0.45)),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Spacer(),
                Text(
                  "Request. Quote. Deliver.",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "A professional RFQ marketplace connecting users and companies.\nGet quotations and choose the best offer — instantly.",
                  style: TextStyle(color: Colors.white70, height: 1.3),
                ),
                Spacer(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ImageCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String assetPath;
  final VoidCallback onTap;

  const _ImageCard({
    required this.title,
    required this.subtitle,
    required this.assetPath,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(16),
      color: Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black12),
            borderRadius: BorderRadius.circular(16),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AspectRatio(
                  aspectRatio: 4 / 3,
                  child: Image.asset(
                    assetPath,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.black12,
                      child: const Center(child: Icon(Icons.image)),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(subtitle, style: const TextStyle(color: Colors.black54, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CardItem {
  final String title;
  final String subtitle;
  final String assetPath;
  const _CardItem(this.title, this.subtitle, this.assetPath);
}