import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'app_theme.dart';
import 'supplement_store_screen.dart';

// ── Order Status ──────────────────────────────────────────────────────────────
enum OrderStatus { processing, confirmed, shipped, delivered, cancelled }

// ── Order Line Item ───────────────────────────────────────────────────────────
class OrderLineItem {
  final String name;
  final int qty;
  final double price;
  final String imageUrl;
  const OrderLineItem({
    required this.name,
    required this.qty,
    required this.price,
    this.imageUrl = '',
  });
}

// ── Order ─────────────────────────────────────────────────────────────────────
class Order {
  final String id;
  final DateTime date;
  final double total;
  final List<OrderLineItem> items;
  final OrderStatus status;
  final String address;
  final String payMethod;
  final String phone;
  final String? driverId;
  final String? driverName;

  const Order({
    required this.id,
    required this.date,
    required this.total,
    required this.items,
    required this.status,
    required this.address,
    required this.payMethod,
    this.phone = '',
    this.driverId,
    this.driverName,
  });

  bool get hasDriver => driverId != null && driverId!.isNotEmpty;

  static OrderStatus _parseStatus(String s) {
    switch (s) {
      case 'confirmed':
        return OrderStatus.confirmed;
      case 'shipped':
        return OrderStatus.shipped;
      case 'delivered':
        return OrderStatus.delivered;
      case 'cancelled':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.processing;
    }
  }

  factory Order.fromFirestore(Map<String, dynamic> data) {
    final rawItems = data['items'] as List<dynamic>? ?? [];
    return Order(
      id: data['id'] as String? ?? '',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      total: (data['total'] as num?)?.toDouble() ?? 0,
      status: _parseStatus(data['status'] as String? ?? 'processing'),
      address: data['address'] as String? ?? '',
      payMethod: data['payMethod'] as String? ?? 'cod',
      phone: data['phone'] as String? ?? '',
      driverId: data['driverId'] as String?,
      driverName: data['driverName'] as String?,
      items: rawItems.map((e) {
        final m = e as Map<String, dynamic>;
        return OrderLineItem(
          name: m['name'] as String? ?? '',
          qty: (m['qty'] as num?)?.toInt() ?? 1,
          price: (m['price'] as num?)?.toDouble() ?? 0,
          imageUrl: m['imageUrl'] as String? ?? '',
        );
      }).toList(),
    );
  }
}

// ── Local session cache ───────────────────────────────────────────────────────
class OrderManager {
  static final OrderManager _instance = OrderManager._internal();
  factory OrderManager() => _instance;
  OrderManager._internal();

  final List<Order> _orders = [];
  final List<VoidCallback> _listeners = [];

  List<Order> get orders => List.unmodifiable(_orders.reversed.toList());
  void addListener(VoidCallback l) => _listeners.add(l);
  void removeListener(VoidCallback l) => _listeners.remove(l);
  void _notify() {
    for (final l in _listeners) {
      l();
    }
  }

  void placeOrder(Order o) {
    _orders.add(o);
    _notify();
  }
}

// ── My Orders Screen ──────────────────────────────────────────────────────────
class MyOrdersScreen extends StatelessWidget {
  const MyOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(child: Text('Please log in.', style: AppTheme.body)),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'My Orders',
                      style: AppTheme.heading.copyWith(fontSize: 24),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SupplementStoreScreen(),
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: const [
                          Icon(
                            Icons.storefront_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Shop',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Stream from Firestore ────────────────────────────────────────
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('orders')
                    .doc(user.uid)
                    .collection('userOrders')
                    .orderBy('date', descending: true)
                    .snapshots(),
                builder: (ctx, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppTheme.primary),
                    );
                  }
                  if (snap.hasError) {
                    return Center(
                      child: Text(
                        'Error loading orders.',
                        style: AppTheme.body,
                      ),
                    );
                  }
                  final docs = snap.data?.docs ?? [];

                  // Exclude consultation bookings — they belong in My Bookings only
                  final orders = docs
                      .where((d) {
                        final items =
                            (d.data() as Map<String, dynamic>)['items']
                                as List<dynamic>? ??
                            [];
                        return !items.any(
                          (i) => ((i as Map)['name'] as String? ?? '')
                              .startsWith('Consultation:'),
                        );
                      })
                      .map(
                        (d) => Order.fromFirestore(
                          d.data() as Map<String, dynamic>,
                        ),
                      )
                      .toList();

                  if (orders.isEmpty) return _buildEmpty(context);

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                    itemCount: orders.length,
                    itemBuilder: (_, i) => _OrderCard(order: orders[i]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: AppTheme.accent.withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.receipt_long_outlined,
            size: 48,
            color: AppTheme.primary.withValues(alpha: 0.4),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'No orders yet',
          style: AppTheme.subheading.copyWith(fontSize: 18),
        ),
        const SizedBox(height: 8),
        Text(
          'Your supplement orders will appear here',
          style: AppTheme.body.copyWith(fontSize: 13, color: AppTheme.muted),
        ),
        const SizedBox(height: 28),
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SupplementStoreScreen()),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
            decoration: BoxDecoration(
              color: AppTheme.primary,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Text(
              'Browse Supplements',
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
  );
}

// ── Order Card ────────────────────────────────────────────────────────────────
class _OrderCard extends StatelessWidget {
  final Order order;
  const _OrderCard({required this.order});

  Color _statusColor(OrderStatus s) {
    switch (s) {
      case OrderStatus.processing:
        return Colors.orange;
      case OrderStatus.confirmed:
        return Colors.blue;
      case OrderStatus.shipped:
        return Colors.purple;
      case OrderStatus.delivered:
        return Colors.green;
      case OrderStatus.cancelled:
        return Colors.red;
    }
  }

  IconData _statusIcon(OrderStatus s) {
    switch (s) {
      case OrderStatus.processing:
        return Icons.hourglass_top_rounded;
      case OrderStatus.confirmed:
        return Icons.check_circle_outline_rounded;
      case OrderStatus.shipped:
        return Icons.local_shipping_outlined;
      case OrderStatus.delivered:
        return Icons.done_all_rounded;
      case OrderStatus.cancelled:
        return Icons.cancel_outlined;
    }
  }

  String _formatDate(DateTime d) {
    const m = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${m[d.month - 1]} ${d.day}, ${d.year}  '
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => _OrderDetailScreen(order: order)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: AppTheme.card(radius: 18),
        child: Column(
          children: [
            // ── Top ─────────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _statusColor(order.status).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _statusIcon(order.status),
                      color: _statusColor(order.status),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order #${order.id}',
                          style: AppTheme.subheading.copyWith(fontSize: 14),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatDate(order.date),
                          style: AppTheme.body.copyWith(
                            fontSize: 12,
                            color: AppTheme.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _StatusBadge(status: order.status),
                ],
              ),
            ),

            Divider(height: 1, color: AppTheme.divider),

            // ── Items preview ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: Column(
                children: [
                  ...order.items
                      .take(2)
                      .map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              Text(
                                '${item.qty}×',
                                style: AppTheme.body.copyWith(
                                  fontSize: 12,
                                  color: AppTheme.muted,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  item.name,
                                  style: AppTheme.body.copyWith(fontSize: 12),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                '${(item.price * item.qty).toStringAsFixed(2)} JD',
                                style: AppTheme.body.copyWith(
                                  fontSize: 12,
                                  color: AppTheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  if (order.items.length > 2)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '+${order.items.length - 2} more item'
                        '${order.items.length - 2 == 1 ? '' : 's'}',
                        style: AppTheme.body.copyWith(
                          fontSize: 11,
                          color: AppTheme.muted,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            Divider(height: 1, color: AppTheme.divider),

            // ── Bottom ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 12, 12),
              child: Row(
                children: [
                  Icon(
                    order.payMethod == 'visa'
                        ? Icons.credit_card_rounded
                        : Icons.payments_outlined,
                    size: 15,
                    color: AppTheme.muted,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    order.payMethod == 'visa' ? 'Visa' : 'Cash on Delivery',
                    style: AppTheme.body.copyWith(
                      fontSize: 12,
                      color: AppTheme.muted,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${order.total.toStringAsFixed(2)} JD',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: AppTheme.muted,
                    size: 20,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Status Badge ──────────────────────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final OrderStatus status;
  const _StatusBadge({required this.status});

  String _label(OrderStatus s) {
    switch (s) {
      case OrderStatus.processing:
        return 'Processing';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.shipped:
        return 'Shipped';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  Color _color(OrderStatus s) {
    switch (s) {
      case OrderStatus.processing:
        return Colors.orange;
      case OrderStatus.confirmed:
        return Colors.blue;
      case OrderStatus.shipped:
        return Colors.purple;
      case OrderStatus.delivered:
        return Colors.green;
      case OrderStatus.cancelled:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _color(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.withValues(alpha: 0.3)),
      ),
      child: Text(
        _label(status),
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: c,
        ),
      ),
    );
  }
}

// ── Order Detail Screen ───────────────────────────────────────────────────────
class _OrderDetailScreen extends StatefulWidget {
  final Order order;
  const _OrderDetailScreen({required this.order});

  @override
  State<_OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<_OrderDetailScreen> {
  Order get order => widget.order;

  Map<String, int> _ratings = {};
  int _driverRating = 0;
  bool _alreadyRated = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (order.status == OrderStatus.delivered) _loadExistingRatings();
  }

  Future<void> _loadExistingRatings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('orders')
          .doc(user.uid)
          .collection('userOrders')
          .doc(order.id)
          .get();
      final data = doc.data();
      if (data == null) return;
      final raw = data['itemRatings'] as Map<String, dynamic>?;
      if (raw != null && raw.isNotEmpty) {
        setState(() {
          _ratings = raw.map((k, v) => MapEntry(k, (v as num).toInt()));
          _driverRating = (data['driverRating'] as num?)?.toInt() ?? 0;
          _alreadyRated = true;
        });
      }
    } catch (_) {}
  }

  Future<void> _submitRatings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    setState(() => _isSubmitting = true);
    try {
      final db = FirebaseFirestore.instance;
      final orderRef = db
          .collection('orders')
          .doc(user.uid)
          .collection('userOrders')
          .doc(order.id);

      final updates = <String, dynamic>{'itemRatings': _ratings};
      if (order.hasDriver && _driverRating > 0) {
        updates['driverRating'] = _driverRating;
      }

      await orderRef.update(updates);

      // Update driver aggregate rating in a transaction
      if (order.hasDriver && _driverRating > 0) {
        final driverRef = db.collection('drivers').doc(order.driverId);
        await db.runTransaction((tx) async {
          final snap = await tx.get(driverRef);
          if (!snap.exists) return;
          final d = snap.data()!;
          final count = (d['ratingCount'] as num?)?.toInt() ?? 0;
          final total = (d['totalRatingPoints'] as num?)?.toDouble() ?? 0.0;
          final newCount = count + 1;
          final newTotal = total + _driverRating;
          tx.update(driverRef, {
            'ratingCount': newCount,
            'totalRatingPoints': newTotal,
            'rating': newTotal / newCount,
          });
        });
      }

      setState(() => _alreadyRated = true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thanks for your rating!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String _formatDate(DateTime d) {
    const m = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${m[d.month - 1]} ${d.day}, ${d.year}  '
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  String _stepLabel(OrderStatus s) {
    switch (s) {
      case OrderStatus.processing:
        return 'Processing';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.shipped:
        return 'Shipped';
      case OrderStatus.delivered:
        return 'Delivered';
      default:
        return '';
    }
  }

  IconData _stepIcon(OrderStatus s) {
    switch (s) {
      case OrderStatus.processing:
        return Icons.hourglass_top_rounded;
      case OrderStatus.confirmed:
        return Icons.check_rounded;
      case OrderStatus.shipped:
        return Icons.local_shipping_outlined;
      case OrderStatus.delivered:
        return Icons.done_all_rounded;
      default:
        return Icons.circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.dark),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Order #${order.id}',
          style: AppTheme.subheading.copyWith(fontSize: 17),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTracker(),
            const SizedBox(height: 24),

            Text('Items', style: AppTheme.subheading.copyWith(fontSize: 15)),
            const SizedBox(height: 10),
            Container(
              decoration: AppTheme.card(radius: 16),
              child: Column(
                children: order.items.map((i) => _ItemRow(item: i)).toList(),
              ),
            ),
            const SizedBox(height: 20),

            Text('Summary', style: AppTheme.subheading.copyWith(fontSize: 15)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: AppTheme.card(radius: 16),
              child: Column(
                children: [
                  _infoRow(Icons.location_on_outlined, 'Delivery address', order.address),
                  const SizedBox(height: 12),
                  if (order.phone.isNotEmpty) ...[
                    _infoRow(Icons.phone_outlined, 'Phone', order.phone),
                    const SizedBox(height: 12),
                  ],
                  _infoRow(
                    order.payMethod == 'visa'
                        ? Icons.credit_card_rounded
                        : Icons.payments_outlined,
                    'Payment',
                    order.payMethod == 'visa' ? 'Visa card' : 'Cash on delivery',
                  ),
                  const SizedBox(height: 12),
                  _infoRow(Icons.calendar_today_outlined, 'Order date', _formatDate(order.date)),
                  Divider(height: 20, color: AppTheme.divider),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total', style: AppTheme.subheading.copyWith(fontSize: 15)),
                      Text(
                        '${order.total.toStringAsFixed(2)} JD',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                          color: AppTheme.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Rating section (delivered orders only) ───────────────────────
            if (order.status == OrderStatus.delivered) _buildRatingSection(),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingSection() {
    final allItemsRated = _ratings.length == order.items.length;
    final driverRatingDone = !order.hasDriver || _driverRating > 0;
    final allRated = allItemsRated && driverRatingDone;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Row(
          children: [
            Text('Rate Your Order', style: AppTheme.subheading.copyWith(fontSize: 15)),
            const SizedBox(width: 8),
            if (_alreadyRated)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Rated',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.green,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: AppTheme.card(radius: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...order.items.asMap().entries.map((e) => _buildItemRatingRow(e.key, e.value)),
              if (order.hasDriver) _buildDriverRatingRow(),
              if (!_alreadyRated) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: allRated && !_isSubmitting ? _submitRatings : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      disabledBackgroundColor: AppTheme.primary.withValues(alpha: 0.3),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Submit Rating',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ] else ...[
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle_rounded, color: Colors.green, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'Thank you for your feedback!',
                      style: AppTheme.body.copyWith(fontSize: 13, color: Colors.green),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildItemRatingRow(int index, OrderLineItem item) {
    final key = '$index';
    final rating = _ratings[key] ?? 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.name,
            style: AppTheme.body.copyWith(fontSize: 13, fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Row(
            children: List.generate(5, (i) {
              final star = i + 1;
              return GestureDetector(
                onTap: _alreadyRated
                    ? null
                    : () => setState(() => _ratings[key] = star),
                child: Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Icon(
                    star <= rating ? Icons.star_rounded : Icons.star_border_rounded,
                    color: star <= rating ? Colors.amber : AppTheme.muted,
                    size: 30,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildDriverRatingRow() {
    final label = (order.driverName?.trim().isNotEmpty == true)
        ? 'Driver — ${order.driverName}'
        : 'Driver';

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 20, color: AppTheme.divider),
          Row(
            children: [
              const Icon(Icons.delivery_dining, size: 16, color: AppTheme.primary),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTheme.body.copyWith(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: List.generate(5, (i) {
              final star = i + 1;
              return GestureDetector(
                onTap: _alreadyRated
                    ? null
                    : () => setState(() => _driverRating = star),
                child: Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Icon(
                    star <= _driverRating
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    color: star <= _driverRating ? Colors.amber : AppTheme.muted,
                    size: 30,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildTracker() {
    final steps = [
      OrderStatus.processing,
      OrderStatus.confirmed,
      OrderStatus.shipped,
      OrderStatus.delivered,
    ];
    final currentIdx = order.status == OrderStatus.cancelled
        ? -1
        : steps.indexOf(order.status);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.card(radius: 16),
      child: order.status == OrderStatus.cancelled
          ? Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.cancel_outlined, color: Colors.red, size: 22),
                ),
                const SizedBox(width: 12),
                Text(
                  'Order cancelled',
                  style: AppTheme.subheading.copyWith(fontSize: 15, color: Colors.red),
                ),
              ],
            )
          : Row(
              children: List.generate(steps.length * 2 - 1, (i) {
                if (i.isOdd) {
                  return Expanded(
                    child: Container(
                      height: 3,
                      decoration: BoxDecoration(
                        color: i ~/ 2 < currentIdx ? AppTheme.primary : AppTheme.divider,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }
                final idx = i ~/ 2;
                final done = idx <= currentIdx;
                return Column(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: done ? AppTheme.primary : AppTheme.divider,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _stepIcon(steps[idx]),
                        size: 16,
                        color: done ? Colors.white : AppTheme.muted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _stepLabel(steps[idx]),
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 9,
                        color: done ? AppTheme.primary : AppTheme.muted,
                        fontWeight: done ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ],
                );
              }),
            ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 2),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppTheme.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTheme.body.copyWith(fontSize: 11, color: AppTheme.muted)),
              const SizedBox(height: 2),
              Text(value, style: AppTheme.body.copyWith(fontSize: 13)),
            ],
          ),
        ),
      ],
    ),
  );
}

// ── Item Row ──────────────────────────────────────────────────────────────────
class _ItemRow extends StatelessWidget {
  final OrderLineItem item;
  const _ItemRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.divider, width: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.science_rounded,
              color: AppTheme.primary,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              item.name,
              style: AppTheme.body.copyWith(fontSize: 13),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${item.qty}× ${item.price.toStringAsFixed(2)} JD',
            style: AppTheme.body.copyWith(
              fontSize: 12,
              color: AppTheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
