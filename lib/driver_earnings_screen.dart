import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'app_theme.dart';
import 'driver_models.dart';

class DriverEarningsScreen extends StatefulWidget {
  const DriverEarningsScreen({super.key});

  @override
  State<DriverEarningsScreen> createState() => _DriverEarningsScreenState();
}

class _DriverEarningsScreenState extends State<DriverEarningsScreen> {
  String _selectedPeriod = 'today';

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Text(
              'Earnings',
              style: AppTheme.subheading.copyWith(fontSize: 18),
            ),
          ),
          _buildTotalEarningsCard(),
          _buildPeriodSelector(),
          Expanded(child: _buildEarningsList()),
        ],
      ),
    );
  }

  Widget _buildTotalEarningsCard() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(20),
      child: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('drivers')
            .doc(user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          final driverProfile = snapshot.hasData && snapshot.data!.exists
              ? DriverProfile.fromFirestore(snapshot.data!)
              : null;

          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primary, AppTheme.primaryLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Total Earnings',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${driverProfile?.totalEarnings.toStringAsFixed(2) ?? '0.00'}',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 40,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Text(
                        'JD',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          const Icon(
                            Icons.delivery_dining,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${driverProfile?.totalDeliveries ?? 0}',
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Deliveries',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: Colors.white.withOpacity(0.2),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          const Icon(Icons.star, color: Colors.white, size: 20),
                          const SizedBox(height: 6),
                          Text(
                            '${driverProfile?.rating.toStringAsFixed(1) ?? '0.0'}',
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            '${driverProfile?.ratingCount ?? 0} ratings',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            _buildPeriodTab('today', 'Today'),
            _buildPeriodTab('week', 'Week'),
            _buildPeriodTab('month', 'Month'),
            _buildPeriodTab('all', 'All'),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodTab(String period, String label) {
    final isSelected = _selectedPeriod == period;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedPeriod = period),
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
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : AppTheme.muted,
            ),
          ),
        ),
      ),
    );
    
  }

  Widget _buildEarningsList() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox();

    final now = DateTime.now();
    DateTime? startDate;

    switch (_selectedPeriod) {
      case 'today':
        startDate = DateTime(now.year, now.month, now.day);
        break;
      case 'week':
        startDate = now.subtract(const Duration(days: 7));
        break;
      case 'month':
        startDate = DateTime(now.year, now.month, 1);
        break;
      case 'all':
        startDate = null;
        break;
    }

    Query query = FirebaseFirestore.instance
        .collection('deliveryOrders')
        .where('driverId', isEqualTo: user.uid)
        .where('status', isEqualTo: 'delivered');

    if (startDate != null) {
      query = query.where('deliveredAt', isGreaterThanOrEqualTo: startDate);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primary),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error loading earnings', style: AppTheme.body),
          );
        }

        final orders = snapshot.data?.docs
                .map((doc) => DeliveryOrder.fromFirestore(doc))
                .toList() ??
            []
          ..sort((a, b) {
            final aTime = (a.deliveredAt ?? a.date).millisecondsSinceEpoch;
            final bTime = (b.deliveredAt ?? b.date).millisecondsSinceEpoch;
            return bTime.compareTo(aTime);
          });

        if (orders.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 48,
                    color: AppTheme.accent,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'No Earnings Yet',
                  style: AppTheme.subheading.copyWith(fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  'Start delivering to earn money',
                  style: AppTheme.body.copyWith(fontSize: 13),
                ),
              ],
            ),
          );
        }

        final totalEarnings = orders.fold<double>(
          0,
          (sum, order) => sum + order.deliveryFee,
        );

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          itemCount: orders.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: AppTheme.card(radius: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getPeriodLabel(),
                          style: AppTheme.label.copyWith(fontSize: 11),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${orders.length} ${orders.length == 1 ? 'Delivery' : 'Deliveries'}',
                          style: AppTheme.subheading.copyWith(fontSize: 14),
                        ),
                      ],
                    ),
                    Text(
                      '${totalEarnings.toStringAsFixed(2)} JD',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              );
            }

            final order = orders[index - 1];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: AppTheme.card(radius: 14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      color: Colors.green,
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
                          style: AppTheme.subheading.copyWith(fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('MMM d, h:mm a')
                              .format(order.deliveredAt ?? order.date),
                          style: AppTheme.label.copyWith(fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '+${order.deliveryFee.toStringAsFixed(2)} JD',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _getPeriodLabel() {
    switch (_selectedPeriod) {
      case 'today':
        return 'Today\'s Earnings';
      case 'week':
        return 'This Week';
      case 'month':
        return 'This Month';
      case 'all':
        return 'All Time';
      default:
        return '';
    }
  }
}
