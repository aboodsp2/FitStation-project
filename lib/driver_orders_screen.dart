import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'app_theme.dart';
import 'driver_models.dart';

class DriverOrdersScreen extends StatefulWidget {
  const DriverOrdersScreen({super.key});

  @override
  State<DriverOrdersScreen> createState() => _DriverOrdersScreenState();
}

class _DriverOrdersScreenState extends State<DriverOrdersScreen> {
  String _selectedTab = 'mydeliveries';

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Text(
              'Orders',
              style: AppTheme.subheading.copyWith(fontSize: 18),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  _buildTab('mydeliveries', 'My Deliveries'),
                  _buildTab('available', 'Available'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _selectedTab == 'available'
                ? _buildAvailableOrders()
                : _buildMyDeliveries(),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String tab, String label) {
    final isSelected = _selectedTab == tab;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = tab),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : AppTheme.muted,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvailableOrders() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('deliveryOrders')
          .where('status', isEqualTo: 'confirmed')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primary),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error loading orders', style: AppTheme.body),
          );
        }

        // Filter unassigned orders in memory to avoid composite index requirement
        final orders = (snapshot.data?.docs ?? [])
            .where((d) => (d.data() as Map<String, dynamic>)['driverId'] == null)
            .toList()
          ..sort((a, b) {
            final aT = ((a.data() as Map)['date'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
            final bT = ((b.data() as Map)['date'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
            return bT.compareTo(aT);
          });

        if (orders.isEmpty) {
          return _buildEmptyState(
            Icons.delivery_dining,
            'No Available Orders',
            'New delivery requests will appear here',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = DeliveryOrder.fromFirestore(orders[index]);
            return _AvailableOrderCard(
              order: order,
              onAccept: () => _acceptOrder(order),
            );
          },
        );
      },
    );
  }

  Widget _buildMyDeliveries() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('deliveryOrders')
          .where('driverId', isEqualTo: user.uid)
          .where('status', whereIn: ['assigned', 'pickedUp', 'inTransit'])
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primary),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error loading deliveries', style: AppTheme.body),
          );
        }

        // Sort by assignedAt descending in memory to avoid composite index requirement
        final orders = (snapshot.data?.docs ?? [])
          ..sort((a, b) {
            final aT = ((a.data() as Map)['assignedAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
            final bT = ((b.data() as Map)['assignedAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
            return bT.compareTo(aT);
          });

        if (orders.isEmpty) {
          return _buildEmptyState(
            Icons.shopping_bag_outlined,
            'No Active Deliveries',
            'Accept an order to start delivering',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = DeliveryOrder.fromFirestore(orders[index]);
            return _MyDeliveryCard(order: order);
          },
        );
      },
    );
  }

  Widget _buildEmptyState(IconData icon, String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppTheme.accent.withValues(alpha:0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 48, color: AppTheme.accent),
          ),
          const SizedBox(height: 24),
          Text(title, style: AppTheme.subheading.copyWith(fontSize: 16)),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: AppTheme.body.copyWith(fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _acceptOrder(DeliveryOrder order) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final driverDoc = await FirebaseFirestore.instance
          .collection('drivers')
          .doc(user.uid)
          .get();

      final isAvailable = driverDoc.data()?['isAvailable'] as bool? ?? false;
      if (!isAvailable) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You must be online to accept orders. Toggle your status first.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      final batch = FirebaseFirestore.instance.batch();

      // Update delivery order
      batch.update(
        FirebaseFirestore.instance
            .collection('deliveryOrders')
            .doc(order.id),
        {
          'driverId': user.uid,
          'status': 'assigned',
          'assignedAt': FieldValue.serverTimestamp(),
        },
      );

      // Update user's order
      batch.update(
        FirebaseFirestore.instance
            .collection('orders')
            .doc(order.userId)
            .collection('userOrders')
            .doc(order.id),
        {
          'status': 'assigned',
          'driverId': user.uid,
        },
      );

      await batch.commit();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order accepted! Start delivering.'),
          backgroundColor: Colors.green,
        ),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to accept: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

// ─── Available Order Card ────────────────────────────────────────────────────
class _AvailableOrderCard extends StatelessWidget {
  final DeliveryOrder order;
  final VoidCallback onAccept;

  const _AvailableOrderCard({required this.order, required this.onAccept});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: AppTheme.card(radius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.accent.withValues(alpha:0.06),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.receipt_long,
                    color: Colors.white,
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
                        _formatTime(order.date),
                        style: AppTheme.label.copyWith(fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha:0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '+${order.deliveryFee.toStringAsFixed(2)} JD',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.green,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InfoRow(
                  icon: Icons.person_outline,
                  text: order.customerName.isNotEmpty ? order.customerName : 'Customer',
                ),
                const SizedBox(height: 10),
                _InfoRow(
                  icon: Icons.location_on_outlined,
                  text: order.deliveryAddress,
                ),
                const SizedBox(height: 10),
                _InfoRow(
                  icon: Icons.shopping_bag_outlined,
                  text: '${order.items.length} items • ${order.total.toStringAsFixed(2)} JD',
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: onAccept,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Accept Order',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

// ─── My Delivery Card ────────────────────────────────────────────────────────
class _MyDeliveryCard extends StatelessWidget {
  final DeliveryOrder order;

  const _MyDeliveryCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => _OrderDetailsScreen(order: order),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: AppTheme.card(radius: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Order #${order.id}',
                    style: AppTheme.subheading.copyWith(fontSize: 15),
                  ),
                ),
                _StatusBadge(status: order.status),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppTheme.divider),
            const SizedBox(height: 12),
            _InfoRow(
              icon: Icons.person_outline,
              text: order.customerName.isNotEmpty ? order.customerName : 'Customer',
            ),
            const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.location_on_outlined,
              text: order.deliveryAddress,
            ),
            const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.phone_outlined,
              text: order.customerPhone,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${order.items.length} items',
                  style: AppTheme.body.copyWith(fontSize: 12),
                ),
                Text(
                  '${order.total.toStringAsFixed(2)} JD',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Helper Widgets ──────────────────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppTheme.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: AppTheme.body.copyWith(fontSize: 13),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final OrderStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;

    switch (status) {
      case OrderStatus.assigned:
        color = Colors.blue;
        label = 'ASSIGNED';
        break;
      case OrderStatus.pickedUp:
        color = Colors.orange;
        label = 'PICKED UP';
        break;
      case OrderStatus.inTransit:
        color = AppTheme.accent;
        label = 'IN TRANSIT';
        break;
      case OrderStatus.delivered:
        color = Colors.green;
        label = 'DELIVERED';
        break;
      default:
        color = AppTheme.muted;
        label = 'PROCESSING';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha:0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

// ─── Order Details Screen ────────────────────────────────────────────────────
class _OrderDetailsScreen extends StatefulWidget {
  final DeliveryOrder order;

  const _OrderDetailsScreen({required this.order});

  @override
  State<_OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<_OrderDetailsScreen> {
  late DeliveryOrder _order;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _order = widget.order;
  }

  Future<void> _updateStatus(OrderStatus newStatus) async {
    setState(() => _isUpdating = true);

    try {
      final updates = <String, dynamic>{'status': newStatus.value};

      if (newStatus == OrderStatus.pickedUp) {
        updates['pickedUpAt'] = FieldValue.serverTimestamp();
      } else if (newStatus == OrderStatus.delivered) {
        updates['deliveredAt'] = FieldValue.serverTimestamp();
        await _updateEarnings();
      }

      final batch = FirebaseFirestore.instance.batch();

      batch.update(
        FirebaseFirestore.instance.collection('deliveryOrders').doc(_order.id),
        updates,
      );

      batch.update(
        FirebaseFirestore.instance
            .collection('orders')
            .doc(_order.userId)
            .collection('userOrders')
            .doc(_order.id),
        {'status': newStatus.value},
      );

      await batch.commit();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Status updated!'), backgroundColor: Colors.green),
      );

      if (newStatus == OrderStatus.delivered) {
        Navigator.pop(context);
      } else {
        // Reload order
        final doc = await FirebaseFirestore.instance
            .collection('deliveryOrders')
            .doc(_order.id)
            .get();
        if (doc.exists) {
          setState(() => _order = DeliveryOrder.fromFirestore(doc));
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isUpdating = false);
    }
  }

  Future<void> _updateEarnings() async {
    final driverId = FirebaseAuth.instance.currentUser!.uid;
    final driverRef = FirebaseFirestore.instance.collection('drivers').doc(driverId);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final doc = await transaction.get(driverRef);
      if (doc.exists) {
        final currentEarnings = (doc.data()?['totalEarnings'] as num?)?.toDouble() ?? 0.0;
        final currentDeliveries = (doc.data()?['totalDeliveries'] as num?)?.toInt() ?? 0;

        transaction.update(driverRef, {
          'totalEarnings': currentEarnings + _order.deliveryFee,
          'totalDeliveries': currentDeliveries + 1,
        });
      }
    });
  }

  Future<void> _openMaps() async {
    final url = _order.latitude != null && _order.longitude != null
        ? 'https://www.google.com/maps/dir/?api=1&destination=${_order.latitude},${_order.longitude}'
        : 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(_order.deliveryAddress)}';

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _callCustomer() async {
    final url = 'tel:${_order.customerPhone}';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        title: Text('Order Details', style: AppTheme.subheading.copyWith(fontSize: 18)),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Customer Info
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: AppTheme.card(radius: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Customer', style: AppTheme.subheading.copyWith(fontSize: 14)),
                        const SizedBox(height: 12),
                        _InfoRow(
                          icon: Icons.person_outline,
                          text: _order.customerName.isNotEmpty ? _order.customerName : 'Customer',
                        ),
                        const SizedBox(height: 8),
                        _InfoRow(icon: Icons.phone_outlined, text: _order.customerPhone),
                        const SizedBox(height: 8),
                        _InfoRow(icon: Icons.location_on_outlined, text: _order.deliveryAddress),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Items
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: AppTheme.card(radius: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Items (${_order.items.length})', style: AppTheme.subheading.copyWith(fontSize: 14)),
                        const SizedBox(height: 12),
                        ..._order.items.map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Expanded(child: Text(item.name, style: AppTheme.body.copyWith(fontSize: 13))),
                              Text('${item.qty}×', style: AppTheme.body.copyWith(fontSize: 12)),
                              const SizedBox(width: 6),
                              Text(
                                '${item.price.toStringAsFixed(2)} JD',
                                style: AppTheme.body.copyWith(fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        )),
                        const Divider(height: 20, color: AppTheme.divider),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Total', style: AppTheme.subheading.copyWith(fontSize: 14)),
                            Text(
                              '${_order.total.toStringAsFixed(2)} JD',
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
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
          ),
          
          // Actions
          if (_order.status != OrderStatus.delivered)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha:0.08),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _callCustomer,
                            icon: const Icon(Icons.phone, size: 18),
                            label: const Text('Call'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.primary,
                              side: const BorderSide(color: AppTheme.primary),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _openMaps,
                            icon: const Icon(Icons.navigation, size: 18),
                            label: const Text('Navigate'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.primary,
                              side: const BorderSide(color: AppTheme.primary),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isUpdating ? null : _getNextAction,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        child: _isUpdating
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                              )
                            : Text(
                                _getNextLabel(),
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _getNextAction() {
    switch (_order.status) {
      case OrderStatus.assigned:
        _updateStatus(OrderStatus.pickedUp);
        break;
      case OrderStatus.pickedUp:
        _updateStatus(OrderStatus.inTransit);
        break;
      case OrderStatus.inTransit:
        _updateStatus(OrderStatus.delivered);
        break;
      default:
        break;
    }
  }

  String _getNextLabel() {
    switch (_order.status) {
      case OrderStatus.assigned:
        return 'Mark as Picked Up';
      case OrderStatus.pickedUp:
        return 'Start Delivery';
      case OrderStatus.inTransit:
        return 'Complete Delivery';
      default:
        return 'Update Status';
    }
  }
}
