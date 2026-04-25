import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'app_theme.dart';
import 'driver_models.dart';
import 'auth_screen.dart';

class DriverProfileScreen extends StatelessWidget {
  const DriverProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        title: Text('Profile', style: AppTheme.subheading.copyWith(fontSize: 18)),
      ),
      body: user == null
          ? const Center(child: Text('Not logged in'))
          : StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('drivers')
                  .doc(user.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                final driverProfile = snapshot.hasData && snapshot.data!.exists
                    ? DriverProfile.fromFirestore(snapshot.data!)
                    : null;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildProfileHeader(driverProfile),
                      const SizedBox(height: 24),
                      _buildStatsCards(driverProfile),
                      const SizedBox(height: 24),
                      _buildMenuSection(context, 'Account', [
                        _MenuItem(
                          icon: Icons.person_outline,
                          title: 'Personal Information',
                          subtitle: driverProfile?.email ?? '',
                          onTap: () {},
                        ),
                        _MenuItem(
                          icon: Icons.two_wheeler_outlined,
                          title: 'Vehicle Details',
                          subtitle:
                              '${driverProfile?.vehicleType ?? ''} • ${driverProfile?.vehicleNumber ?? ''}',
                          onTap: () {},
                        ),
                      ]),
                      const SizedBox(height: 16),
                      _buildMenuSection(context, 'Legal', [
                        _MenuItem(
                          icon: Icons.gavel_outlined,
                          title: 'Terms & Conditions',
                          onTap: () => _showTermsAndConditions(context),
                        ),
                      ]),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () => _signOut(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.withValues(alpha:0.1),
                            foregroundColor: Colors.red,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.logout, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Sign Out',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildProfileHeader(DriverProfile? driverProfile) {
    final driverName = (driverProfile?.name ?? '').trim();
    final driverInitial = driverName.isNotEmpty
        ? driverName.substring(0, 1).toUpperCase()
        : 'D';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.card(radius: 20),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withValues(alpha:0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Center(
              child: Text(
                driverInitial,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            driverProfile?.name ?? 'Driver',
            style: AppTheme.subheading.copyWith(fontSize: 20),
          ),
          const SizedBox(height: 4),
          Text(
            driverProfile?.email ?? '',
            style: AppTheme.body.copyWith(fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            driverProfile?.phone ?? '',
            style: AppTheme.body.copyWith(fontSize: 13),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha:0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star, color: Colors.orange, size: 16),
                const SizedBox(width: 4),
                Text(
                  '${driverProfile?.rating.toStringAsFixed(1) ?? '0.0'} Rating',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards(DriverProfile? driverProfile) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: AppTheme.card(radius: 16),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha:0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.delivery_dining,
                    color: Colors.blue,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '${driverProfile?.totalDeliveries ?? 0}',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Deliveries',
                  style: AppTheme.label.copyWith(fontSize: 10),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: AppTheme.card(radius: 16),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha:0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet,
                    color: Colors.green,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '${driverProfile?.totalEarnings.toStringAsFixed(0) ?? '0'} JD',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Earned',
                  style: AppTheme.label.copyWith(fontSize: 10),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuSection(
      BuildContext context, String title, List<_MenuItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            title,
            style: AppTheme.subheading.copyWith(fontSize: 14),
          ),
        ),
        Container(
          decoration: AppTheme.card(radius: 16),
          child: Column(
            children: items.map((item) {
              final isLast = item == items.last;
              return Column(
                children: [
                  InkWell(
                    onTap: item.onTap,
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.accent.withValues(alpha:0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              item.icon,
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
                                  item.title,
                                  style: AppTheme.body.copyWith(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.dark,
                                  ),
                                ),
                                if (item.subtitle != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    item.subtitle!,
                                    style: AppTheme.label.copyWith(fontSize: 11),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right,
                            color: AppTheme.muted,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (!isLast)
                    const Divider(
                        height: 1, color: AppTheme.divider, indent: 56),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  void _showTermsAndConditions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Terms & Conditions',
                  style: AppTheme.subheading.copyWith(fontSize: 18),
                ),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Last updated: January 2025',
                  style: AppTheme.label.copyWith(fontSize: 12),
                ),
              ),
              const SizedBox(height: 16),
              const Divider(height: 1, color: AppTheme.divider),
              Expanded(
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.all(20),
                  children: [
                    _TermsSection(
                      title: '1. Acceptance of Terms',
                      body:
                          'By registering as a driver on FitStation, you agree to be bound by these Terms & Conditions. If you do not agree to these terms, you may not use our platform.',
                    ),
                    _TermsSection(
                      title: '2. Driver Eligibility',
                      body:
                          'You must be at least 18 years old, hold a valid driving license, and own or have legal access to a vehicle in good working condition. All provided information must be accurate and up to date.',
                    ),
                    _TermsSection(
                      title: '3. Order Acceptance & Conduct',
                      body:
                          'Drivers are expected to accept and complete orders in a professional and timely manner. Repeated cancellations or failure to deliver may result in suspension of your account.',
                    ),
                    _TermsSection(
                      title: '4. Delivery Standards',
                      body:
                          'All deliveries must be handled with care. Drivers are responsible for ensuring orders are delivered to the correct address in the condition received. Any damage caused during transit is the driver\'s responsibility.',
                    ),
                    _TermsSection(
                      title: '5. Earnings & Payments',
                      body:
                          'Earnings are calculated per delivery based on the delivery fee shown in the app. Payments are processed weekly. FitStation reserves the right to adjust fees with prior notice.',
                    ),
                    _TermsSection(
                      title: '6. Privacy & Data',
                      body:
                          'Your personal information is collected and used solely to operate the delivery service. We do not sell your data to third parties. Location data is only tracked when you are online and on an active delivery.',
                    ),
                    _TermsSection(
                      title: '7. Account Suspension',
                      body:
                          'FitStation reserves the right to suspend or terminate driver accounts for violations of these terms, fraudulent activity, or behaviour that harms customers or the platform.',
                    ),
                    _TermsSection(
                      title: '8. Changes to Terms',
                      body:
                          'We may update these Terms & Conditions from time to time. Continued use of the app after changes are posted constitutes your acceptance of the revised terms.',
                    ),
                    _TermsSection(
                      title: '9. Contact',
                      body:
                          'For any questions regarding these terms, please contact our support team through the app or at support@fitstation.jo.',
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _signOut(BuildContext context) async {
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Sign Out', style: AppTheme.subheading.copyWith(fontSize: 18)),
        content: Text(
          'Are you sure you want to sign out?',
          style: AppTheme.body.copyWith(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: AppTheme.body.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Sign Out',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );

    if (shouldSignOut == true) {
      await FirebaseAuth.instance.signOut();
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const AuthFlowHandler()),
          (route) => false,
        );
      }
    }
  }
}

class _MenuItem {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });
}

class _TermsSection extends StatelessWidget {
  final String title;
  final String body;

  const _TermsSection({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTheme.subheading.copyWith(fontSize: 14),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: AppTheme.body.copyWith(fontSize: 13, height: 1.6),
          ),
        ],
      ),
    );
  }
}
