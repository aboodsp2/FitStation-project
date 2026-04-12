import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'dashboard_screen.dart';
import 'checkout_screen.dart';

// ═══════════════════════════════════════════════════════════════════════════
// MEAL CART MANAGER  (singleton — separate from supplement CartManager)
// ═══════════════════════════════════════════════════════════════════════════

class MealCartManager {
  static final MealCartManager _instance = MealCartManager._internal();
  factory MealCartManager() => _instance;
  MealCartManager._internal();

  final List<CartItem> _items = [];
  final List<VoidCallback> _listeners = [];

  List<CartItem> get items => List.unmodifiable(_items);

  void addListener(VoidCallback l) => _listeners.add(l);
  void removeListener(VoidCallback l) => _listeners.remove(l);
  void _notify() {
    for (final l in _listeners) l();
  }

  void addItem(CartItem item) {
    final idx = _items.indexWhere((i) => i.id == item.id);
    if (idx >= 0) {
      _items[idx] = CartItem(
        id: item.id,
        name: item.name,
        price: item.price,
        quantity: _items[idx].quantity + item.quantity,
        icon: item.icon,
        imageUrl: _items[idx].imageUrl.isNotEmpty
            ? _items[idx].imageUrl
            : item.imageUrl,
      );
    } else {
      _items.add(item);
    }
    _notify();
  }

  void removeItem(String id) {
    _items.removeWhere((i) => i.id == id);
    _notify();
  }

  void updateQuantity(String id, int qty) {
    final idx = _items.indexWhere((i) => i.id == id);
    if (idx < 0) return;
    if (qty <= 0) {
      _items.removeAt(idx);
    } else {
      _items[idx] = CartItem(
        id: _items[idx].id,
        name: _items[idx].name,
        price: _items[idx].price,
        quantity: qty,
        icon: _items[idx].icon,
        imageUrl: _items[idx].imageUrl,
      );
    }
    _notify();
  }

  void clear() {
    _items.clear();
    _notify();
  }

  double get total => _items.fold(0, (s, i) => s + i.price * i.quantity);
  int get totalCount => _items.fold(0, (s, i) => s + i.quantity);
  int get itemCount => _items.length;
}

// ═══════════════════════════════════════════════════════════════════════════
// MEAL CART BADGE
// ═══════════════════════════════════════════════════════════════════════════

class MealCartBadge extends StatefulWidget {
  const MealCartBadge({super.key});
  @override
  State<MealCartBadge> createState() => _MealCartBadgeState();
}

class _MealCartBadgeState extends State<MealCartBadge> {
  @override
  void initState() {
    super.initState();
    MealCartManager().addListener(_refresh);
  }

  @override
  void dispose() {
    MealCartManager().removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final count = MealCartManager().totalCount;
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const MealCartScreen()),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.shopping_bag_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          if (count > 0)
            Positioned(
              top: -5,
              right: -5,
              child: Container(
                width: 18,
                height: 18,
                decoration: const BoxDecoration(
                  color: AppTheme.accent,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    count > 9 ? '9+' : '$count',
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'Poppins',
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// MEAL CART SCREEN
// ═══════════════════════════════════════════════════════════════════════════

class MealCartScreen extends StatefulWidget {
  const MealCartScreen({super.key});
  @override
  State<MealCartScreen> createState() => _MealCartScreenState();
}

class _MealCartScreenState extends State<MealCartScreen> {
  @override
  void initState() {
    super.initState();
    MealCartManager().addListener(_refresh);
  }

  @override
  void dispose() {
    MealCartManager().removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  void _clearCart() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Clear Cart',
          style: AppTheme.subheading.copyWith(fontSize: 17),
        ),
        content: Text('Remove all meals from your cart?', style: AppTheme.body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(fontFamily: 'Poppins', color: AppTheme.muted),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              MealCartManager().clear();
              Navigator.pop(context);
            },
            child: const Text(
              'Clear',
              style: TextStyle(
                fontFamily: 'Poppins',
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _checkout(double total) {
    final cartItems = MealCartManager().items.toList();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CheckoutScreen(
          total: total,
          cartItems: cartItems, // ← passes the required param
          onOrderPlaced: () {
            MealCartManager().clear();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = MealCartManager().items;
    final total = MealCartManager().total;

    // ── Empty state ────────────────────────────────────────────────────────
    if (items.isEmpty) {
      return Scaffold(
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
            'Meal Cart',
            style: AppTheme.heading.copyWith(fontSize: 20),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  color: AppTheme.accent.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.no_food_rounded,
                  size: 52,
                  color: AppTheme.accent.withOpacity(0.5),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Your meal cart is empty',
                style: AppTheme.subheading.copyWith(fontSize: 18),
              ),
              const SizedBox(height: 8),
              Text(
                'Add meals from our restaurants!',
                style: AppTheme.body.copyWith(fontSize: 14),
              ),
              const SizedBox(height: 28),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 13,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Browse Meals',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ── Filled cart ────────────────────────────────────────────────────────
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ─────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: AppTheme.card(radius: 12),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: AppTheme.primary,
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Meal Cart',
                      style: AppTheme.heading.copyWith(fontSize: 22),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.accent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${items.length} item${items.length > 1 ? 's' : ''}',
                      style: AppTheme.label.copyWith(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _clearCart,
                    child: Text(
                      'Clear',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.red.shade500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Item list ───────────────────────────────────────────────────
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                itemCount: items.length,
                itemBuilder: (_, i) => _MealCartTile(item: items[i]),
              ),
            ),

            // ── Summary + Checkout ──────────────────────────────────────────
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              padding: const EdgeInsets.all(20),
              decoration: AppTheme.card(radius: 22),
              child: Column(
                children: [
                  _summaryRow('Subtotal', '\$${total.toStringAsFixed(2)}'),
                  const SizedBox(height: 8),
                  _summaryRow('Delivery', 'Free', green: true),
                  Divider(height: 22, color: AppTheme.divider),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total',
                        style: AppTheme.subheading.copyWith(fontSize: 16),
                      ),
                      Text(
                        '\$${total.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w800,
                          fontSize: 20,
                          color: AppTheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        elevation: 4,
                        shadowColor: AppTheme.primary.withOpacity(0.35),
                      ),
                      onPressed: () => _checkout(total),
                      child: const Text(
                        'Checkout  →',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool green = false}) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: AppTheme.body.copyWith(fontSize: 14)),
      Text(
        value,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: green ? Colors.green.shade600 : AppTheme.dark,
        ),
      ),
    ],
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// MEAL CART TILE  — shows Image.asset for local meal photos
// ═══════════════════════════════════════════════════════════════════════════

class _MealCartTile extends StatefulWidget {
  final CartItem item;
  const _MealCartTile({required this.item});
  @override
  State<_MealCartTile> createState() => _MealCartTileState();
}

class _MealCartTileState extends State<_MealCartTile> {
  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: AppTheme.card(radius: 18),
      child: Row(
        children: [
          // ── Meal image ──────────────────────────────────────────────────
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: _buildImage(item),
          ),

          const SizedBox(width: 14),

          // ── Name + price ────────────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: AppTheme.subheading.copyWith(fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '\$${item.price.toStringAsFixed(2)} / meal',
                  style: AppTheme.body.copyWith(
                    color: AppTheme.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Subtotal: \$${(item.price * item.quantity).toStringAsFixed(2)}',
                  style: AppTheme.label.copyWith(
                    fontSize: 11,
                    color: AppTheme.muted,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // ── Qty controls ────────────────────────────────────────────────
          Column(
            children: [
              _qtyBtn(
                Icons.add,
                () => MealCartManager().updateQuantity(
                  item.id,
                  item.quantity + 1,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${item.quantity}',
                style: AppTheme.subheading.copyWith(fontSize: 15),
              ),
              const SizedBox(height: 6),
              _qtyBtn(
                Icons.remove,
                () => MealCartManager().updateQuantity(
                  item.id,
                  item.quantity - 1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Local asset path  → Image.asset
  /// http/https URL    → Image.network
  /// empty / fallback  → icon
  Widget _buildImage(CartItem item) {
    const double size = 72;

    if (item.imageUrl.isNotEmpty) {
      if (item.imageUrl.startsWith('http')) {
        return Image.network(
          item.imageUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _iconBox(item, size),
        );
      } else {
        // local asset (e.g. assets/Rest_meals/r1_meals/r1_m1.jpg)
        return Image.asset(
          item.imageUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _iconBox(item, size),
        );
      }
    }

    return _iconBox(item, size);
  }

  Widget _iconBox(CartItem item, double size) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: AppTheme.accent.withOpacity(0.08),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Icon(item.icon, color: AppTheme.primary, size: 30),
  );

  Widget _qtyBtn(IconData icon, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: AppTheme.accent.withOpacity(0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 16, color: AppTheme.primary),
    ),
  );
}
