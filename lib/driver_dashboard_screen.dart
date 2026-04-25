import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'app_theme.dart';
import 'driver_models.dart';
import 'driver_orders_screen.dart';
import 'driver_earnings_screen.dart';
import 'driver_profile_screen.dart';

/// Main driver dashboard with bottom navigation
/// Integrated into the FitStation app for drivers
class DriverDashboardScreen extends StatefulWidget {
  const DriverDashboardScreen({super.key});

  @override
  State<DriverDashboardScreen> createState() => _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends State<DriverDashboardScreen> {
  int _selectedTab = 0;
  DriverProfile? _driverProfile;
  bool _isAvailable = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDriverProfile();
  }

  Future<void> _loadDriverProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('drivers')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        setState(() {
          _driverProfile = DriverProfile.fromFirestore(doc);
          _isAvailable = _driverProfile?.isAvailable ?? true;
          _isLoading = false;
        });
      } else {
        // First time driver - show setup
        setState(() => _isLoading = false);
        _showDriverSetup();
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleAvailability() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final newStatus = !_isAvailable;

    await FirebaseFirestore.instance
        .collection('drivers')
        .doc(user.uid)
        .update({'isAvailable': newStatus});

    setState(() => _isAvailable = newStatus);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          newStatus ? '🚀 You are now online!' : '⏸️ You are now offline',
          style: const TextStyle(fontFamily: 'Poppins'),
        ),
        backgroundColor: newStatus ? AppTheme.primary : AppTheme.muted,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showDriverSetup() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _DriverSetupSheet(
        onComplete: () {
          Navigator.pop(context);
          _loadDriverProfile();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        ),
      );
    }

    final List<Widget> screens = [
      const DriverOrdersScreen(),
      const DriverEarningsScreen(),
      const DriverProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: _selectedTab == 0 ? _buildAppBar() : null,
      body: screens[_selectedTab],
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.background,
      elevation: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Driver Mode',
            style: AppTheme.subheading.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _isAvailable ? Colors.green : Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                _isAvailable ? 'Online' : 'Offline',
                style: AppTheme.label.copyWith(
                  fontSize: 12,
                  color: _isAvailable ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        // Availability Toggle
        GestureDetector(
          onTap: _toggleAvailability,
          child: Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: _isAvailable
                  ? Colors.green.withOpacity(0.1)
                  : AppTheme.muted.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isAvailable ? Colors.green : AppTheme.muted,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _isAvailable ? Icons.toggle_on : Icons.toggle_off,
                  color: _isAvailable ? Colors.green : AppTheme.muted,
                  size: 20,
                ),
                const SizedBox(width: 6),
                Text(
                  _isAvailable ? 'Online' : 'Offline',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _isAvailable ? Colors.green : AppTheme.muted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.delivery_dining, 'Orders'),
              _buildNavItem(1, Icons.account_balance_wallet, 'Earnings'),
              _buildNavItem(2, Icons.person, 'Profile'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _selectedTab == index;

    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primary.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.primary : AppTheme.muted,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? AppTheme.primary : AppTheme.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Driver Setup Sheet ──────────────────────────────────────────────────────
class _DriverSetupSheet extends StatefulWidget {
  final VoidCallback onComplete;

  const _DriverSetupSheet({required this.onComplete});

  @override
  State<_DriverSetupSheet> createState() => _DriverSetupSheetState();
}

class _DriverSetupSheetState extends State<_DriverSetupSheet> {
  final _phoneController = TextEditingController();
  final _vehicleTypeController = TextEditingController();
  final _vehicleNumberController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _vehicleTypeController.dispose();
    _vehicleNumberController.dispose();
    super.dispose();
  }

  Future<void> _setupDriver() async {
    if (_phoneController.text.trim().isEmpty ||
        _vehicleTypeController.text.trim().isEmpty ||
        _vehicleNumberController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser!;

      final driver = DriverProfile(
        id: user.uid,
        name: user.displayName ?? 'Driver',
        email: user.email ?? '',
        phone: _phoneController.text.trim(),
        vehicleType: _vehicleTypeController.text.trim(),
        vehicleNumber: _vehicleNumberController.text.trim(),
        joinedDate: DateTime.now(),
      );

      await FirebaseFirestore.instance
          .collection('drivers')
          .doc(user.uid)
          .set(driver.toMap());

      widget.onComplete();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.delivery_dining,
                      color: AppTheme.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Become a Driver',
                          style: AppTheme.heading.copyWith(fontSize: 22),
                        ),
                        Text(
                          'Complete your driver profile',
                          style: AppTheme.body.copyWith(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Phone
              TextField(
                controller: _phoneController,
                decoration: AppTheme.inputDecoration(
                  'Phone Number',
                  Icons.phone_outlined,
                ),
                keyboardType: TextInputType.phone,
              ),

              const SizedBox(height: 16),

              // Vehicle Type
              TextField(
                controller: _vehicleTypeController,
                decoration: AppTheme.inputDecoration(
                  'Vehicle Type (Motorcycle, Car, etc.)',
                  Icons.two_wheeler_outlined,
                ),
                textCapitalization: TextCapitalization.words,
              ),

              const SizedBox(height: 16),

              // Vehicle Number
              TextField(
                controller: _vehicleNumberController,
                decoration: AppTheme.inputDecoration(
                  'Vehicle Number',
                  Icons.confirmation_number_outlined,
                ),
                textCapitalization: TextCapitalization.characters,
              ),

              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _setupDriver,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text(
                          'Start Driving',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
