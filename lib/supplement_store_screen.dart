import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'app_theme.dart';
import 'dashboard_screen.dart';
import 'cart_screen.dart';
import 'supplement_models.dart';
import 'auth_screen.dart' show GuestManager;
import 'guest_preview_screen.dart' show showGuestSignupSheet;

// local alias so existing code using _SupplementImage still works
typedef _SupplementImage = SupplementImage;

// ─── MAIN STORE SCREEN ───────────────────────────────────────────────────────
class SupplementStoreScreen extends StatefulWidget {
  const SupplementStoreScreen({super.key});
  @override
  State<SupplementStoreScreen> createState() => _SupplementStoreScreenState();
}

class _SupplementStoreScreenState extends State<SupplementStoreScreen> {
  int _cartCount = 0;
  final _searchCtrl = TextEditingController();
  String _query = '';

  static const _categories = [
    "Pre-Workouts",
    "Proteins & Recovery",
    "Mass Gainers",
    "Creatine & Performance",
    "Vitamins & Health",
    "Weight Loss",
    "Snacks",
  ];

  static const _catMap = {
    "Pre-Workout": "Pre-Workouts",
    "Protein": "Proteins & Recovery",
    "Recovery": "Proteins & Recovery",
    "Mass Gainer": "Mass Gainers",
    "Creatine": "Creatine & Performance",
    "Vitamins": "Vitamins & Health",
    "Weight Loss": "Weight Loss",
    "Snacks": "Snacks",
  };

  @override
  void initState() {
    super.initState();
    CartManager().addListener(_onCart);
    _cartCount = CartManager().count;
  }

  @override
  void dispose() {
    CartManager().removeListener(_onCart);
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onCart() {
    if (mounted) setState(() => _cartCount = CartManager().count);
  }

  void _addToCart(SupplementItem item, {int qty = 1}) {
    if (GuestManager().isGuest) {
      showGuestSignupSheet(context);
      return;
    }
    for (int i = 0; i < qty; i++) {
      CartManager().addItem(
        CartItem(
          id: item.id,
          name: item.name,
          price: item.effectivePrice,
          quantity: 1,
          icon: Icons.science_rounded,
          imageUrl: item.imageUrl,
        ),
      );
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "${item.name} added to cart",
          style: const TextStyle(fontFamily: 'Poppins'),
        ),
        backgroundColor: AppTheme.primary,
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // Opens full product detail bottom sheet
  void _openDetail(SupplementItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProductDetailSheet(
        item: item,
        onAddToCart: (qty) => _addToCart(item, qty: qty),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppTheme.background,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('supplements')
            .snapshots(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(color: AppTheme.primary),
              ),
            );
          }
          if (snap.hasError) {
            return Scaffold(
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: AppTheme.primary,
                        size: 56,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Could not load supplements",
                        style: AppTheme.subheading,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "${snap.error}",
                        style: AppTheme.body,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          final all =
              (snap.data?.docs ?? []).map(SupplementItem.fromFirestore).toList()
                ..sort((a, b) => a.name.compareTo(b.name));

          final deals = all.where((i) => i.isOnSale).toList();

          final items = _query.isEmpty
              ? all
              : all
                    .where(
                      (i) =>
                          i.name.toLowerCase().contains(_query.toLowerCase()) ||
                          i.category.toLowerCase().contains(
                            _query.toLowerCase(),
                          ),
                    )
                    .toList();

          final Map<String, List<SupplementItem>> grouped = {};
          for (final item in items) {
            final display = _catMap[item.category] ?? item.category;
            grouped.putIfAbsent(display, () => []).add(item);
          }

          return CustomScrollView(
            slivers: [
              // ── AppBar ──────────────────────────────────────────────
              SliverAppBar(
                pinned: true,
                backgroundColor: AppTheme.background,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: AppTheme.dark,
                  ),
                  onPressed: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const DashboardScreen()),
                  ),
                ),
                title: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                        color: AppTheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.bolt_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      "STORE",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primary,
                        fontSize: 18,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
                actions: [
                  IconButton(
                    icon: Icon(
                      _query.isEmpty
                          ? Icons.search_rounded
                          : Icons.close_rounded,
                      color: AppTheme.dark,
                    ),
                    onPressed: () {
                      if (_query.isNotEmpty) {
                        _searchCtrl.clear();
                        setState(() => _query = '');
                      } else {
                        _showSearch();
                      }
                    },
                  ),
                  Stack(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.shopping_cart_outlined,
                          color: AppTheme.dark,
                        ),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const CartScreen()),
                        ),
                      ),
                      if (_cartCount > 0)
                        Positioned(
                          top: 6,
                          right: 6,
                          child: Container(
                            width: 17,
                            height: 17,
                            decoration: const BoxDecoration(
                              color: AppTheme.primary,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                _cartCount > 9 ? "9+" : "$_cartCount",
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
                  const SizedBox(width: 4),
                ],
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(1),
                  child: Container(height: 1, color: AppTheme.divider),
                ),
              ),

              // ── Hero Banner ──────────────────────────────────────────
              SliverToBoxAdapter(child: _heroBanner(deals)),

              // ── Empty state ──────────────────────────────────────────
              if (all.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            color: AppTheme.accent,
                            size: 60,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "No supplements found",
                            style: AppTheme.subheading.copyWith(fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Add supplements to your Firestore 'supplements' collection.",
                            style: AppTheme.body.copyWith(fontSize: 13),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else if (_query.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => _listTile(items[i]),
                      childCount: items.length,
                    ),
                  ),
                )
              else ...[
                // ── Deals section always shown first ─────────────────────
                SliverToBoxAdapter(child: _dealsSection(deals)),
                // ── Category sections — exclude on-sale items so they only
                //    appear in the HOT DEALS section above ─────────────────
                for (final cat in _categories)
                  if (grouped.containsKey(cat) &&
                      grouped[cat]!.any((i) => !i.isOnSale))
                    SliverToBoxAdapter(
                      child: _section(
                        cat,
                        grouped[cat]!.where((i) => !i.isOnSale).toList(),
                      ),
                    ),
                // Any unmapped category — skip if empty after filtering deals
                for (final cat in grouped.keys)
                  if (!_categories.contains(cat))
                    if (grouped[cat]!.any((i) => !i.isOnSale))
                      SliverToBoxAdapter(
                        child: _section(
                          cat,
                          grouped[cat]!.where((i) => !i.isOnSale).toList(),
                        ),
                      ),
              ],

              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          );
        },
      ),
    );
  }

  // ── Hero banner — single slide only ─────────────────────────────────────
  Widget _heroBanner(List<SupplementItem> deals) {
    return SizedBox(height: 155, child: _mainBannerSlide());
  }

  Widget _mainBannerSlide() => ClipRRect(
    borderRadius: BorderRadius.circular(18),
    child: Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppTheme.dark,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "WE HAVE EVERYTHING\nYOU NEED FROM A-Z",
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const _AllSupplementsScreen(),
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.accent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      "Shop All",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.shopping_bag_outlined,
            color: Colors.white24,
            size: 52,
          ),
        ],
      ),
    ),
  );

  Widget _dealsBannerSlide(List<SupplementItem> deals) => ClipRRect(
    borderRadius: BorderRadius.circular(18),
    child: Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primary, AppTheme.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    "🔥 HOT DEALS",
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 10,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  "Discounted\nSupplements",
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DealsScreen(deals: deals),
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "Shop Deals",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // no product images — background will be added later
        ],
      ),
    ),
  );

  // ── Deals section — always visible, shows discounted items ──────────────
  Widget _dealsSection(List<SupplementItem> deals) {
    final preview = deals.take(3).toList();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          // header
          Row(
            children: [
              const Text(
                "HOT DEALS",
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: AppTheme.dark,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.red.shade600,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  deals.isEmpty ? "No deals yet" : "${deals.length} deals",
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // products or empty state
          if (deals.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: AppTheme.card(radius: 14),
              child: Column(
                children: [
                  Icon(
                    Icons.local_offer_outlined,
                    color: AppTheme.accent,
                    size: 36,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "No discounted products yet",
                    style: AppTheme.body.copyWith(fontSize: 13),
                  ),
                ],
              ),
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(
                preview.length,
                (i) => Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: i < preview.length - 1 ? 8 : 0,
                    ),
                    child: _productCard(preview[i]),
                  ),
                ),
              ),
            ),

          const SizedBox(height: 12),
          // VIEW ALL DEALS — same style as VIEW MORE
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => DealsScreen(deals: deals)),
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.divider),
              ),
              child: const Center(
                child: Text(
                  "VIEW ALL DEALS",
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: AppTheme.primary,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Divider(color: AppTheme.divider, height: 1),
        ],
      ),
    );
  }

  // ── Category section ─────────────────────────────────────────────────────
  Widget _section(String title, List<SupplementItem> items) {
    final preview = items.take(3).toList();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w800,
              fontSize: 13,
              color: AppTheme.dark,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(
              preview.length,
              (i) => Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: i < preview.length - 1 ? 8 : 0,
                  ),
                  child: _productCard(preview[i]),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    _CategoryScreen(category: title, allItems: items),
              ),
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.divider),
              ),
              child: const Center(
                child: Text(
                  "VIEW MORE",
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: AppTheme.primary,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Divider(color: AppTheme.divider, height: 1),
        ],
      ),
    );
  }

  // ── Product card — equal height enforced with fixed image area ───────────
  Widget _productCard(SupplementItem item) {
    return _ScaleOnPress(
      onTap: () => _openDetail(item),
      child: Container(
        decoration: AppTheme.card(radius: 14),
        padding: const EdgeInsets.all(10),
        // Column with fixed-height image ensures all cards are the same size
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // fixed-size image box — all cards same height here
            Stack(
              children: [
                SizedBox(
                  height: 80,
                  width: double.infinity,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.accent.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: item.imageUrl.isNotEmpty
                          ? _SupplementImage(
                              imageUrl: item.imageUrl,
                              size: 60,
                              borderRadius: BorderRadius.circular(10),
                            )
                          : Icon(
                              Icons.science_rounded,
                              color: AppTheme.accent,
                              size: 36,
                            ),
                    ),
                  ),
                ),
                // Out of stock overlay
                if (item.quantity == 0)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Center(
                        child: Text(
                          'OUT OF\nSTOCK',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 10,
                            letterSpacing: 0.8,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ),
                  ),
                if (item.isOnSale && item.quantity > 0)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.shade600,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        "SALE",
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            // fixed 2-line name — keeps all cards same height regardless of name length
            SizedBox(
              height: 30,
              child: Text(
                item.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                  color: AppTheme.dark,
                  height: 1.3,
                ),
              ),
            ),
            const SizedBox(height: 4),
            // fixed-height price area (sale has 2 lines, normal has 1)
            SizedBox(
              height: 32,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (item.isOnSale)
                    Text(
                      "${item.price.toStringAsFixed(0)} JD",
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10,
                        color: AppTheme.muted,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  Text(
                    item.isOnSale
                        ? "${item.discountPrice!.toStringAsFixed(0)} JD"
                        : "${item.price.toStringAsFixed(0)} JD",
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      color: item.isOnSale ? Colors.red : AppTheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: item.quantity == 0 ? null : () => _addToCart(item),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: item.quantity == 0
                      ? AppTheme.divider
                      : Colors.transparent,
                  border: Border.all(
                    color: item.quantity == 0
                        ? AppTheme.divider
                        : AppTheme.primary,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: item.quantity == 0
                      ? Text(
                          "OUT OF STOCK",
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.muted,
                            letterSpacing: 0.8,
                          ),
                        )
                      : GuestManager().isGuest
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(
                              Icons.lock_rounded,
                              size: 9,
                              color: AppTheme.primary,
                            ),
                            SizedBox(width: 4),
                            Text(
                              "SIGN UP TO ADD",
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primary,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        )
                      : Text(
                          "ADD TO CART",
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primary,
                            letterSpacing: 0.8,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Search result list tile ───────────────────────────────────────────────
  Widget _listTile(SupplementItem item) => _ScaleOnPress(
    onTap: () => _openDetail(item),
    child: Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.card(radius: 14),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppTheme.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: item.imageUrl.isNotEmpty
                ? _SupplementImage(
                    imageUrl: item.imageUrl,
                    size: 28,
                    borderRadius: BorderRadius.circular(12),
                  )
                : Icon(Icons.science_rounded, color: AppTheme.accent, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: AppTheme.subheading.copyWith(fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(item.unit, style: AppTheme.body.copyWith(fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "${item.effectivePrice.toStringAsFixed(0)} JD",
                style: AppTheme.subheading.copyWith(
                  color: item.isOnSale ? Colors.red : AppTheme.primary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: () => _addToCart(item),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    "Add",
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  void _showSearch() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          "Search Supplements",
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        content: TextField(
          controller: _searchCtrl,
          autofocus: true,
          onChanged: (v) => setState(() => _query = v),
          style: const TextStyle(fontFamily: 'Poppins'),
          decoration: AppTheme.inputDecoration(
            "Type product name...",
            Icons.search_rounded,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Done",
              style: TextStyle(
                fontFamily: 'Poppins',
                color: AppTheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── SCALE ON PRESS ──────────────────────────────────────────────────────────
class _ScaleOnPress extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const _ScaleOnPress({required this.child, required this.onTap});
  @override
  State<_ScaleOnPress> createState() => _ScaleOnPressState();
}

class _ScaleOnPressState extends State<_ScaleOnPress>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ac = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 120),
    lowerBound: 0.0,
    upperBound: 0.05,
  );
  late final Animation<double> _scale = Tween<double>(
    begin: 1.0,
    end: 1.06,
  ).animate(CurvedAnimation(parent: _ac, curve: Curves.easeOut));

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTapDown: (_) => _ac.forward(),
    onTapUp: (_) {
      _ac.reverse();
      widget.onTap();
    },
    onTapCancel: () => _ac.reverse(),
    child: ScaleTransition(scale: _scale, child: widget.child),
  );
}

// ─── PRODUCT DETAIL BOTTOM SHEET ─────────────────────────────────────────────
class _ProductDetailSheet extends StatefulWidget {
  final SupplementItem item;
  final Function(int qty) onAddToCart;
  const _ProductDetailSheet({required this.item, required this.onAddToCart});
  @override
  State<_ProductDetailSheet> createState() => _ProductDetailSheetState();
}

class _ProductDetailSheetState extends State<_ProductDetailSheet> {
  int _qty = 1;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, scroll) => Container(
        decoration: const BoxDecoration(
          color: AppTheme.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: ListView(
          controller: scroll,
          children: [
            // drag handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.divider,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            // product image — large
            Container(
              height: 220,
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: AppTheme.accent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(22),
              ),
              child: item.imageUrl.isNotEmpty
                  ? _SupplementImage(
                      imageUrl: item.imageUrl,
                      size: 140,
                      borderRadius: BorderRadius.circular(22),
                      fit: BoxFit.contain,
                    )
                  : Icon(
                      Icons.science_rounded,
                      color: AppTheme.accent,
                      size: 90,
                    ),
            ),

            const SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // sale badge
                  if (item.isOnSale)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.shade600,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "SAVE ${((1 - item.discountPrice! / item.price) * 100).round()}% OFF",
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),

                  // name
                  Text(
                    item.name,
                    style: AppTheme.heading.copyWith(fontSize: 20, height: 1.2),
                  ),
                  const SizedBox(height: 6),

                  // unit
                  Text(item.unit, style: AppTheme.body.copyWith(fontSize: 13)),
                  const SizedBox(height: 10),

                  // rating row
                  Row(
                    children: [
                      ...List.generate(
                        5,
                        (i) => Icon(
                          i < item.rating.round()
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          color: AppTheme.accent,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        item.rating.toStringAsFixed(1),
                        style: AppTheme.subheading.copyWith(
                          fontSize: 13,
                          color: AppTheme.muted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // price
                  Row(
                    children: [
                      if (item.isOnSale) ...[
                        Text(
                          "${item.discountPrice!.toStringAsFixed(0)} JD",
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Colors.red.shade700,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          "${item.price.toStringAsFixed(0)} JD",
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 16,
                            color: AppTheme.muted,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ] else
                        Text(
                          "${item.price.toStringAsFixed(0)} JD",
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.primary,
                          ),
                        ),
                    ],
                  ),

                  // description
                  if (item.description.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      "About this product",
                      style: AppTheme.subheading.copyWith(fontSize: 14),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.description,
                      style: AppTheme.body.copyWith(fontSize: 13, height: 1.6),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // qty selector + add to cart
                  item.quantity == 0
                      ? Container(
                          width: double.infinity,
                          height: 52,
                          decoration: BoxDecoration(
                            color: AppTheme.divider,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Center(
                            child: Text(
                              "OUT OF STOCK",
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                color: AppTheme.muted,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        )
                      : Row(
                          children: [
                            // qty controls
                            Container(
                              decoration: AppTheme.card(radius: 30),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 4,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _qtyBtn(Icons.remove, () {
                                    if (_qty > 1) setState(() => _qty--);
                                  }),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                    ),
                                    child: Text(
                                      "$_qty",
                                      style: AppTheme.subheading.copyWith(
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  _qtyBtn(
                                    Icons.add,
                                    () => setState(() => _qty++),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 14),
                            // add to cart button
                            Expanded(
                              child: SizedBox(
                                height: 52,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primary,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    elevation: 4,
                                    shadowColor: AppTheme.primary.withValues(
                                      alpha: 0.35,
                                    ),
                                  ),
                                  onPressed: () {
                                    widget.onAddToCart(_qty);
                                    Navigator.pop(context);
                                  },
                                  child: Text(
                                    "Add $_qty to Cart",
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: AppTheme.accent.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: AppTheme.primary, size: 18),
    ),
  );
}

// ─── CATEGORY DETAIL SCREEN ───────────────────────────────────────────────────
class _CategoryScreen extends StatefulWidget {
  final String category;
  final List<SupplementItem> allItems;
  const _CategoryScreen({required this.category, required this.allItems});
  @override
  State<_CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<_CategoryScreen> {
  int _cartCount = 0;
  // qty per item (id → qty)
  final Map<String, int> _qtys = {};

  @override
  void initState() {
    super.initState();
    CartManager().addListener(_onCart);
    _cartCount = CartManager().count;
    for (final item in widget.allItems) {
      _qtys[item.id] = 1;
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

  void _addToCart(SupplementItem item) {
    if (GuestManager().isGuest) {
      showGuestSignupSheet(context);
      return;
    }
    final qty = _qtys[item.id] ?? 1;
    for (int i = 0; i < qty; i++) {
      CartManager().addItem(
        CartItem(
          id: item.id,
          name: item.name,
          price: item.effectivePrice,
          quantity: 1,
          icon: Icons.science_rounded,
          imageUrl: item.imageUrl,
        ),
      );
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "${item.name} × $qty added to cart",
          style: const TextStyle(fontFamily: 'Poppins'),
        ),
        backgroundColor: AppTheme.primary,
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _openDetail(SupplementItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProductDetailSheet(
        item: item,
        onAddToCart: (qty) {
          for (int i = 0; i < qty; i++) {
            CartManager().addItem(
              CartItem(
                id: item.id,
                name: item.name,
                price: item.effectivePrice,
                quantity: 1,
                icon: Icons.science_rounded,
              ),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppTheme.dark,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.category,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
            fontSize: 17,
            color: AppTheme.dark,
          ),
        ),
        actions: [_cartIcon(context, _cartCount), const SizedBox(width: 4)],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: widget.allItems.length,
        itemBuilder: (_, i) => _detailCard(widget.allItems[i]),
      ),
    );
  }

  Widget _detailCard(SupplementItem item) {
    final qty = _qtys[item.id] ?? 1;
    return _ScaleOnPress(
      onTap: () => _openDetail(item),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: AppTheme.card(radius: 18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // image
            Container(
              width: 110,
              height: 140,
              decoration: BoxDecoration(
                color: AppTheme.accent.withValues(alpha: 0.08),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                ),
              ),
              child: item.imageUrl.isNotEmpty
                  ? _SupplementImage(
                      imageUrl: item.imageUrl,
                      size: 46,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(18),
                        bottomLeft: Radius.circular(18),
                      ),
                    )
                  : Icon(
                      Icons.science_rounded,
                      color: AppTheme.accent,
                      size: 46,
                    ),
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // sale badge
                    if (item.isOnSale)
                      Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.shade600,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          "SALE",
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: AppTheme.dark,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.unit,
                      style: AppTheme.body.copyWith(fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    // stars
                    Row(
                      children: [
                        ...List.generate(
                          5,
                          (i) => Icon(
                            i < item.rating.round()
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            color: AppTheme.accent,
                            size: 13,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "(${item.rating.toStringAsFixed(1)})",
                          style: AppTheme.body.copyWith(fontSize: 10),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // price
                    if (item.isOnSale) ...[
                      Text(
                        "${item.price.toStringAsFixed(0)} JD",
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          color: AppTheme.muted,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                      Text(
                        "${item.discountPrice!.toStringAsFixed(0)} JD",
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ] else
                      Text(
                        "${item.price.toStringAsFixed(0)} JD",
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: AppTheme.primary,
                        ),
                      ),
                    const SizedBox(height: 8),
                    // ── Qty + BUY NOW row ──────────────────────────────────
                    item.quantity == 0
                        ? Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            decoration: BoxDecoration(
                              color: AppTheme.divider,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Center(
                              child: Text(
                                "OUT OF STOCK",
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  color: AppTheme.muted,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          )
                        : Row(
                            children: [
                              // qty controls
                              Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: AppTheme.divider),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 2,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _qtyBtn(Icons.remove, () {
                                      if (qty > 1) {
                                        setState(
                                          () => _qtys[item.id] = qty - 1,
                                        );
                                      }
                                    }),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                      ),
                                      child: Text(
                                        "$qty",
                                        style: AppTheme.subheading.copyWith(
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                    _qtyBtn(
                                      Icons.add,
                                      () => setState(
                                        () => _qtys[item.id] = qty + 1,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              // buy now
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => _addToCart(item),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 9,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primary,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Center(
                                      child: Text(
                                        "BUY NOW",
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
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

  Widget _qtyBtn(IconData icon, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: AppTheme.accent.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 14, color: AppTheme.primary),
    ),
  );
}

// ─── DEALS SCREEN (public — also used from dashboard banner) ─────────────────
class DealsScreen extends StatefulWidget {
  final List<SupplementItem> deals;
  const DealsScreen({super.key, required this.deals});
  @override
  State<DealsScreen> createState() => _DealsScreenState();
}

class _DealsScreenState extends State<DealsScreen> {
  int _cartCount = 0;
  final Map<String, int> _qtys = {};

  @override
  void initState() {
    super.initState();
    CartManager().addListener(_onCart);
    _cartCount = CartManager().count;
    for (final item in widget.deals) {
      _qtys[item.id] = 1;
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

  void _addToCart(SupplementItem item) {
    if (GuestManager().isGuest) {
      showGuestSignupSheet(context);
      return;
    }
    final qty = _qtys[item.id] ?? 1;
    for (int i = 0; i < qty; i++) {
      CartManager().addItem(
        CartItem(
          id: item.id,
          name: item.name,
          price: item.effectivePrice,
          quantity: 1,
          icon: Icons.science_rounded,
          imageUrl: item.imageUrl,
        ),
      );
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "${item.name} added to cart",
          style: const TextStyle(fontFamily: 'Poppins'),
        ),
        backgroundColor: AppTheme.primary,
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _openDetail(SupplementItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProductDetailSheet(
        item: item,
        onAddToCart: (qty) {
          for (int i = 0; i < qty; i++) {
            CartManager().addItem(
              CartItem(
                id: item.id,
                name: item.name,
                price: item.effectivePrice,
                quantity: 1,
                icon: Icons.science_rounded,
                imageUrl: item.imageUrl,
              ),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppTheme.dark,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "🔥 Hot Deals",
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
            fontSize: 17,
            color: AppTheme.dark,
          ),
        ),
        actions: [_cartIcon(context, _cartCount), const SizedBox(width: 4)],
      ),
      body: widget.deals.isEmpty
          ? Center(
              child: Text(
                "No deals available right now.",
                style: AppTheme.body.copyWith(fontSize: 15),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: widget.deals.length,
              itemBuilder: (_, i) {
                final item = widget.deals[i];
                final qty = _qtys[item.id] ?? 1;
                return _ScaleOnPress(
                  onTap: () => _openDetail(item),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: AppTheme.card(radius: 18),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 110,
                          height: 140,
                          decoration: BoxDecoration(
                            color: AppTheme.accent.withValues(alpha: 0.08),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(18),
                              bottomLeft: Radius.circular(18),
                            ),
                          ),
                          child: Stack(
                            children: [
                              Center(
                                child: item.imageUrl.isNotEmpty
                                    ? _SupplementImage(
                                        imageUrl: item.imageUrl,
                                        size: 70,
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(18),
                                          bottomLeft: Radius.circular(18),
                                        ),
                                      )
                                    : Icon(
                                        Icons.science_rounded,
                                        color: AppTheme.accent,
                                        size: 50,
                                      ),
                              ),
                              Positioned(
                                top: 8,
                                left: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade600,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    "-${((1 - item.discountPrice! / item.price) * 100).round()}%",
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.name,
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    color: AppTheme.dark,
                                    height: 1.3,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  item.unit,
                                  style: AppTheme.body.copyWith(fontSize: 12),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    ...List.generate(
                                      5,
                                      (i) => Icon(
                                        i < item.rating.round()
                                            ? Icons.star_rounded
                                            : Icons.star_outline_rounded,
                                        color: AppTheme.accent,
                                        size: 13,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Text(
                                      "${item.discountPrice!.toStringAsFixed(0)} JD",
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.red.shade700,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      "${item.price.toStringAsFixed(0)} JD",
                                      style: const TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 12,
                                        color: AppTheme.muted,
                                        decoration: TextDecoration.lineThrough,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                item.quantity == 0
                                    ? Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 9,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppTheme.divider,
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: const Center(
                                          child: Text(
                                            "OUT OF STOCK",
                                            style: TextStyle(
                                              fontFamily: 'Poppins',
                                              color: AppTheme.muted,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      )
                                    : Row(
                                        children: [
                                          Container(
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                color: AppTheme.divider,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 4,
                                              vertical: 2,
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                _qtyBtn(Icons.remove, () {
                                                  if (qty > 1) {
                                                    setState(
                                                      () => _qtys[item.id] =
                                                          qty - 1,
                                                    );
                                                  }
                                                }),
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                      ),
                                                  child: Text(
                                                    "$qty",
                                                    style: AppTheme.subheading
                                                        .copyWith(fontSize: 13),
                                                  ),
                                                ),
                                                _qtyBtn(
                                                  Icons.add,
                                                  () => setState(
                                                    () => _qtys[item.id] =
                                                        qty + 1,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: GestureDetector(
                                              onTap: () => _addToCart(item),
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 9,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: AppTheme.primary,
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                ),
                                                child: const Center(
                                                  child: Text(
                                                    "BUY NOW",
                                                    style: TextStyle(
                                                      fontFamily: 'Poppins',
                                                      color: Colors.white,
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: AppTheme.accent.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 14, color: AppTheme.primary),
    ),
  );
}

// ─── ALL SUPPLEMENTS SCREEN ───────────────────────────────────────────────────
class _AllSupplementsScreen extends StatefulWidget {
  const _AllSupplementsScreen();
  @override
  State<_AllSupplementsScreen> createState() => _AllSupplementsScreenState();
}

class _AllSupplementsScreenState extends State<_AllSupplementsScreen> {
  int _cartCount = 0;
  @override
  void initState() {
    super.initState();
    CartManager().addListener(_onCart);
    _cartCount = CartManager().count;
  }

  @override
  void dispose() {
    CartManager().removeListener(_onCart);
    super.dispose();
  }

  void _onCart() {
    if (mounted) setState(() => _cartCount = CartManager().count);
  }

  void _addToCart(SupplementItem item) {
    if (GuestManager().isGuest) {
      showGuestSignupSheet(context);
      return;
    }
    CartManager().addItem(
      CartItem(
        id: item.id,
        name: item.name,
        price: item.effectivePrice,
        quantity: 1,
        icon: Icons.science_rounded,
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "${item.name} added to cart",
          style: const TextStyle(fontFamily: 'Poppins'),
        ),
        backgroundColor: AppTheme.primary,
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppTheme.dark,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "All Products",
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
            fontSize: 17,
            color: AppTheme.dark,
          ),
        ),
        actions: [_cartIcon(context, _cartCount), const SizedBox(width: 4)],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('supplements')
            .snapshots(),
        builder: (_, snap) {
          if (!snap.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            );
          }
          final items =
              snap.data!.docs.map(SupplementItem.fromFirestore).toList()
                ..sort((a, b) => a.name.compareTo(b.name));

          if (items.isEmpty) {
            return Center(
              child: Text("No supplements in database.", style: AppTheme.body),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (_, i) {
              final item = items[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                decoration: AppTheme.card(radius: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 100,
                      height: 120,
                      decoration: BoxDecoration(
                        color: AppTheme.accent.withValues(alpha: 0.08),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          bottomLeft: Radius.circular(16),
                        ),
                      ),
                      child: item.imageUrl.isNotEmpty
                          ? _SupplementImage(
                              imageUrl: item.imageUrl,
                              size: 40,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(16),
                                bottomLeft: Radius.circular(16),
                              ),
                            )
                          : Icon(
                              Icons.science_rounded,
                              color: AppTheme.accent,
                              size: 40,
                            ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: AppTheme.dark,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              item.unit,
                              style: AppTheme.body.copyWith(fontSize: 11),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "${item.effectivePrice.toStringAsFixed(0)} JD",
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                    color: item.isOnSale
                                        ? Colors.red
                                        : AppTheme.primary,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: item.quantity == 0
                                      ? null
                                      : () => _addToCart(item),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: item.quantity == 0
                                          ? AppTheme.divider
                                          : AppTheme.primary,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      item.quantity == 0 ? "SOLD OUT" : "ADD",
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        color: item.quantity == 0
                                            ? AppTheme.muted
                                            : Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ─── Shared cart icon ─────────────────────────────────────────────────────────
Widget _cartIcon(BuildContext context, int count) => Stack(
  children: [
    IconButton(
      icon: const Icon(Icons.shopping_cart_outlined, color: AppTheme.dark),
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CartScreen()),
      ),
    ),
    if (count > 0)
      Positioned(
        top: 6,
        right: 6,
        child: Container(
          width: 17,
          height: 17,
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
);
