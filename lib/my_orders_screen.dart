import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'app_theme.dart';
import 'supplement_store_screen.dart';

// ── Order Status ──────────────────────────────────────────────────────────────
enum OrderStatus {
  processing,
  confirmed,
  assigned,
  pickedUp,
  inTransit,
  shipped,
  delivered,
  cancelled,
}

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
  final String firestoreId;
  final DateTime date;
  final double total;
  final List<OrderLineItem> items;
  final OrderStatus status;
  final String address;
  final String payMethod;
  final String phone;
  final String? driverId;
  final String? driverName;
  final double? orderRating;
  final double? driverRating;

  const Order({
    required this.id,
    this.firestoreId = '',
    required this.date,
    required this.total,
    required this.items,
    required this.status,
    required this.address,
    required this.payMethod,
    this.phone = '',
    this.driverId,
    this.driverName,
    this.orderRating,
    this.driverRating,
  });

  static OrderStatus _parseStatus(String s) {
    switch (s) {
      case 'confirmed':
        return OrderStatus.confirmed;
      case 'assigned':
        return OrderStatus.assigned;
      case 'pickedUp':
      case 'picked_up':
        return OrderStatus.pickedUp;
      case 'inTransit':
      case 'in_transit':
        return OrderStatus.inTransit;
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
      orderRating: (data['orderRating'] as num?)?.toDouble(),
      driverRating: (data['driverRating'] as num?)?.toDouble(),
      firestoreId: data['firestoreId'] as String? ?? data['id'] as String? ?? '',
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
                  // Rating icon — tapping opens rate-an-order bottom sheet
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('orders')
                        .doc(user.uid)
                        .collection('userOrders')
                        .orderBy('date', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      final pendingCount = (snapshot.data?.docs ?? []).where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        if ((data['status'] as String? ?? '') != 'delivered') {
                          return false;
                        }
                        final hasDriver =
                            (data['driverId'] as String?)?.isNotEmpty ?? false;
                        final orderRated = data['orderRating'] != null;
                        final driverRated =
                            !hasDriver || data['driverRating'] != null;
                        return !orderRated || !driverRated;
                      }).length;

                      return GestureDetector(
                        onTap: () => _showRatePicker(context, user.uid),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 9,
                          ),
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                color: Colors.amber,
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                pendingCount > 0 ? 'Rate ($pendingCount)' : 'Rate',
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  color: Colors.amber,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
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
                      .map((d) {
                        final data = d.data() as Map<String, dynamic>;
                        data['firestoreId'] = d.id;
                        return Order.fromFirestore(data);
                      })
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

  void _showRatePicker(BuildContext context, String userId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _RateOrderPicker(userId: userId),
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

  bool get _canRateOrder => order.status == OrderStatus.delivered;
  bool get _hasOrderRating => order.orderRating != null;
  bool get _hasDriverRating => order.driverRating != null;
  bool get _hasDriver => (order.driverId ?? '').isNotEmpty;

  void _showRatingSheet(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _RateOrderSheet(userId: user.uid, order: order),
    );
  }

  Color _statusColor(OrderStatus s) {
    switch (s) {
      case OrderStatus.processing:
        return Colors.orange;
      case OrderStatus.confirmed:
        return Colors.blue;
      case OrderStatus.assigned:
        return Colors.indigo;
      case OrderStatus.pickedUp:
        return Colors.deepOrange;
      case OrderStatus.inTransit:
        return AppTheme.accent;
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
      case OrderStatus.assigned:
        return Icons.person_rounded;
      case OrderStatus.pickedUp:
        return Icons.shopping_bag_outlined;
      case OrderStatus.inTransit:
        return Icons.local_shipping_outlined;
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
            if (_hasOrderRating || _hasDriverRating)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: Row(
                  children: [
                    if (_hasOrderRating)
                      _RatingChip(label: 'Order', rating: order.orderRating!),
                    if (_hasOrderRating && _hasDriverRating)
                      const SizedBox(width: 8),
                    if (_hasDriverRating)
                      _RatingChip(label: 'Driver', rating: order.driverRating!),
                  ],
                ),
              ),
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
                  if (_canRateOrder)
                    GestureDetector(
                      onTap: () => _showRatingSheet(context),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: (_hasOrderRating && (!_hasDriver || _hasDriverRating))
                              ? Colors.green.withValues(alpha: 0.12)
                              : Colors.amber.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          (_hasOrderRating && (!_hasDriver || _hasDriverRating))
                              ? 'Rated'
                              : 'Rate',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: (_hasOrderRating && (!_hasDriver || _hasDriverRating))
                                ? Colors.green
                                : Colors.amber.shade800,
                          ),
                        ),
                      ),
                    ),
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
class _RatingChip extends StatelessWidget {
  final String label;
  final double rating;

  const _RatingChip({required this.label, required this.rating});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
          const SizedBox(width: 4),
          Text(
            '$label ${rating.toStringAsFixed(1)}',
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.amber,
            ),
          ),
        ],
      ),
    );
  }
}

class _RateOrderPicker extends StatelessWidget {
  final String userId;

  const _RateOrderPicker({required this.userId});

  bool _needsRating(Map<String, dynamic> data) {
    if ((data['status'] as String? ?? '') != 'delivered') return false;
    final hasDriver = (data['driverId'] as String?)?.isNotEmpty ?? false;
    final orderRated = data['orderRating'] != null;
    final driverRated = !hasDriver || data['driverRating'] != null;
    return !orderRated || !driverRated;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('orders')
              .doc(userId)
              .collection('userOrders')
              .orderBy('date', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            final docs = (snapshot.data?.docs ?? [])
                .where((doc) => _needsRating(doc.data() as Map<String, dynamic>))
                .toList();

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rate your orders',
                  style: AppTheme.subheading.copyWith(fontSize: 18),
                ),
                const SizedBox(height: 6),
                Text(
                  'Choose a delivered order to rate the order and the driver.',
                  style: AppTheme.body.copyWith(fontSize: 13),
                ),
                const SizedBox(height: 16),
                if (snapshot.connectionState == ConnectionState.waiting)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(color: AppTheme.primary),
                    ),
                  )
                else if (docs.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: AppTheme.card(radius: 16),
                    child: Text(
                      'No delivered orders waiting for rating.',
                      style: AppTheme.body.copyWith(fontSize: 13),
                    ),
                  )
                else
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 320),
                    child: SingleChildScrollView(
                      child: Column(
                        children: docs.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          data['firestoreId'] = doc.id;
                          final order = Order.fromFirestore(data);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: GestureDetector(
                              onTap: () {
                                Navigator.pop(context);
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: AppTheme.background,
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(24),
                                    ),
                                  ),
                                  builder: (_) => _RateOrderSheet(
                                    userId: userId,
                                    order: order,
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: AppTheme.card(radius: 16),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 42,
                                      height: 42,
                                      decoration: BoxDecoration(
                                        color: Colors.amber.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.star_rounded,
                                        color: Colors.amber,
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
                                          const SizedBox(height: 4),
                                          Text(
                                            order.items.isNotEmpty
                                                ? order.items.first.name
                                                : 'Delivered order',
                                            style: AppTheme.body.copyWith(fontSize: 12),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(
                                      Icons.chevron_right_rounded,
                                      color: AppTheme.muted,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _RateOrderSheet extends StatefulWidget {
  final String userId;
  final Order order;

  const _RateOrderSheet({required this.userId, required this.order});

  @override
  State<_RateOrderSheet> createState() => _RateOrderSheetState();
}

class _RateOrderSheetState extends State<_RateOrderSheet> {
  int? _orderRating;
  int? _driverRating;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _orderRating = widget.order.orderRating?.round();
    _driverRating = widget.order.driverRating?.round();
  }

  bool get _hasDriver => (widget.order.driverId ?? '').isNotEmpty;

  Future<void> _submit() async {
    if (_orderRating == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please rate the order first.')),
      );
      return;
    }
    if (_hasDriver && _driverRating == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please rate the driver too.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await _OrderRatingService.submit(
        userId: widget.userId,
        order: widget.order,
        orderRating: _orderRating!,
        driverRating: _hasDriver ? _driverRating : null,
      );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rating submitted successfully.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save rating: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 20, 20, 24 + bottomInset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rate Order #${widget.order.id}',
              style: AppTheme.subheading.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 6),
            Text(
              'Your order rating is saved with the order. Driver rating updates the driver score instantly.',
              style: AppTheme.body.copyWith(fontSize: 13),
            ),
            const SizedBox(height: 18),
            Text(
              'Order experience',
              style: AppTheme.subheading.copyWith(fontSize: 14),
            ),
            const SizedBox(height: 10),
            _StarSelector(
              value: _orderRating ?? 0,
              onChanged: widget.order.orderRating == null
                  ? (value) => setState(() => _orderRating = value)
                  : null,
            ),
            if (widget.order.orderRating != null) ...[
              const SizedBox(height: 6),
              Text(
                'This order was already rated.',
                style: AppTheme.body.copyWith(fontSize: 12),
              ),
            ],
            if (_hasDriver) ...[
              const SizedBox(height: 18),
              Text(
                widget.order.driverName?.trim().isNotEmpty == true
                    ? 'Driver: ${widget.order.driverName}'
                    : 'Driver',
                style: AppTheme.subheading.copyWith(fontSize: 14),
              ),
              const SizedBox(height: 10),
              _StarSelector(
                value: _driverRating ?? 0,
                onChanged: widget.order.driverRating == null
                    ? (value) => setState(() => _driverRating = value)
                    : null,
              ),
              if (widget.order.driverRating != null) ...[
                const SizedBox(height: 6),
                Text(
                  'This driver was already rated for this order.',
                  style: AppTheme.body.copyWith(fontSize: 12),
                ),
              ],
            ],
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Submit Rating',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w700,
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

class _StarSelector extends StatelessWidget {
  final int value;
  final ValueChanged<int>? onChanged;

  const _StarSelector({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(5, (index) {
        final starValue = index + 1;
        return GestureDetector(
          onTap: onChanged == null ? null : () => onChanged!(starValue),
          child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Icon(
              starValue <= value ? Icons.star_rounded : Icons.star_border_rounded,
              color: Colors.amber,
              size: 32,
            ),
          ),
        );
      }),
    );
  }
}

class _OrderRatingService {
  static Future<void> submit({
    required String userId,
    required Order order,
    required int orderRating,
    required int? driverRating,
  }) async {
    final db = FirebaseFirestore.instance;
    final userOrderRef = db
        .collection('orders')
        .doc(userId)
        .collection('userOrders')
        .doc(order.firestoreId.isNotEmpty ? order.firestoreId : order.id);
    final deliveryOrderRef = db.collection('deliveryOrders').doc(order.id);
    final hasDriver = (order.driverId ?? '').isNotEmpty;

    await db.runTransaction((transaction) async {
      final userOrderSnap = await transaction.get(userOrderRef);
      if (!userOrderSnap.exists) {
        throw Exception('Order was not found.');
      }

      final currentData = userOrderSnap.data() as Map<String, dynamic>;
      final updates = <String, dynamic>{};

      if (currentData['orderRating'] == null) {
        updates['orderRating'] = orderRating.toDouble();
      }

      if (hasDriver && driverRating != null && currentData['driverRating'] == null) {
        updates['driverRating'] = driverRating.toDouble();

        final driverRef = db.collection('drivers').doc(order.driverId!);
        final driverSnap = await transaction.get(driverRef);
        if (driverSnap.exists) {
          final driverData = driverSnap.data() as Map<String, dynamic>;
          final ratingCount = (driverData['ratingCount'] as num?)?.toInt() ?? 0;
          final totalPoints =
              (driverData['totalRatingPoints'] as num?)?.toDouble() ?? 0.0;
          final newCount = ratingCount + 1;
          final newTotal = totalPoints + driverRating;

          transaction.update(driverRef, {
            'ratingCount': newCount,
            'totalRatingPoints': newTotal,
            'rating': newTotal / newCount,
          });
        }
      }

      if (updates.isEmpty) {
        throw Exception('This order has already been rated.');
      }

      updates['ratedAt'] = FieldValue.serverTimestamp();
      transaction.update(userOrderRef, updates);
      transaction.set(deliveryOrderRef, updates, SetOptions(merge: true));
    });
  }
}

class _StatusBadge extends StatelessWidget {
  final OrderStatus status;
  const _StatusBadge({required this.status});

  String _label(OrderStatus s) {
    switch (s) {
      case OrderStatus.processing:
        return 'Processing';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.assigned:
        return 'Assigned';
      case OrderStatus.pickedUp:
        return 'Picked Up';
      case OrderStatus.inTransit:
        return 'In Transit';
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
      case OrderStatus.assigned:
        return Colors.indigo;
      case OrderStatus.pickedUp:
        return Colors.deepOrange;
      case OrderStatus.inTransit:
        return AppTheme.accent;
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
class _OrderDetailScreen extends StatelessWidget {
  final Order order;
  const _OrderDetailScreen({required this.order});

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

  String _stepLabel(OrderStatus s) {
    switch (s) {
      case OrderStatus.processing:
        return 'Processing';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.assigned:
        return 'Assigned';
      case OrderStatus.pickedUp:
        return 'Picked Up';
      case OrderStatus.inTransit:
        return 'In Transit';
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
      case OrderStatus.assigned:
        return Icons.person_rounded;
      case OrderStatus.pickedUp:
        return Icons.shopping_bag_outlined;
      case OrderStatus.inTransit:
        return Icons.local_shipping_outlined;
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
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppTheme.dark,
          ),
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
            // ── Status tracker ───────────────────────────────────────────────
            _buildTracker(),
            const SizedBox(height: 24),

            // ── Items ────────────────────────────────────────────────────────
            Text('Items', style: AppTheme.subheading.copyWith(fontSize: 15)),
            const SizedBox(height: 10),
            Container(
              decoration: AppTheme.card(radius: 16),
              child: Column(
                children: order.items.map((i) => _ItemRow(item: i)).toList(),
              ),
            ),
            const SizedBox(height: 20),

            // ── Summary ──────────────────────────────────────────────────────
            Text('Summary', style: AppTheme.subheading.copyWith(fontSize: 15)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: AppTheme.card(radius: 16),
              child: Column(
                children: [
                  _infoRow(
                    Icons.location_on_outlined,
                    'Delivery address',
                    order.address,
                  ),
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
                    order.payMethod == 'visa'
                        ? 'Visa card'
                        : 'Cash on delivery',
                  ),
                  const SizedBox(height: 12),
                  _infoRow(
                    Icons.calendar_today_outlined,
                    'Order date',
                    _formatDate(order.date),
                  ),
                  Divider(height: 20, color: AppTheme.divider),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total',
                        style: AppTheme.subheading.copyWith(fontSize: 15),
                      ),
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
          ],
        ),
      ),
    );
  }

  Widget _buildTracker() {
    final steps = [
      OrderStatus.processing,
      OrderStatus.confirmed,
      OrderStatus.assigned,
      OrderStatus.pickedUp,
      OrderStatus.inTransit,
      OrderStatus.delivered,
    ];
    final currentIdx = order.status == OrderStatus.cancelled
        ? -1
        : steps.indexOf(order.status).clamp(0, steps.length - 1);

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
                  child: const Icon(
                    Icons.cancel_outlined,
                    color: Colors.red,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Order cancelled',
                  style: AppTheme.subheading.copyWith(
                    fontSize: 15,
                    color: Colors.red,
                  ),
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
                        color: i ~/ 2 < currentIdx
                            ? AppTheme.primary
                            : AppTheme.divider,
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
              Text(
                label,
                style: AppTheme.body.copyWith(
                  fontSize: 11,
                  color: AppTheme.muted,
                ),
              ),
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
