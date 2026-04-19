import 'package:flutter/material.dart';
import 'driver_signup_screen.dart';
// Import your existing customer & restaurant signup screens
// import 'customer_signup_screen.dart';
// import 'restaurant_signup_screen.dart';

/// JOIN AS Screen - Role selection during signup
/// Updated to include Driver option alongside Customer and Restaurant Partner
class JoinAsScreen extends StatefulWidget {
  const JoinAsScreen({super.key});

  @override
  State<JoinAsScreen> createState() => _JoinAsScreenState();
}

class _JoinAsScreenState extends State<JoinAsScreen> {
  String _selectedRole = 'customer'; // customer, restaurant, driver

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background image
          Image.asset(
            'assets/gym_background.jpg', // Your background image
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(color: Colors.black),
          ),
          
          // Dark overlay
          Container(color: Colors.black.withOpacity(0.7)),
          
          // Content
          SafeArea(
            child: Column(
              children: [
                // Back Button
                Align(
                  alignment: Alignment.topLeft,
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      color: Colors.white,
                      size: 24,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),

                const SizedBox(height: 20),

                // Logo & Title
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.change_history,
                      color: Colors.white,
                      size: 28,
                    ),
                    SizedBox(width: 10),
                    Text(
                      "FITSTATION",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                // Main Title
                const Text(
                  "JOIN AS",
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  "Choose how you want to sign up",
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),

                const SizedBox(height: 40),

                // Role Cards
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        // Customer Option
                        _RoleCard(
                          icon: Icons.person,
                          title: 'Customer',
                          description: 'Browse supplements, meal plans\n& book consultations',
                          isSelected: _selectedRole == 'customer',
                          onTap: () => setState(() => _selectedRole = 'customer'),
                        ),
                        
                        const SizedBox(height: 14),

                        // Restaurant Partner Option
                        _RoleCard(
                          icon: Icons.restaurant,
                          title: 'Restaurant Partner',
                          description: 'List your restaurant & serve\nhealthy meals on FitStation',
                          isSelected: _selectedRole == 'restaurant',
                          onTap: () => setState(() => _selectedRole = 'restaurant'),
                        ),

                        const SizedBox(height: 14),

                        // Driver Option (NEW!)
                        _RoleCard(
                          icon: Icons.delivery_dining,
                          title: 'Driver',
                          description: 'Deliver orders & earn money\non your own schedule',
                          isSelected: _selectedRole == 'driver',
                          onTap: () => setState(() => _selectedRole = 'driver'),
                        ),
                      ],
                    ),
                  ),
                ),

                // Continue Button
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _continueWithRole,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'CONTINUE AS ${_getRoleLabel()}',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
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

  String _getRoleLabel() {
    switch (_selectedRole) {
      case 'customer':
        return 'CUSTOMER';
      case 'restaurant':
        return 'RESTAURANT';
      case 'driver':
        return 'DRIVER';
      default:
        return 'CUSTOMER';
    }
  }

  void _continueWithRole() {
    switch (_selectedRole) {
      case 'customer':
        // Navigate to your existing customer signup
        // Navigator.push(context, MaterialPageRoute(
        //   builder: (_) => const CustomerSignupScreen(),
        // ));
        break;
      case 'restaurant':
        // Navigate to your existing restaurant signup
        // Navigator.push(context, MaterialPageRoute(
        //   builder: (_) => const RestaurantSignupScreen(),
        // ));
        break;
      case 'driver':
        // Navigate to the new driver signup
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => const DriverSignupScreen(),
        ));
        break;
    }
  }
}

// ─── Role Selection Card ─────────────────────────────────────────────────────
class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isSelected 
              ? Colors.white 
              : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected 
                ? Colors.white 
                : Colors.white.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: isSelected 
                    ? const Color(0xFF5C3D2E) // Brown
                    : Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 26,
              ),
            ),

            const SizedBox(width: 14),

            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: isSelected 
                          ? const Color(0xFF1C1008) 
                          : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: isSelected 
                          ? const Color(0xFF9E8A7A) 
                          : Colors.white70,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            // Selected indicator
            if (isSelected)
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: Color(0xFF5C3D2E),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 18,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
