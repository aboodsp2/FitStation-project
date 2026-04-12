import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'dashboard_screen.dart';
import 'supplement_models.dart';
import 'supplement_store_screen.dart';
import 'checkout_screen.dart';
import 'auth_screen.dart' show GuestManager;
import 'guest_preview_screen.dart' show showGuestSignupSheet;

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});
  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _promoCtrl = TextEditingController();
  bool _promoApplied = false;
  bool _promoError = false;
  static const _validCode = 'fit20';
  static const _discount = 0.20;

  @override
  void initState() {
    super.initState();
    CartManager().addListener(_onCartChanged);
  }

  @override
  void dispose() {
    CartManager().removeListener(_onCartChanged);
    _promoCtrl.dispose();
    super.dispose();
  }

  void _onCartChanged() {
    if (mounted) setState(() {});
  }

  void _applyPromo() {
    final code = _promoCtrl.text.trim().toLowerCase();
    if (code == _validCode) {
      setState(() {
        _promoApplied = true;
        _promoError = false;
      });
      FocusScope.of(context).unfocus();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            "🎉 20% discount applied!",
            style: TextStyle(fontFamily: 'Poppins'),
          ),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } else {
      setState(() {
        _promoApplied = false;
        _promoError = true;
      });
    }
  }

  void _clearCart() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "Clear Cart",
          style: AppTheme.subheading.copyWith(fontSize: 17),
        ),
        content: Text("Remove all items from your cart?", style: AppTheme.body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Cancel",
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
              final ids = CartManager().items.map((i) => i.id).toList();
              for (final id in ids) {
                CartManager().removeItem(id);
              }
              setState(() {
                _promoApplied = false;
                _promoError = false;
                _promoCtrl.clear();
              });
              Navigator.pop(context);
            },
            child: const Text(
              "Clear",
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

  void _checkout(double finalTotal) {
    if (GuestManager().isGuest) {
      showGuestSignupSheet(context);
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CheckoutScreen(
          total: finalTotal,
          cartItems: List.from(CartManager().items),
          onOrderPlaced: () {
            final ids = CartManager().items.map((i) => i.id).toList();
            for (final id in ids) {
              CartManager().removeItem(id);
            }
            setState(() {
              _promoApplied = false;
              _promoCtrl.clear();
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = CartManager().items;
    final subtotal = CartManager().total;
    final discount = _promoApplied ? subtotal * _discount : 0.0;
    final total = subtotal - discount;

    // ── Empty state ──────────────────────────────────────────────────────────
    if (items.isEmpty) {
      return Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: AppTheme.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.shopping_cart_outlined,
                size: 80,
                color: AppTheme.divider,
              ),
              const SizedBox(height: 20),
              Text(
                "Your cart is empty",
                style: AppTheme.body.copyWith(fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                "Add something from the store!",
                style: AppTheme.label.copyWith(fontSize: 13),
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SupplementStoreScreen(),
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    "Go to Store",
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

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ────────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  // back to store
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SupplementStoreScreen(),
                      ),
                    ),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: AppTheme.card(radius: 12),
                      child: Icon(
                        Icons.storefront_rounded,
                        color: AppTheme.primary,
                        size: 19,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "My Cart",
                      style: AppTheme.heading.copyWith(fontSize: 22),
                    ),
                  ),
                  // item count
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "${items.length} item${items.length > 1 ? 's' : ''}",
                      style: AppTheme.label.copyWith(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // clear — text button, no filled box
                  GestureDetector(
                    onTap: _clearCart,
                    child: Text(
                      "Clear",
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

            // ── Items ──────────────────────────────────────────────────────────
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                itemCount: items.length,
                itemBuilder: (_, i) => _CartItemTile(item: items[i]),
              ),
            ),

            const SizedBox(height: 8),

            // ── Summary + Promo + Checkout ──────────────────────────────────────
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              padding: const EdgeInsets.all(20),
              decoration: AppTheme.card(radius: 22),
              child: Column(
                children: [
                  // promo row
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.background,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.divider),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.local_offer_outlined,
                          color: _promoApplied
                              ? Colors.green.shade600
                              : AppTheme.accent,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _promoCtrl,
                            enabled: !_promoApplied,
                            textCapitalization: TextCapitalization.characters,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: InputDecoration(
                              hintText: _promoApplied
                                  ? "FIT20 applied ✓"
                                  : "Enter promo code",
                              hintStyle: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 13,
                                color: _promoApplied
                                    ? Colors.green.shade600
                                    : AppTheme.muted,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              errorText: _promoError
                                  ? "Invalid — try FIT20"
                                  : null,
                              errorStyle: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 11,
                              ),
                            ),
                            onSubmitted: (_) => _applyPromo(),
                          ),
                        ),
                        const SizedBox(width: 6),
                        _promoApplied
                            ? GestureDetector(
                                onTap: () => setState(() {
                                  _promoApplied = false;
                                  _promoCtrl.clear();
                                }),
                                child: const Icon(
                                  Icons.close_rounded,
                                  color: AppTheme.muted,
                                  size: 20,
                                ),
                              )
                            : GestureDetector(
                                onTap: _applyPromo,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primary,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    "Apply",
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _row("Subtotal", "${subtotal.toStringAsFixed(2)} JD"),
                  const SizedBox(height: 8),
                  _row("Shipping", "Free", green: true),
                  if (_promoApplied) ...[
                    const SizedBox(height: 8),
                    _row(
                      "Promo (FIT20 -20%)",
                      "-${discount.toStringAsFixed(2)} JD",
                      green: true,
                    ),
                  ],
                  Divider(height: 22, color: AppTheme.divider),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Total",
                        style: AppTheme.subheading.copyWith(fontSize: 16),
                      ),
                      Text(
                        "${total.toStringAsFixed(2)} JD",
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
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
                        shadowColor: AppTheme.primary.withValues(alpha: 0.35),
                      ),
                      onPressed: () => _checkout(total),
                      child: const Text(
                        "Checkout  →",
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
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value, {bool green = false}) => Row(
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

// ── Cart item tile ────────────────────────────────────────────────────────────
class _CartItemTile extends StatefulWidget {
  final CartItem item;
  const _CartItemTile({required this.item});
  @override
  State<_CartItemTile> createState() => _CartItemTileState();
}

class _CartItemTileState extends State<_CartItemTile> {
  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: AppTheme.card(radius: 18),
      child: Row(
        children: [
          // product image
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: AppTheme.accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: item.imageUrl.isNotEmpty
                  ? SupplementImage(
                      imageUrl: item.imageUrl,
                      size: 46,
                      fit: BoxFit.contain,
                    )
                  : Icon(item.icon, color: AppTheme.primary, size: 26),
            ),
          ),
          const SizedBox(width: 12),
          // name + price
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
                const SizedBox(height: 3),
                Text(
                  "${item.price.toStringAsFixed(2)} JD",
                  style: AppTheme.body.copyWith(
                    color: AppTheme.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          // qty controls
          Row(
            children: [
              _qtyBtn(
                Icons.remove,
                () => CartManager().updateQuantity(item.id, item.quantity - 1),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  "${item.quantity}",
                  style: AppTheme.subheading.copyWith(fontSize: 15),
                ),
              ),
              _qtyBtn(
                Icons.add,
                () => CartManager().updateQuantity(item.id, item.quantity + 1),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: AppTheme.accent.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 16, color: AppTheme.primary),
    ),
  );
}
