import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'app_theme.dart';
import 'supplement_store_screen.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// MODEL — represents one purchased product the user can review
// ═══════════════════════════════════════════════════════════════════════════════

class _PurchasedProduct {
  final String supplementId; // Firestore supplement doc ID
  final String name;
  final String imageUrl;
  final String orderId;

  const _PurchasedProduct({
    required this.supplementId,
    required this.name,
    required this.imageUrl,
    required this.orderId,
  });
}

// ═══════════════════════════════════════════════════════════════════════════════
// FEEDBACK SCREEN
// ═══════════════════════════════════════════════════════════════════════════════

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  bool _loading = true;
  List<_PurchasedProduct> _products = [];
  // supplementId → true if already reviewed
  Map<String, bool> _reviewed = {};
  bool _showReviewed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _loading = false);
      return;
    }

    // 1. Load all orders for the user
    final ordersSnap = await FirebaseFirestore.instance
        .collection('orders')
        .doc(user.uid)
        .collection('userOrders')
        .get();

    // 2. Load all supplements for name→id lookup (handles old orders with no id field)
    final supSnap = await FirebaseFirestore.instance
        .collection('supplements')
        .get();
    final nameToId = <String, String>{};
    final nameToImage = <String, String>{};
    for (final doc in supSnap.docs) {
      final d = doc.data();
      final n = (d['name'] as String? ?? '').trim().toLowerCase();
      if (n.isNotEmpty) {
        nameToId[n] = doc.id;
        nameToImage[n] = d['imageUrl'] as String? ?? '';
      }
    }

    // 3. Collect unique purchased supplements
    final Map<String, _PurchasedProduct> uniqueMap = {};
    for (final orderDoc in ordersSnap.docs) {
      final data = orderDoc.data();
      final items =
          (data['items'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      for (final item in items) {
        final name = (item['name'] as String? ?? '').trim();
        if (name.isEmpty) continue;

        // Try stored id first, fall back to name lookup
        String supId = item['id'] as String? ?? '';
        String imageUrl = item['imageUrl'] as String? ?? '';

        if (supId.isEmpty) {
          // Look up by name (case-insensitive)
          final key = name.toLowerCase();
          supId = nameToId[key] ?? '';
          // Also try partial match
          if (supId.isEmpty) {
            for (final entry in nameToId.entries) {
              if (key.contains(entry.key) || entry.key.contains(key)) {
                supId = entry.value;
                if (imageUrl.isEmpty) imageUrl = nameToImage[entry.key] ?? '';
                break;
              }
            }
          }
          if (imageUrl.isEmpty && supId.isNotEmpty) {
            imageUrl = nameToImage[name.toLowerCase()] ?? '';
          }
        }

        // Use name as key if still no id (so it still shows up)
        final mapKey = supId.isNotEmpty ? supId : name;
        if (!uniqueMap.containsKey(mapKey)) {
          uniqueMap[mapKey] = _PurchasedProduct(
            supplementId: supId.isNotEmpty ? supId : mapKey,
            name: name,
            imageUrl: imageUrl,
            orderId: orderDoc.id,
          );
        }
      }
    }

    // 4. Check which ones the user has already reviewed
    final reviewedSnap = await FirebaseFirestore.instance
        .collection('feedback')
        .where('userId', isEqualTo: user.uid)
        .get();

    final reviewed = <String, bool>{};
    for (final doc in reviewedSnap.docs) {
      final sid = doc.data()['supplementId'] as String? ?? '';
      if (sid.isNotEmpty) reviewed[sid] = true;
      // Also mark by productName for old reviews
      final pn = doc.data()['productName'] as String? ?? '';
      if (pn.isNotEmpty) reviewed[pn] = true;
    }

    setState(() {
      _products = uniqueMap.values.toList();
      _reviewed = reviewed;
      _loading = false;
    });
  }

  void _openReviewSheet(_PurchasedProduct product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ReviewSheet(
        product: product,
        onSubmitted: () {
          setState(() => _reviewed[product.supplementId] = true);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppTheme.dark,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Rate Your Products',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: AppTheme.dark,
          ),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            )
          : _products.isEmpty
          ? _buildEmpty(context)
          : _buildList(),
    );
  }

  Widget _buildList() {
    final pending = _products
        .where(
          (p) => !(_reviewed[p.supplementId] ?? _reviewed[p.name] ?? false),
        )
        .toList();
    final done = _products
        .where((p) => (_reviewed[p.supplementId] ?? _reviewed[p.name] ?? false))
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 60),
      children: [
        // ── Banner ──────────────────────────────────────────────────────────
        Container(
          margin: const EdgeInsets.only(bottom: 20),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.primary,
                AppTheme.primary.withValues(alpha: 0.75),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              const Icon(Icons.star_rounded, color: Colors.amber, size: 32),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your feedback matters!',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '${pending.length} product${pending.length == 1 ? '' : 's'} waiting for your review',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // ── Pending reviews ─────────────────────────────────────────────────
        if (pending.isNotEmpty) ...[
          _sectionLabel('Awaiting Your Review', pending.length),
          const SizedBox(height: 10),
          ...pending.map(
            (p) => _ProductCard(
              product: p,
              reviewed: false,
              onTap: () => _openReviewSheet(p),
            ),
          ),
          const SizedBox(height: 24),
        ],

        // ── Completed reviews ───────────────────────────────────────────────
        if (done.isNotEmpty) ...[
          GestureDetector(
            onTap: () => setState(() => _showReviewed = !_showReviewed),
            child: Row(
              children: [
                Text(
                  'Reviewed',
                  style: AppTheme.subheading.copyWith(fontSize: 14),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${done.length}',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.green,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  _showReviewed ? 'Hide' : 'Show',
                  style: AppTheme.body.copyWith(fontSize: 12),
                ),
                const SizedBox(width: 4),
                AnimatedRotation(
                  turns: _showReviewed ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: AppTheme.muted,
                    size: 22,
                  ),
                ),
              ],
            ),
          ),
          if (_showReviewed) ...[
            const SizedBox(height: 10),
            ...done.map(
              (p) => _ProductCard(product: p, reviewed: true, onTap: null),
            ),
          ],
        ],
      ],
    );
  }

  Widget _sectionLabel(String text, int count) {
    return Row(
      children: [
        Text(text, style: AppTheme.subheading.copyWith(fontSize: 14)),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$count',
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppTheme.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: AppTheme.accent.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shopping_bag_outlined,
                color: AppTheme.accent,
                size: 44,
              ),
            ),
            const SizedBox(height: 22),
            Text(
              'No purchases yet',
              style: AppTheme.subheading.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              'Buy supplements to unlock product reviews',
              textAlign: TextAlign.center,
              style: AppTheme.body.copyWith(fontSize: 13),
            ),
            const SizedBox(height: 28),
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SupplementStoreScreen(),
                ),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  'Browse Store',
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
}

// ═══════════════════════════════════════════════════════════════════════════════
// PRODUCT CARD
// ═══════════════════════════════════════════════════════════════════════════════

class _ProductCard extends StatelessWidget {
  final _PurchasedProduct product;
  final bool reviewed;
  final VoidCallback? onTap;

  const _ProductCard({
    required this.product,
    required this.reviewed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: reviewed ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: reviewed
                ? Colors.green.withValues(alpha: 0.3)
                : AppTheme.divider,
            width: reviewed ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withValues(alpha: 0.06),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Product image — handles assets/ and https:// URLs
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _buildImage(),
            ),
            const SizedBox(width: 14),

            // Name
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: AppTheme.subheading.copyWith(fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (reviewed)
                    Row(
                      children: const [
                        Icon(
                          Icons.check_circle_rounded,
                          color: Colors.green,
                          size: 14,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Reviewed',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            color: Colors.green,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    )
                  else
                    Text(
                      'Tap to leave a review',
                      style: AppTheme.body.copyWith(fontSize: 11),
                    ),
                ],
              ),
            ),

            // CTA
            if (!reviewed)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.star_outline_rounded,
                  color: AppTheme.primary,
                  size: 22,
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.green,
                  size: 22,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    final url = product.imageUrl;
    if (url.isEmpty) return _fallbackIcon();
    if (url.startsWith('assets/')) {
      return Image.asset(
        url,
        width: 60,
        height: 60,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallbackIcon(),
      );
    }
    return Image.network(
      url,
      width: 60,
      height: 60,
      fit: BoxFit.cover,
      loadingBuilder: (_, child, prog) => prog == null
          ? child
          : Container(
              width: 60,
              height: 60,
              color: AppTheme.accent.withValues(alpha: 0.08),
              child: const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppTheme.accent,
                ),
              ),
            ),
      errorBuilder: (_, __, ___) => _fallbackIcon(),
    );
  }

  Widget _fallbackIcon() => Container(
    width: 60,
    height: 60,
    decoration: BoxDecoration(
      color: AppTheme.accent.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(12),
    ),
    child: const Icon(Icons.science_rounded, color: AppTheme.accent, size: 28),
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
// REVIEW BOTTOM SHEET
// ═══════════════════════════════════════════════════════════════════════════════

class _ReviewSheet extends StatefulWidget {
  final _PurchasedProduct product;
  final VoidCallback onSubmitted;

  const _ReviewSheet({required this.product, required this.onSubmitted});

  @override
  State<_ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends State<_ReviewSheet> {
  int _rating = 0;
  final _commentCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Please select a star rating',
            style: TextStyle(fontFamily: 'Poppins'),
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    setState(() => _submitting = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Fetch the user's display name from Firestore users collection
    String userName = user.displayName ?? '';
    if (userName.isEmpty) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      userName = userDoc.data()?['name'] as String? ?? '';
    }

    try {
      // Check once more server-side to prevent double submit (race condition)
      final existing = await FirebaseFirestore.instance
          .collection('feedback')
          .where('userId', isEqualTo: user.uid)
          .where('supplementId', isEqualTo: widget.product.supplementId)
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'You have already reviewed this product.',
                style: TextStyle(fontFamily: 'Poppins'),
              ),
              backgroundColor: AppTheme.primary,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
        return;
      }

      // Write to feedback collection
      await FirebaseFirestore.instance.collection('feedback').add({
        'userId': user.uid,
        'userEmail': user.email ?? '',
        'userName': userName,
        'supplementId': widget.product.supplementId,
        'productName': widget.product.name,
        'imageUrl': widget.product.imageUrl,
        'rating': _rating,
        'comment': _commentCtrl.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'type': 'supplement',
      });

      // Also update the supplement's average rating in Firestore
      // (optional but keeps product ratings live)
      _updateSupplementRating(widget.product.supplementId);

      if (mounted) {
        Navigator.pop(context);
        widget.onSubmitted();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                SizedBox(width: 10),
                Text(
                  'Review submitted — thank you!',
                  style: TextStyle(fontFamily: 'Poppins'),
                ),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Something went wrong. Please try again.',
              style: TextStyle(fontFamily: 'Poppins'),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  /// Recalculates and updates the average rating on the supplement document.
  Future<void> _updateSupplementRating(String supplementId) async {
    try {
      final allReviews = await FirebaseFirestore.instance
          .collection('feedback')
          .where('supplementId', isEqualTo: supplementId)
          .get();
      if (allReviews.docs.isEmpty) return;
      final total = allReviews.docs.fold<double>(
        0,
        (sum, d) => sum + ((d.data()['rating'] as num?)?.toDouble() ?? 0),
      );
      final avg = total / allReviews.docs.length;
      await FirebaseFirestore.instance
          .collection('supplements')
          .doc(supplementId)
          .update({'rating': double.parse(avg.toStringAsFixed(1))});
    } catch (_) {
      // Non-critical — ignore silently
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      maxChildSize: 0.92,
      minChildSize: 0.5,
      builder: (_, scroll) => Container(
        decoration: const BoxDecoration(
          color: AppTheme.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: ListView(
          controller: scroll,
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
          children: [
            // Drag handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 20),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.divider,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            // Product row
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: _buildSheetImage(),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Review',
                        style: AppTheme.body.copyWith(fontSize: 12),
                      ),
                      Text(
                        widget.product.name,
                        style: AppTheme.subheading.copyWith(fontSize: 16),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Star rating picker
            Text(
              'How would you rate it?',
              style: AppTheme.subheading.copyWith(fontSize: 14),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                final filled = i < _rating;
                return GestureDetector(
                  onTap: () => setState(() => _rating = i + 1),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.all(6),
                    child: Icon(
                      filled ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: filled ? Colors.amber : AppTheme.divider,
                      size: 44,
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                _rating == 0 ? 'Tap a star to rate' : _ratingLabel(_rating),
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _rating == 0 ? AppTheme.muted : _ratingColor(_rating),
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Comment field
            Text(
              'Tell us more (optional)',
              style: AppTheme.subheading.copyWith(fontSize: 14),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.divider),
              ),
              child: TextField(
                controller: _commentCtrl,
                maxLines: 4,
                maxLength: 300,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  color: AppTheme.dark,
                ),
                decoration: InputDecoration(
                  hintText: 'Share your experience with this product...',
                  hintStyle: AppTheme.body.copyWith(fontSize: 13),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                  counterStyle: AppTheme.body.copyWith(fontSize: 11),
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Submit button
            GestureDetector(
              onTap: _submitting ? null : _submit,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: _submitting
                      ? AppTheme.primary.withValues(alpha: 0.5)
                      : AppTheme.primary,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: _submitting
                      ? []
                      : [
                          BoxShadow(
                            color: AppTheme.primary.withValues(alpha: 0.35),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                        ],
                ),
                child: Center(
                  child: _submitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.send_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Submit Review',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSheetImage() {
    final url = widget.product.imageUrl;
    if (url.isEmpty) return _icon();
    if (url.startsWith('assets/')) {
      return Image.asset(
        url,
        width: 72,
        height: 72,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _icon(),
      );
    }
    return Image.network(
      url,
      width: 72,
      height: 72,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _icon(),
    );
  }

  Widget _icon() => Container(
    width: 72,
    height: 72,
    decoration: BoxDecoration(
      color: AppTheme.accent.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(14),
    ),
    child: const Icon(Icons.science_rounded, color: AppTheme.accent, size: 32),
  );

  String _ratingLabel(int r) {
    switch (r) {
      case 1:
        return 'Poor';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Great';
      case 5:
        return 'Excellent!';
      default:
        return '';
    }
  }

  Color _ratingColor(int r) {
    switch (r) {
      case 1:
        return Colors.red;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.amber.shade700;
      case 4:
        return Colors.lightGreen.shade700;
      case 5:
        return Colors.green.shade700;
      default:
        return AppTheme.muted;
    }
  }
}
