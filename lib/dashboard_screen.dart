import 'dart:async';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fitness_app/level_selection_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'app_theme.dart';

import 'supplement_store_screen.dart';
import 'supplement_models.dart';
import 'meal_plan_screen.dart';
import 'consultation_screen.dart';
import 'about_screen.dart';
import 'profile_screen.dart';
import 'my_orders_screen.dart';
import 'auth_screen.dart' show GuestManager, AuthFlowHandler;
import 'guest_preview_screen.dart';

// ─── GLOBAL CART STATE ──────────────────────────────────────────────────────
class CartManager {
  static final CartManager _instance = CartManager._internal();
  factory CartManager() => _instance;
  CartManager._internal();

  final List<CartItem> items = [];
  final List<VoidCallback> _listeners = [];

  void addListener(VoidCallback l) => _listeners.add(l);
  void removeListener(VoidCallback l) => _listeners.remove(l);
  void _notify() {
    for (final l in _listeners) {
      l();
    }
  }

  void addItem(CartItem item) {
    final idx = items.indexWhere((i) => i.id == item.id);
    if (idx >= 0) {
      items[idx] = CartItem(
        id: item.id,
        name: item.name,
        price: item.price,
        quantity: items[idx].quantity + 1,
        icon: item.icon,
        imageUrl: items[idx].imageUrl.isNotEmpty
            ? items[idx].imageUrl
            : item.imageUrl,
      );
    } else {
      items.add(item);
    }
    _notify();
  }

  void removeItem(String id) {
    items.removeWhere((i) => i.id == id);
    _notify();
  }

  void updateQuantity(String id, int qty) {
    final idx = items.indexWhere((i) => i.id == id);
    if (idx >= 0) {
      if (qty <= 0) {
        items.removeAt(idx);
      } else {
        items[idx] = CartItem(
          id: items[idx].id,
          name: items[idx].name,
          price: items[idx].price,
          quantity: qty,
          icon: items[idx].icon,
          imageUrl: items[idx].imageUrl, // preserve imageUrl
        );
      }
      _notify();
    }
  }

  double get total => items.fold(0, (s, i) => s + i.price * i.quantity);
  int get count => items.fold(0, (s, i) => s + i.quantity);
}

class CartItem {
  final String id, name;
  final double price;
  final int quantity;
  final IconData icon;
  final String imageUrl;
  const CartItem({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
    required this.icon,
    this.imageUrl = '',
  });
}

// ─── DASHBOARD SHELL ────────────────────────────────────────────────────────
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _tab = 0;
  int _cartCount = 0;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    CartManager().addListener(_onCart);
    _checkAdmin();
  }

  Future<void> _checkAdmin() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    // Check admins collection by email
    final snap = await FirebaseFirestore.instance
        .collection('admins')
        .where('email', isEqualTo: user.email)
        .limit(1)
        .get();
    if (mounted) {
      setState(() => _isAdmin = snap.docs.isNotEmpty);
    }
  }

  @override
  void dispose() {
    CartManager().removeListener(_onCart);
    super.dispose();
  }

  void _onCart() {
    if (mounted) setState(() => _cartCount = CartManager().count);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            IndexedStack(
              index: _tab,
              children: [
                _HomeTab(onNavToCart: () => setState(() => _tab = 2)),
                const AboutScreen(),
                const MyOrdersScreen(),
                const ProfileSection(),
                if (_isAdmin) const AdminBookingsPanel(),
              ],
            ),
            _glassNav(),
          ],
        ),
      ),
    );
  }

  // ── Glassy / frosted bottom nav bar ─────────────────────────────────────
  Widget _glassNav() => Positioned(
    bottom: 20,
    left: 20,
    right: 20,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(40),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          height: 72,
          decoration: BoxDecoration(
            color: AppTheme.surface.withValues(alpha: 0.75),
            borderRadius: BorderRadius.circular(40),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.55),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withValues(alpha: 0.10),
                blurRadius: 24,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _ni(0, Icons.home_rounded, "Home"),
              _ni(1, Icons.info_outline_rounded, "About"),
              _ni(2, Icons.receipt_long_outlined, "Orders"),
              _ni(3, Icons.person_outline_rounded, "Profile"),
              if (_isAdmin) _ni(4, Icons.admin_panel_settings_rounded, "Admin"),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _ni(int index, IconData icon, String label) {
    final sel = _tab == index;
    // Tabs 2 (Orders) and 3 (Profile) require auth
    final needsAuth = index == 2 || index == 3;
    return GestureDetector(
      onTap: () {
        if (needsAuth && !GuestManager().requireAuth(context)) return;
        setState(() => _tab = index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: sel
              ? AppTheme.primary.withValues(alpha: 0.13)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: sel ? AppTheme.primary : AppTheme.muted,
              size: sel ? 26 : 24,
            ),
            const SizedBox(height: 2),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 220),
              style: TextStyle(
                fontSize: sel ? 10 : 0,
                color: sel ? AppTheme.primary : Colors.transparent,
                fontWeight: FontWeight.w600,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }

  Widget _nb(int index, IconData icon, String label, int count) {
    final sel = _tab == index;
    return GestureDetector(
      onTap: () {
        if (!GuestManager().requireAuth(context)) return;
        setState(() => _tab = index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: sel
              ? AppTheme.primary.withValues(alpha: 0.13)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  icon,
                  color: sel ? AppTheme.primary : AppTheme.muted,
                  size: sel ? 26 : 24,
                ),
                if (count > 0)
                  Positioned(
                    top: -4,
                    right: -6,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: const BoxDecoration(
                        color: AppTheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          count > 9 ? "9+" : "$count",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 220),
              style: TextStyle(
                fontSize: sel ? 10 : 0,
                color: sel ? AppTheme.primary : Colors.transparent,
                fontWeight: FontWeight.w600,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── HOME TAB ───────────────────────────────────────────────────────────────
class _HomeTab extends StatefulWidget {
  final VoidCallback onNavToCart;
  const _HomeTab({required this.onNavToCart});
  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  int _bannerIdx = 0;
  late final PageController _bannerCtrl;
  Timer? _timer;

  // Slides 0-3 are static; slide 4 (deals) added dynamically when Firestore has deals
  static const _staticBanners = [
    {
      "tag": "LIMITED OFFER",
      "title": "20% Off\nFresh Plans",
      "sub": "Use code FIT20 at checkout",
      "btn": "Shop Now",
      "icon": Icons.local_fire_department_rounded,
      "action": "supplements",
    },
    {
      "tag": "MEAL PLANS",
      "title": "Customize\nYour Meal Plan",
      "sub": "Tailored nutrition for your goals",
      "btn": "Customize",
      "icon": Icons.restaurant_menu_rounded,
      "action": "meal",
    },
    {
      "tag": "BOOK NOW",
      "title": "1-on-1\nConsultation",
      "sub": "Certified personal trainers",
      "btn": "Reserve",
      "icon": Icons.video_call_rounded,
      "action": "consultation",
    },
  ];

  static const _allItems = [
    {
      "title": "Training Plan",
      "sub": "By Muscle Group",
      "icon": Icons.fitness_center_rounded,
      "idx": 0,
    },
    {
      "title": "Supplements",
      "sub": "Elite Store",
      "icon": Icons.science_rounded,
      "idx": 1,
    },
    {
      "title": "Meal Plan",
      "sub": "Custom Diet",
      "icon": Icons.restaurant_menu_rounded,
      "idx": 2,
    },
    {
      "title": "Consultation",
      "sub": "Book a Session",
      "icon": Icons.video_call_rounded,
      "idx": 3,
    },
  ];

  List<Map<String, dynamic>> get _filtered => _query.isEmpty
      ? List.from(_allItems)
      : _allItems
            .where(
              (i) =>
                  i['title']!.toString().toLowerCase().contains(
                    _query.toLowerCase(),
                  ) ||
                  i['sub']!.toString().toLowerCase().contains(
                    _query.toLowerCase(),
                  ),
            )
            .toList();

  @override
  void initState() {
    super.initState();
    // Start in the middle of the loop range so swiping backwards also works
    _bannerCtrl = PageController(initialPage: 500);
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      _bannerCtrl.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _bannerCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      children: [
        const SizedBox(height: 14),
        _header(),
        // Guest banner
        if (GuestManager().isGuest) ...[
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => showGuestSignupSheet(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.accent.withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.visibility_outlined,
                    color: AppTheme.primary,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'You\'re viewing as Guest — tap to sign up for full access',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppTheme.primary,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 20),
        _searchBar(),
        const SizedBox(height: 22),
        _banner(),
        const SizedBox(height: 26),
        Row(
          children: [
            Text("Explore", style: AppTheme.subheading.copyWith(fontSize: 18)),
            const Spacer(),
            Text(
              "See all",
              style: AppTheme.body.copyWith(
                color: AppTheme.accent,
                fontSize: 13,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _grid(),
        const SizedBox(height: 110),
      ],
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────
  Widget _header() {
    // Guest mode — show simplified header
    if (GuestManager().isGuest) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppTheme.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.accent.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  Icons.person_outline_rounded,
                  color: AppTheme.primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 13),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Hey, Guest 👋",
                    style: AppTheme.subheading.copyWith(fontSize: 17),
                  ),
                  Text(
                    "Sign in for full access",
                    style: AppTheme.body.copyWith(fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          GestureDetector(
            onTap: () {
              GuestManager().setGuest(false);
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const AuthFlowHandler()),
                (route) => false,
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text(
                'Sign In',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      );
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .snapshots(),
      builder: (ctx, snap) {
        String name = "User";
        String? photoUrl;
        if (snap.hasData && snap.data!.exists) {
          final d = snap.data!.data() as Map<String, dynamic>;
          name = d['name'] ?? "User";
          photoUrl = d['photoUrl'];
        }
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                // avatar — refreshes from Firestore whenever photoUrl changes
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.accent.withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withValues(alpha: 0.15),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: photoUrl != null
                        ? Image.network(
                            photoUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Icon(
                              Icons.person_rounded,
                              color: AppTheme.primary,
                              size: 28,
                            ),
                          )
                        : Icon(
                            Icons.person_rounded,
                            color: AppTheme.primary,
                            size: 28,
                          ),
                  ),
                ),
                const SizedBox(width: 13),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Hey, $name 👋",
                      style: AppTheme.subheading.copyWith(fontSize: 17),
                    ),
                    Text(
                      "Let's crush today's goals",
                      style: AppTheme.body.copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
            GestureDetector(
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                if (ctx.mounted) {
                  Navigator.of(ctx).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const AuthFlowHandler()),
                    (_) => false,
                  );
                }
              },
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: AppTheme.card(radius: 14),
                child: Icon(
                  Icons.logout_rounded,
                  color: AppTheme.primary,
                  size: 20,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ── Search bar ───────────────────────────────────────────────────────────
  Widget _searchBar() => Container(
    height: 52,
    decoration: BoxDecoration(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppTheme.divider),
      boxShadow: [
        BoxShadow(
          color: AppTheme.primary.withValues(alpha: 0.04),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: TextField(
      controller: _searchCtrl,
      onChanged: (v) => setState(() => _query = v),
      style: TextStyle(color: AppTheme.dark, fontSize: 14),
      decoration: InputDecoration(
        hintText: "Search plans, supplements...",
        hintStyle: TextStyle(color: AppTheme.muted, fontSize: 14),
        prefixIcon: Icon(Icons.search_rounded, color: AppTheme.muted, size: 22),
        suffixIcon: _query.isNotEmpty
            ? GestureDetector(
                onTap: () {
                  _searchCtrl.clear();
                  setState(() => _query = '');
                },
                child: Icon(
                  Icons.close_rounded,
                  color: AppTheme.muted,
                  size: 20,
                ),
              )
            : null,
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(vertical: 15),
      ),
    ),
  );

  // ── Banner — infinite loop, all slides with working buttons ────────────
  Widget _banner() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('supplements').snapshots(),
      builder: (ctx, snap) {
        List<SupplementItem> deals = [];
        if (snap.hasData) {
          deals = snap.data!.docs
              .map(SupplementItem.fromFirestore)
              .where((i) => i.isOnSale)
              .toList();
        }

        final hasDeals = deals.isNotEmpty;
        final realCount = _staticBanners.length + (hasDeals ? 1 : 0);
        // Large multiple for "infinite" feel — user will never reach the end
        const loopFactor = 1000;
        final loopCount = realCount * loopFactor;

        return Column(
          children: [
            SizedBox(
              height: 190,
              child: PageView.builder(
                controller: _bannerCtrl,
                itemCount: loopCount,
                onPageChanged: (i) =>
                    setState(() => _bannerIdx = i % realCount),
                itemBuilder: (_, loopI) {
                  final i = loopI % realCount;

                  // ── Static slides 0-2 ──────────────────────────────────
                  if (i < _staticBanners.length) {
                    final b = _staticBanners[i];
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppTheme.primary, AppTheme.primaryLight],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primary.withValues(alpha: 0.3),
                              blurRadius: 18,
                              offset: const Offset(0, 7),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              right: -20,
                              top: -20,
                              child: Container(
                                width: 140,
                                height: 140,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.06),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                            Positioned(
                              right: 16,
                              bottom: 10,
                              child: Icon(
                                b["icon"] as IconData,
                                size: 60,
                                color: Colors.white.withValues(alpha: 0.10),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 22,
                                vertical: 18,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.18,
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      b["tag"] as String,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.3,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    b["title"] as String,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      height: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    b["sub"] as String,
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.65,
                                      ),
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  GestureDetector(
                                    onTap: () {
                                      final action = b["action"] as String;
                                      switch (action) {
                                        case "supplements":
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  const SupplementStoreScreen(),
                                            ),
                                          );
                                          break;
                                        case "meal":
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  const MealPlanScreen(),
                                            ),
                                          );
                                          break;
                                        case "consultation":
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  const ConsultationScreen(),
                                            ),
                                          );
                                          break;
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 18,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppTheme.accent,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        b["btn"] as String,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  // ── Deals slide (index == realCount - 1) ───────────────
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppTheme.primary, AppTheme.primaryLight],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primary.withValues(alpha: 0.35),
                            blurRadius: 18,
                            offset: const Offset(0, 7),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            right: -20,
                            top: -20,
                            child: Container(
                              width: 140,
                              height: 140,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.06),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          Positioned(
                            right: 16,
                            bottom: 10,
                            child: Icon(
                              Icons.local_offer_rounded,
                              size: 60,
                              color: Colors.white.withValues(alpha: 0.10),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 22,
                              vertical: 18,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.18),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text(
                                    "🔥 HOT DEALS",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.3,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "Up to ${_maxDiscount(deals)}% OFF",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    height: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  "${deals.length} discounted products",
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.75),
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                GestureDetector(
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => DealsScreen(deals: deals),
                                    ),
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 18,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.accent,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Text(
                                      "Shop Deals",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            // dot indicators — show real position via modulo
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                realCount,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 280),
                  width: _bannerIdx == i ? 22 : 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: _bannerIdx == i
                        ? AppTheme.primary
                        : AppTheme.accent.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  int _maxDiscount(List<SupplementItem> deals) {
    if (deals.isEmpty) return 0;
    return deals
        .map((d) => ((1 - d.discountPrice! / d.price) * 100).round())
        .reduce((a, b) => a > b ? a : b);
  }

  // ── Grid ─────────────────────────────────────────────────────────────────
  Widget _grid() {
    final list = _filtered;
    if (list.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 30),
        child: Center(
          child: Text(
            'No results for "$_query"',
            style: AppTheme.body.copyWith(fontSize: 15),
          ),
        ),
      );
    }

    const cardGradients = [
      [Color(0xFF3B2314), Color(0xFF7B5035)],
      [Color(0xFF1C2A1E), Color(0xFF3A5C3E)],
      [Color(0xFF2A1C0E), Color(0xFF6B4C2A)],
      [Color(0xFF1A1A2A), Color(0xFF3D3460)],
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.92,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
      ),
      itemCount: list.length,
      itemBuilder: (ctx, i) {
        final item = list[i];
        final idx = item["idx"] as int;
        final cols = cardGradients[idx % cardGradients.length];
        return GestureDetector(
          onTap: () {
            final isGuest = GuestManager().isGuest;
            Widget screen;
            switch (idx) {
              case 0: // Training Plan
                screen = isGuest
                    ? const GuestTrainingPreview()
                    : const LevelSelectionScreen();
                break;
              case 1: // Supplements — guests see real store (cart allowed, checkout blocked)
                screen = const SupplementStoreScreen();
                break;
              case 2: // Meal Plan
                screen = isGuest
                    ? const GuestMealPreview()
                    : const MealPlanScreen();
                break;
              case 3: // Consultation
                screen = isGuest
                    ? const GuestConsultationPreview()
                    : const ConsultationScreen();
                break;
              default:
                screen = const LevelSelectionScreen();
            }
            Navigator.push(ctx, MaterialPageRoute(builder: (_) => screen));
          },
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: cols,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: cols[0].withValues(alpha: 0.4),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    item["icon"] as IconData,
                    color: AppTheme.accent,
                    size: 24,
                  ),
                ),
                const Spacer(),
                Text(
                  item["title"] as String,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  item["sub"] as String,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.48),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppTheme.accent.withValues(alpha: 0.22),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_forward_rounded,
                      color: AppTheme.accent,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── ADMIN BOOKINGS PANEL ────────────────────────────────────────────────────
class AdminBookingsPanel extends StatefulWidget {
  const AdminBookingsPanel({super.key});
  @override
  State<AdminBookingsPanel> createState() => _AdminBookingsPanelState();
}

class _AdminBookingsPanelState extends State<AdminBookingsPanel>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _db = FirebaseFirestore.instance;

  static const _tabs = ['All', 'Pending', 'Confirmed', 'Cancelled'];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Query<Map<String, dynamic>> _query(String tab) {
    final base = _db
        .collection('bookings')
        .orderBy('createdAt', descending: true);
    if (tab == 'All') return base;
    return base.where('status', isEqualTo: tab.toLowerCase());
  }

  Future<void> _updateStatus(String docId, String status) async {
    await _db.collection('bookings').doc(docId).update({'status': status});
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Booking $status.'),
          backgroundColor: status == 'confirmed'
              ? Colors.green
              : Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Bookings — Admin',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: AppTheme.dark,
          ),
        ),
        centerTitle: false,
        bottom: TabBar(
          controller: _tabCtrl,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.muted,
          indicatorColor: AppTheme.primary,
          indicatorWeight: 2.5,
          labelStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: _tabs
            .map(
              (tab) => _BookingsList(
                query: _query(tab),
                onUpdateStatus: _updateStatus,
              ),
            )
            .toList(),
      ),
    );
  }
}

class _BookingsList extends StatelessWidget {
  final Query<Map<String, dynamic>> query;
  final Future<void> Function(String docId, String status) onUpdateStatus;

  const _BookingsList({required this.query, required this.onUpdateStatus});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: query.snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primary),
          );
        }
        if (snap.hasError) {
          return Center(
            child: Text(
              'Error loading bookings.\n${snap.error}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Poppins',
                color: AppTheme.muted,
              ),
            ),
          );
        }
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  size: 48,
                  color: AppTheme.muted.withValues(alpha: 0.4),
                ),
                const SizedBox(height: 12),
                const Text(
                  'No bookings found',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 15,
                    color: AppTheme.muted,
                  ),
                ),
              ],
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, i) =>
              _BookingCard(doc: docs[i], onUpdateStatus: onUpdateStatus),
        );
      },
    );
  }
}

class _BookingCard extends StatelessWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  final Future<void> Function(String docId, String status) onUpdateStatus;

  const _BookingCard({required this.doc, required this.onUpdateStatus});

  Color _statusColor(String status) {
    switch (status) {
      case 'confirmed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  IconData _typeIcon(String? type) {
    if (type == 'nutritionist') return Icons.restaurant_menu_rounded;
    return Icons.fitness_center_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final d = doc.data();
    final status = d['status'] as String? ?? 'pending';
    final name = d['specialistName'] as String? ?? '—';
    final type = d['specialistType'] as String? ?? 'pt';
    final specialty = d['specialty'] as String? ?? '—';
    final date = d['date'] as String? ?? '—';
    final time = d['time'] as String? ?? '—';
    final address = d['address'] as String? ?? '';
    final lat = d['locationLat'];
    final lng = d['locationLng'];
    final hasPin = d['hasMapPin'] == true;
    final price = (d['price'] as num?)?.toDouble() ?? 0;
    final userId = d['userId'] as String? ?? '—';

    final statusColor = _statusColor(status);
    final isPending = status == 'pending';

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.divider, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row ─────────────────────────────────────────────────
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _typeIcon(type),
                    color: AppTheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: AppTheme.dark,
                        ),
                      ),
                      Text(
                        specialty,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          color: AppTheme.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    status[0].toUpperCase() + status.substring(1),
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),
            const Divider(height: 1, color: AppTheme.divider),
            const SizedBox(height: 12),

            // ── Details grid ───────────────────────────────────────────────
            _detailRow(
              Icons.calendar_today_rounded,
              'Date & Time',
              '$date  •  $time',
            ),
            const SizedBox(height: 6),
            _detailRow(
              Icons.attach_money_rounded,
              'Session Fee',
              '\$${price.toStringAsFixed(0)}/hr',
            ),
            const SizedBox(height: 6),
            _detailRow(
              Icons.person_outline_rounded,
              'User ID',
              userId,
              mono: true,
            ),
            const SizedBox(height: 6),

            // Address
            if (address.isNotEmpty)
              _detailRow(Icons.home_outlined, 'Address', address),

            // Map coordinates
            if (hasPin && lat != null && lng != null) ...[
              const SizedBox(height: 6),
              _detailRow(
                Icons.location_on_rounded,
                'Location',
                '${(lat as num).toStringAsFixed(5)}, ${(lng as num).toStringAsFixed(5)}',
              ),
            ],

            if (!hasPin && address.isEmpty) ...[
              const SizedBox(height: 6),
              _detailRow(
                Icons.location_off_rounded,
                'Location',
                'Not provided',
                valueColor: Colors.orange.shade700,
              ),
            ],

            // ── Action buttons (only for pending bookings) ─────────────────
            if (isPending) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.close_rounded, size: 16),
                      label: const Text(
                        'Cancel',
                        style: TextStyle(fontFamily: 'Poppins', fontSize: 13),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      onPressed: () => onUpdateStatus(doc.id, 'cancelled'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.check_rounded, size: 16),
                      label: const Text(
                        'Confirm',
                        style: TextStyle(fontFamily: 'Poppins', fontSize: 13),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      onPressed: () => onUpdateStatus(doc.id, 'confirmed'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _detailRow(
    IconData icon,
    String label,
    String value, {
    bool mono = false,
    Color? valueColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: AppTheme.muted),
        const SizedBox(width: 8),
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              color: AppTheme.muted,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontFamily: mono ? 'monospace' : 'Poppins',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: valueColor ?? AppTheme.dark,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ),
      ],
    );
  }
}
