import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'app_theme.dart';
import 'supplement_store_screen.dart';
import 'feedback_screen.dart';

// ── Order Status ──────────────────────────────────────────────────────────────
enum OrderStatus {
  processing,
  confirmed,
  assigned, // NEW - Driver assigned
  pickedUp, // NEW - Driver picked up order
  inTransit, // NEW - Driver is delivering
  shipped, // Keep existing
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
  final DateTime date;
  final double total;
  final List<OrderLineItem> items;
  final OrderStatus status;
  final String address;
  final String payMethod;
  final String phone;
  final String? driverId;

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
  });

  static OrderStatus _parseStatus(String s) {
    switch (s) {
      case 'confirmed':
        return OrderStatus.confirmed;
      case 'assigned': // NEW
        return OrderStatus.assigned;
      case 'pickedUp': // NEW
      case 'picked_up': // NEW
        return OrderStatus.pickedUp;
      case 'inTransit': // NEW
      case 'in_transit': // NEW
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
                  Row(
                    children: [
                      // ── Rate button ─────────────────────────────────────
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const FeedbackScreen(),
                          ),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 13,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.amber.withValues(alpha: 0.4),
                            ),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.star_rounded,
                                color: Colors.amber,
                                size: 16,
                              ),
                              SizedBox(width: 5),
                              Text(
                                'Rate',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  color: Colors.amber,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // ── Shop button ─────────────────────────────────────
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SupplementStoreScreen(),
                          ),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 13,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primary,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Row(
                            children: [
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
                  if (docs.isEmpty) return _buildEmpty(context);

                  final orders = docs
                      .map(
                        (d) => Order.fromFirestore(
                          d.data() as Map<String, dynamic>,
                        ),
                      )
                      .toList();

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

  Color _statusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.delivered:
        return Colors.green;
      case OrderStatus.cancelled:
        return Colors.red;
      case OrderStatus.confirmed:
        return Colors.blue;
      case OrderStatus.assigned:
      case OrderStatus.pickedUp:
      case OrderStatus.inTransit:
      case OrderStatus.shipped:
        return Colors.indigo;
      case OrderStatus.processing:
        return Colors.orange;
    }
  }

  IconData _statusIcon(OrderStatus status) {
    switch (status) {
      case OrderStatus.delivered:
        return Icons.check_circle_rounded;
      case OrderStatus.cancelled:
        return Icons.cancel_outlined;
      case OrderStatus.inTransit:
      case OrderStatus.shipped:
        return Icons.local_shipping_rounded;
      case OrderStatus.assigned:
      case OrderStatus.pickedUp:
        return Icons.delivery_dining_rounded;
      case OrderStatus.confirmed:
        return Icons.thumb_up_alt_rounded;
      case OrderStatus.processing:
        return Icons.hourglass_top_rounded;
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
      case OrderStatus.assigned:
        return 'Driver Assigned';
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
      case OrderStatus.pickedUp:
      case OrderStatus.inTransit:
      case OrderStatus.shipped:
        return Colors.indigo;
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

// ── Order Detail Screen — streams live status from Firestore ─────────────────
class _OrderDetailScreen extends StatefulWidget {
  final Order order;
  const _OrderDetailScreen({required this.order});
  @override
  State<_OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<_OrderDetailScreen> {
  Order get order => widget.order;

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

  String _stepLabel(OrderStatus status) {
    switch (status) {
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
      case OrderStatus.delivered:
        return 'Delivered';
      default:
        return '';
    }
  }

  IconData _stepIcon(OrderStatus status) {
    switch (status) {
      case OrderStatus.processing:
        return Icons.receipt;
      case OrderStatus.confirmed:
        return Icons.check_circle;
      case OrderStatus.assigned:
        return Icons.person;
      case OrderStatus.pickedUp:
        return Icons.shopping_bag;
      case OrderStatus.inTransit:
        return Icons.local_shipping;
      case OrderStatus.delivered:
        return Icons.done_all;
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
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('allOrders')
            .doc(order.id)
            .snapshots(),
        builder: (_, snap) {
          // Use live status if available, else fall back to original
          OrderStatus liveStatus = order.status;
          if (snap.hasData && snap.data!.exists) {
            final raw =
                (snap.data!.data() as Map<String, dynamic>?)?['status']
                    as String? ??
                '';
            liveStatus = Order._parseStatus(raw);
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Status tracker ───────────────────────────────────────────────
                _buildTracker(liveStatus),
                const SizedBox(height: 24),
                if (order.status == OrderStatus.assigned ||
                    order.status == OrderStatus.pickedUp ||
                    order.status == OrderStatus.inTransit)
                  FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('drivers')
                        .doc(order.driverId)
                        .get(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const SizedBox();

                      final driver =
                          snapshot.data!.data() as Map<String, dynamic>;
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: AppTheme.card(radius: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Your Driver',
                              style: AppTheme.subheading.copyWith(fontSize: 14),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: AppTheme.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      driver['name']
                                          .substring(0, 1)
                                          .toUpperCase(),
                                      style: const TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        driver['name'],
                                        style: AppTheme.subheading.copyWith(
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        '${driver['vehicleType']} • ${driver['rating'].toStringAsFixed(1)} ⭐',
                                        style: AppTheme.body.copyWith(
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.phone,
                                    color: AppTheme.primary,
                                  ),
                                  onPressed: () async {
                                    final url = 'tel:${driver['phone']}';
                                    if (await canLaunchUrl(Uri.parse(url))) {
                                      await launchUrl(Uri.parse(url));
                                    }
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                // ── Items ────────────────────────────────────────────────────────
                Text(
                  'Items',
                  style: AppTheme.subheading.copyWith(fontSize: 15),
                ),
                const SizedBox(height: 10),
                Container(
                  decoration: AppTheme.card(radius: 16),
                  child: Column(
                    children: order.items
                        .map((i) => _ItemRow(item: i))
                        .toList(),
                  ),
                ),
                const SizedBox(height: 20),

                // ── Summary ──────────────────────────────────────────────────────
                Text(
                  'Summary',
                  style: AppTheme.subheading.copyWith(fontSize: 15),
                ),
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
          ); // SingleChildScrollView
        }, // StreamBuilder builder
      ), // StreamBuilder
    );
  }

  Widget _buildTracker(OrderStatus liveStatus) {
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
        : steps.indexOf(liveStatus);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.card(radius: 16),
      child:
          liveStatus == OrderStatus.cancelled
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
