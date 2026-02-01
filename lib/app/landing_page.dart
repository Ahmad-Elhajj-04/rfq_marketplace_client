import 'package:flutter/material.dart';

import 'package:rfq_marketplace_flutter/core/network/api_client.dart';
import 'package:rfq_marketplace_flutter/core/storage/token_store.dart';
import 'package:rfq_marketplace_flutter/core/ui/profile_avatar.dart';
import 'package:rfq_marketplace_flutter/shared/session.dart';

import 'package:rfq_marketplace_flutter/requests/presentation/request_create_page.dart';
import 'package:rfq_marketplace_flutter/requests/presentation/explore_requests_page.dart';
import 'package:rfq_marketplace_flutter/subscriptions/presentation/subscriptions_page.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final _api = ApiClient();
  final _search = TextEditingController();

  bool _checkingAuth = true;

  final List<_CardItem> _cards = const [
    _CardItem("Iron Supply", "Materials", "assets/images/iron.JPG", 1),
    _CardItem("Cement Supply", "Materials", "assets/images/cement.JPG", 2),
    _CardItem("Electrical Services", "Service", "assets/images/electrical.JPG", 3),
    _CardItem("Plumbing Services", "Service", "assets/images/plumbing.JPG", 4),
    _CardItem("Logistics Delivery", "Service", "assets/images/logistics.JPG", 5),
  ];

  @override
  void initState() {
    super.initState();
    _bootstrapSession();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _bootstrapSession() async {
    setState(() => _checkingAuth = true);

    final token = await TokenStore.get();
    if (token == null) {
      Session.clear();
      setState(() => _checkingAuth = false);
      return;
    }

    try {
      final res = await _api.get("/v1/auth/me");
      final user = res["user"] as Map<String, dynamic>;
      Session.userId = user["id"] as int;
      Session.role = (user["role"] ?? "").toString();
      Session.name = (user["name"] ?? "").toString();
    } catch (_) {
      await TokenStore.clear();
      Session.clear();
    }

    if (mounted) setState(() => _checkingAuth = false);
  }

  Future<void> _logout() async {
    await TokenStore.clear();
    Session.clear();
    if (mounted) setState(() {});
  }

  void _openProfileMenu() async {
    final selected = await showMenu<String>(
      context: context,
      position: const RelativeRect.fromLTRB(1000, 60, 16, 0),
      items: [
        PopupMenuItem<String>(value: "role", child: Text("Role: ${Session.role ?? "-"}")),
        const PopupMenuItem<String>(value: "logout", child: Text("Logout")),
      ],
    );

    if (selected == "logout") _logout();
  }

  void _openUserRequests() => Navigator.pushNamed(context, "/requests");
  void _openCompanyBrowse() => Navigator.pushNamed(context, "/company-requests");

  Future<void> _openCreateRequest() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const RequestCreatePage()));
  }

  Future<void> _openSubscriptions() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const SubscriptionsPage()));
  }

  void _openCategory(_CardItem c) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ExploreRequestsPage(
          categoryId: c.categoryId,
          title: c.title,
          subtitle: c.subtitle,
          assetPath: c.assetPath,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

    int columns = 2;
    if (w >= 750) columns = 3;
    if (w >= 1050) columns = 4;
    if (w >= 1350) columns = 5;

    final isLoggedIn = Session.isLoggedIn;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(
              controller: _search,
              isLoading: _checkingAuth,
              isLoggedIn: isLoggedIn,
              displayName: (Session.name ?? "User").trim(),
              onSearch: () {},
              onLoginUser: () => Navigator.pushNamed(context, "/login", arguments: "user").then((_) => _bootstrapSession()),
              onLoginCompany: () => Navigator.pushNamed(context, "/login", arguments: "company").then((_) => _bootstrapSession()),
              onSignup: () => Navigator.pushNamed(context, "/register", arguments: "user").then((_) => _bootstrapSession()),
              onAvatarTap: _openProfileMenu,
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: w > 900 ? 290 : 220, child: _HeroSection()),
                    const SizedBox(height: 14),

                    if (isLoggedIn) ...[
                      _LandingActions(
                        role: Session.role!,
                        onUserRequests: _openUserRequests,
                        onCreateRequest: _openCreateRequest,
                        onCompanyBrowse: _openCompanyBrowse,
                        onSubscriptions: _openSubscriptions, // ✅ new
                      ),
                      const SizedBox(height: 18),
                    ],

                    const Text("Explore categories", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                          onTap: () => _openCategory(c),
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

// ---------------- Top Bar ----------------

class _TopBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isLoading;
  final bool isLoggedIn;
  final String displayName;

  final VoidCallback onSearch;
  final VoidCallback onLoginUser;
  final VoidCallback onLoginCompany;
  final VoidCallback onSignup;
  final VoidCallback onAvatarTap;

  const _TopBar({
    required this.controller,
    required this.isLoading,
    required this.isLoggedIn,
    required this.displayName,
    required this.onSearch,
    required this.onLoginUser,
    required this.onLoginCompany,
    required this.onSignup,
    required this.onAvatarTap,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.black.withOpacity(0.08)))),
      child: Row(
        children: [
          const Icon(Icons.storefront, size: 22),
          const SizedBox(width: 8),
          const Text("RFQ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(width: 12),

          Expanded(
            child: TextField(
              controller: controller,
              onSubmitted: (_) => onSearch(),
              decoration: InputDecoration(
                hintText: "Search for materials or services",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.black.withOpacity(0.04),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(999), borderSide: BorderSide.none),
              ),
            ),
          ),
          const SizedBox(width: 12),

          if (isLoading)
            const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)),

          if (!isLoading && !isLoggedIn && w > 700) ...[
            OutlinedButton(onPressed: onLoginUser, child: const Text("Login as User")),
            const SizedBox(width: 8),
            OutlinedButton(onPressed: onLoginCompany, child: const Text("Login as Company")),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: onSignup,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE53935)),
              child: const Text("Sign up"),
            ),
          ],

          if (!isLoading && isLoggedIn) ...[
            InkWell(
              onTap: onAvatarTap,
              borderRadius: BorderRadius.circular(999),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: ProfileAvatar(name: displayName),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------- Hero ----------------

class _HeroSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset("assets/images/hero.JPG", fit: BoxFit.cover),
          Container(color: Colors.black.withOpacity(0.45)),
          const Padding(
            padding: EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Spacer(),
                Text("Request. Quote. Deliver.",
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white)),
                SizedBox(height: 8),
                Text("Click a category to browse real requests.",
                    style: TextStyle(color: Colors.white70, height: 1.3)),
                Spacer(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------- Logged-in actions ----------------

class _LandingActions extends StatelessWidget {
  final String role;
  final VoidCallback onUserRequests;
  final Future<void> Function() onCreateRequest;
  final VoidCallback onCompanyBrowse;
  final Future<void> Function() onSubscriptions;

  const _LandingActions({
    required this.role,
    required this.onUserRequests,
    required this.onCreateRequest,
    required this.onCompanyBrowse,
    required this.onSubscriptions,
  });

  @override
  Widget build(BuildContext context) {
    if (role == "company") {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: onCompanyBrowse,
              child: const Text("Browse Requests"),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: OutlinedButton(
              onPressed: () => onSubscriptions(),
              child: const Text("Subscriptions"),
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: OutlinedButton(onPressed: onUserRequests, child: const Text("My Requests"))),
        const SizedBox(width: 10),
        Expanded(child: ElevatedButton(onPressed: () => onCreateRequest(), child: const Text("Create Request"))),
      ],
    );
  }
}

// ---------------- Cards ----------------

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
          decoration: BoxDecoration(border: Border.all(color: Colors.black12), borderRadius: BorderRadius.circular(16)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AspectRatio(
                  aspectRatio: 4 / 3,
                  child: Image.asset(assetPath, fit: BoxFit.cover),
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
  final int categoryId;
  const _CardItem(this.title, this.subtitle, this.assetPath, this.categoryId);
}