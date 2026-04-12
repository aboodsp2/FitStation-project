import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'app_theme.dart';
import 'auth_screen.dart';
import 'supplement_models.dart' show SupplementImage;

// ── Safe number parsers (handles String fields from Firestore) ──────────────
double _safeDouble(dynamic v) {
  if (v == null) return 0.0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0.0;
}

int _safeInt(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString()) ?? 0;
}

// ═══════════════════════════════════════════════════════════════════════════════
// ADMIN ROLE MODEL
// ═══════════════════════════════════════════════════════════════════════════════

class AdminRole {
  final String email;
  final String role; // 'superadmin' | 'restaurant'
  final String? restaurantId;
  final String? restaurantName;

  const AdminRole({
    required this.email,
    required this.role,
    this.restaurantId,
    this.restaurantName,
  });

  bool get isSuperAdmin => role == 'superadmin';
  bool get isRestaurant => role == 'restaurant';
}

// ═══════════════════════════════════════════════════════════════════════════════
// ADMIN CHECKER — call this after login to check if the user is an admin
// ═══════════════════════════════════════════════════════════════════════════════

class AdminChecker {
  static Future<AdminRole?> check(String email) async {
    final snap = await FirebaseFirestore.instance
        .collection('admins')
        .where('email', isEqualTo: email.trim().toLowerCase())
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    final data = snap.docs.first.data();
    return AdminRole(
      email: email,
      role: data['role'] as String? ?? 'restaurant',
      restaurantId: data['restaurantId'] as String?,
      restaurantName: data['restaurantName'] as String?,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// ADMIN SHELL — top-level scaffold with bottom nav
// ═══════════════════════════════════════════════════════════════════════════════

class AdminScreen extends StatefulWidget {
  final AdminRole role;
  const AdminScreen({super.key, required this.role});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  int _tab = 0;

  List<_NavItem> get _navItems {
    if (widget.role.isSuperAdmin) {
      return const [
        _NavItem(Icons.dashboard_rounded, 'Dashboard'),
        _NavItem(Icons.science_rounded, 'Supplements'),
        _NavItem(Icons.receipt_long_rounded, 'Orders'),
        _NavItem(Icons.video_call_rounded, 'Consults'),
        _NavItem(Icons.feedback_rounded, 'Feedback'),
      ];
    } else {
      return const [
        _NavItem(Icons.restaurant_menu_rounded, 'My Meals'),
        _NavItem(Icons.receipt_long_rounded, 'Meal Orders'),
      ];
    }
  }

  List<Widget> get _pages {
    if (widget.role.isSuperAdmin) {
      return [
        _SuperAdminDashboard(),
        _SupplementsTab(),
        _SupplementOrdersTab(),
        _ConsultationsTab(),
        _FeedbackTab(),
      ];
    } else {
      return [
        _RestaurantMealsTab(
          restaurantId: widget.role.restaurantId!,
          restaurantName: widget.role.restaurantName ?? 'My Restaurant',
        ),
        _MealOrdersTab(restaurantId: widget.role.restaurantId!),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _navItems;
    final pages = _pages;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ── Top bar ────────────────────────────────────────────────
            _AdminTopBar(role: widget.role),
            // ── Content ────────────────────────────────────────────────
            Expanded(
              child: IndexedStack(index: _tab, children: pages),
            ),
            // ── Bottom nav ─────────────────────────────────────────────
            _AdminBottomNav(
              items: items,
              selected: _tab,
              onTap: (i) => setState(() => _tab = i),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Top bar ──────────────────────────────────────────────────────────────────

class _AdminTopBar extends StatelessWidget {
  final AdminRole role;
  const _AdminTopBar({required this.role});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      decoration: BoxDecoration(
        color: AppTheme.primary,
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              role.isSuperAdmin
                  ? Icons.admin_panel_settings_rounded
                  : Icons.restaurant_rounded,
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
                  role.isSuperAdmin
                      ? 'FitStation Admin'
                      : (role.restaurantName ?? 'Restaurant Admin'),
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  role.email,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const AuthFlowHandler()),
                  (r) => false,
                );
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.logout_rounded, color: Colors.white, size: 15),
                  SizedBox(width: 5),
                  Text(
                    'Logout',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
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
}

// ── Bottom nav ───────────────────────────────────────────────────────────────

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem(this.icon, this.label);
}

class _AdminBottomNav extends StatelessWidget {
  final List<_NavItem> items;
  final int selected;
  final ValueChanged<int> onTap;
  const _AdminBottomNav({
    required this.items,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(bottom: 20, top: 10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (i) {
          final sel = i == selected;
          return GestureDetector(
            onTap: () => onTap(i),
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: sel
                    ? AppTheme.primary.withValues(alpha: 0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    items[i].icon,
                    color: sel ? AppTheme.primary : AppTheme.muted,
                    size: 22,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    items[i].label,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 10,
                      fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
                      color: sel ? AppTheme.primary : AppTheme.muted,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SUPERADMIN — DASHBOARD
// ═══════════════════════════════════════════════════════════════════════════════

class _SuperAdminDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      children: [
        Text('Dashboard', style: AppTheme.heading.copyWith(fontSize: 22)),
        const SizedBox(height: 16),
        // Stat cards row
        Row(
          children: [
            _StatCard(
              label: 'Supplement\nOrders',
              icon: Icons.science_rounded,
              color: const Color(0xFF4A90D9),
              stream: FirebaseFirestore.instance
                  .collection('allOrders')
                  .snapshots(),
            ),
            const SizedBox(width: 12),
            _StatCard(
              label: 'Consultations',
              icon: Icons.video_call_rounded,
              color: const Color(0xFF27AE60),
              stream: FirebaseFirestore.instance
                  .collection('bookings')
                  .snapshots(),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _StatCard(
              label: 'Supplements\nin Store',
              icon: Icons.inventory_2_rounded,
              color: AppTheme.accent,
              stream: FirebaseFirestore.instance
                  .collection('supplements')
                  .snapshots(),
            ),
            const SizedBox(width: 12),
            _StatCard(
              label: 'Users',
              icon: Icons.people_rounded,
              color: const Color(0xFFE74C3C),
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .snapshots(),
            ),
          ],
        ),
        const SizedBox(height: 28),
        Text(
          'Recent Supplement Orders',
          style: AppTheme.subheading.copyWith(fontSize: 15),
        ),
        const SizedBox(height: 12),
        _RecentOrdersList(),
        const SizedBox(height: 28),
        Text(
          'Recent Consultations',
          style: AppTheme.subheading.copyWith(fontSize: 15),
        ),
        const SizedBox(height: 12),
        _RecentConsultsList(),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Stream<QuerySnapshot> stream;
  const _StatCard({
    required this.label,
    required this.icon,
    required this.color,
    required this.stream,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: StreamBuilder<QuerySnapshot>(
        stream: stream,
        builder: (_, snap) {
          final count = snap.data?.docs.length ?? 0;
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.12),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(height: 12),
                Text(
                  '$count',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.dark,
                  ),
                ),
                Text(
                  label,
                  style: AppTheme.body.copyWith(fontSize: 11, height: 1.3),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _RecentOrdersList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('allOrders')
          .limit(5)
          .snapshots(),
      builder: (_, snap) {
        if (snap.hasError) return _EmptyState(label: 'Error loading orders');
        if (!snap.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primary),
          );
        }
        final docs = snap.data!.docs;
        if (docs.isEmpty) {
          return _EmptyState(label: 'No supplement orders yet');
        }
        return Column(
          children: docs
              .map((d) => _OrderRow(data: d.data() as Map<String, dynamic>))
              .toList(),
        );
      },
    );
  }
}

class _OrderRow extends StatelessWidget {
  final Map<String, dynamic> data;
  const _OrderRow({required this.data});

  @override
  Widget build(BuildContext context) {
    final status = data['status'] as String? ?? 'processing';
    final statusColor = _statusColor(status);
    final date = (data['date'] as Timestamp?)?.toDate();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.card(radius: 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['userEmail'] as String? ?? '—',
                  style: AppTheme.subheading.copyWith(fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  date != null ? '${date.day}/${date.month}/${date.year}' : '—',
                  style: AppTheme.body.copyWith(fontSize: 11),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${_safeDouble(data['total']).toStringAsFixed(2)}',
                style: AppTheme.subheading.copyWith(
                  fontSize: 14,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'completed':
        return Colors.green;
      case 'processing':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      default:
        return AppTheme.muted;
    }
  }
}

class _RecentConsultsList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .orderBy('createdAt', descending: true)
          .limit(5)
          .snapshots(),
      builder: (_, snap) {
        if (!snap.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primary),
          );
        }
        final docs = snap.data!.docs;
        if (docs.isEmpty) return _EmptyState(label: 'No bookings yet');
        return Column(
          children: docs.map((d) {
            final data = d.data() as Map<String, dynamic>;
            return _ConsultRow(data: data, docId: d.id);
          }).toList(),
        );
      },
    );
  }
}

class _ConsultRow extends StatelessWidget {
  final Map<String, dynamic> data;
  final String docId;
  const _ConsultRow({required this.data, required this.docId});

  @override
  Widget build(BuildContext context) {
    final status = data['status'] as String? ?? 'pending';
    final statusColor = status == 'confirmed'
        ? Colors.green
        : status == 'cancelled'
        ? Colors.red
        : Colors.orange;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.card(radius: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.accent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.video_call_rounded,
              color: AppTheme.accent,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['specialistName'] as String? ?? '—',
                  style: AppTheme.subheading.copyWith(fontSize: 13),
                ),
                Text(
                  '${data['date'] ?? '—'}  ${data['time'] ?? ''}',
                  style: AppTheme.body.copyWith(fontSize: 11),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${_safeDouble(data['price']).toStringAsFixed(0)}',
                style: AppTheme.subheading.copyWith(
                  fontSize: 13,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SUPERADMIN — SUPPLEMENTS TAB
// ═══════════════════════════════════════════════════════════════════════════════

class _SupplementsTab extends StatefulWidget {
  @override
  State<_SupplementsTab> createState() => _SupplementsTabState();
}

class _SupplementsTabState extends State<_SupplementsTab> {
  String _filter = 'All';

  static const _filters = [
    'All',
    'Out of Stock',
    'snacks',
    'amino',
    'health',
    'creatine',
    'protein',
    'fat',
    'mass gainer',
    'pre-workout',
    'hot deals',
  ];

  String _filterLabel(String f) {
    if (f == 'All' || f == 'Out of Stock') return f;
    return f[0].toUpperCase() + f.substring(1);
  }

  void _showAddProductDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final qtyCtrl = TextEditingController();
    final unitCtrl = TextEditingController();
    final imageCtrl = TextEditingController();
    String selectedCategory = 'protein';
    bool saving = false;

    const categories = [
      'protein',
      'pre-workout',
      'creatine',
      'mass gainer',
      'amino',
      'fat',
      'health',
      'snacks',
      'hot deals',
    ];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: AppTheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Add New Product',
                style: AppTheme.subheading.copyWith(fontSize: 15),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name
                  TextField(
                    controller: nameCtrl,
                    textCapitalization: TextCapitalization.words,
                    decoration: AppTheme.inputDecoration(
                      'Product name *',
                      Icons.label_rounded,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Category dropdown
                  Text(
                    'Category',
                    style: AppTheme.body.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.dark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.divider),
                    ),
                    child: DropdownButton<String>(
                      value: selectedCategory,
                      isExpanded: true,
                      underline: const SizedBox(),
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        color: AppTheme.dark,
                      ),
                      items: categories
                          .map(
                            (c) => DropdownMenuItem(
                              value: c,
                              child: Text(
                                c[0].toUpperCase() + c.substring(1),
                                style: const TextStyle(fontFamily: 'Poppins'),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setDlgState(() => selectedCategory = v);
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Description
                  TextField(
                    controller: descCtrl,
                    maxLines: 2,
                    decoration: AppTheme.inputDecoration(
                      'Description',
                      Icons.description_rounded,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Price & Quantity row
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: priceCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: AppTheme.inputDecoration(
                            'Price (\$) *',
                            Icons.attach_money_rounded,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: qtyCtrl,
                          keyboardType: TextInputType.number,
                          decoration: AppTheme.inputDecoration(
                            'Qty *',
                            Icons.inventory_2_rounded,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Unit
                  TextField(
                    controller: unitCtrl,
                    decoration: AppTheme.inputDecoration(
                      'Unit (e.g. 500g, 60 caps)',
                      Icons.scale_rounded,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Image URL
                  TextField(
                    controller: imageCtrl,
                    decoration: AppTheme.inputDecoration(
                      'Image URL (https://...)',
                      Icons.image_rounded,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tip: upload image to Firebase Storage and paste the download URL',
                    style: AppTheme.body.copyWith(fontSize: 10),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(fontFamily: 'Poppins', color: AppTheme.muted),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              onPressed: saving
                  ? null
                  : () async {
                      final name = nameCtrl.text.trim();
                      final priceStr = priceCtrl.text.trim();
                      final qtyStr = qtyCtrl.text.trim();
                      if (name.isEmpty || priceStr.isEmpty || qtyStr.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text(
                              'Please fill in name, price and quantity',
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
                      setDlgState(() => saving = true);
                      try {
                        await FirebaseFirestore.instance
                            .collection('supplements')
                            .add({
                              'name': name,
                              'category': selectedCategory,
                              'description': descCtrl.text.trim(),
                              'price': double.tryParse(priceStr) ?? 0.0,
                              'quantity': int.tryParse(qtyStr) ?? 0,
                              'unit': unitCtrl.text.trim(),
                              'imageUrl': imageCtrl.text.trim(),
                              'rating': 0.0,
                              'createdAt': FieldValue.serverTimestamp(),
                            });
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: const [
                                  Icon(
                                    Icons.check_circle_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                  SizedBox(width: 10),
                                  Text(
                                    'Product added successfully!',
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
                        setDlgState(() => saving = false);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Error: $e',
                                style: const TextStyle(fontFamily: 'Poppins'),
                              ),
                              backgroundColor: Colors.red,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      }
                    },
              child: saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Add Product',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  bool _matchesFilter(Map<String, dynamic> data) {
    if (_filter == 'All') return true;
    if (_filter == 'Out of Stock') return _safeInt(data['quantity']) == 0;
    final cat = (data['category'] as String? ?? '').toLowerCase().trim();
    return cat == _filter.toLowerCase().trim() ||
        cat.contains(_filter.toLowerCase().trim());
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('supplements')
          .orderBy('name')
          .snapshots(),
      builder: (_, snap) {
        if (!snap.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primary),
          );
        }
        final allDocs = snap.data!.docs;
        final docs = allDocs
            .where((d) => _matchesFilter(d.data() as Map<String, dynamic>))
            .toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Supplements',
                    style: AppTheme.heading.copyWith(fontSize: 22),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        '${allDocs.length} products in store',
                        style: AppTheme.body.copyWith(fontSize: 12),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => _showAddProductDialog(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.add_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Add Product',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // ── Filter chips ───────────────────────────────────────
                  SizedBox(
                    height: 36,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _filters.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, i) {
                        final f = _filters[i];
                        final sel = f == _filter;
                        final isOutOfStock = f == 'Out of Stock';
                        return GestureDetector(
                          onTap: () => setState(() => _filter = f),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: sel
                                  ? (isOutOfStock
                                        ? Colors.red
                                        : AppTheme.primary)
                                  : AppTheme.surface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: sel
                                    ? (isOutOfStock
                                          ? Colors.red
                                          : AppTheme.primary)
                                    : AppTheme.divider,
                              ),
                            ),
                            child: Text(
                              _filterLabel(f),
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: sel ? Colors.white : AppTheme.muted,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${docs.length} result${docs.length == 1 ? "" : "s"}',
                    style: AppTheme.body.copyWith(fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: docs.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off_rounded,
                            color: AppTheme.muted.withValues(alpha: 0.4),
                            size: 52,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No products in "$_filter"',
                            style: AppTheme.body.copyWith(fontSize: 13),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                      itemCount: docs.length,
                      itemBuilder: (_, i) => _SupplementCard(
                        doc: docs[i],
                        data: docs[i].data() as Map<String, dynamic>,
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }
}

// ── Supplement image widget — handles assets & network URLs ─────────────────
class _SupImage extends StatelessWidget {
  final String url;
  const _SupImage({required this.url});

  @override
  Widget build(BuildContext context) {
    const size = 70.0;
    final radius = BorderRadius.circular(12);

    Widget fallback = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppTheme.accent.withValues(alpha: 0.10),
        borderRadius: radius,
      ),
      child: const Icon(
        Icons.science_rounded,
        color: AppTheme.accent,
        size: 30,
      ),
    );

    if (url.isEmpty) return fallback;

    if (url.startsWith('assets/')) {
      return ClipRRect(
        borderRadius: radius,
        child: Image.asset(
          url,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => fallback,
        ),
      );
    }

    if (url.startsWith('http')) {
      return ClipRRect(
        borderRadius: radius,
        child: Image.network(
          url,
          width: size,
          height: size,
          fit: BoxFit.cover,
          loadingBuilder: (_, child, prog) {
            if (prog == null) return child;
            return Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: AppTheme.accent.withValues(alpha: 0.08),
                borderRadius: radius,
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppTheme.accent,
                ),
              ),
            );
          },
          errorBuilder: (_, __, ___) => fallback,
        ),
      );
    }

    return fallback;
  }
}

class _SupplementCard extends StatelessWidget {
  final QueryDocumentSnapshot doc;
  final Map<String, dynamic> data;
  const _SupplementCard({required this.doc, required this.data});

  @override
  Widget build(BuildContext context) {
    final qty = _safeInt(data['quantity']);
    final isLow = qty < 5;
    final isOut = qty == 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.card(radius: 16),
      child: Row(
        children: [
          // image — supports both assets/ and https:// URLs
          _SupImage(url: data['imageUrl'] as String? ?? ''),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['name'] as String? ?? '—',
                  style: AppTheme.subheading.copyWith(fontSize: 14),
                ),
                Text(
                  data['category'] as String? ?? '',
                  style: AppTheme.body.copyWith(fontSize: 11),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '\$${_safeDouble(data['price']).toStringAsFixed(2)}',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isOut
                            ? Colors.red.withValues(alpha: 0.12)
                            : isLow
                            ? Colors.orange.withValues(alpha: 0.12)
                            : Colors.green.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isOut
                            ? 'Out of Stock'
                            : isLow
                            ? 'Low ($qty)'
                            : 'In Stock ($qty)',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: isOut
                              ? Colors.red
                              : isLow
                              ? Colors.orange
                              : Colors.green,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Restock button
          GestureDetector(
            onTap: () => _showRestockDialog(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Restock',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _supIcon() => _SupImage(url: '');

  void _showRestockDialog(BuildContext context) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Restock: ${data['name']}',
          style: AppTheme.subheading.copyWith(fontSize: 15),
        ),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: AppTheme.inputDecoration(
            'Add quantity',
            Icons.add_box_rounded,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              final add = int.tryParse(ctrl.text.trim()) ?? 0;
              if (add > 0) {
                await FirebaseFirestore.instance
                    .collection('supplements')
                    .doc(doc.id)
                    .update({'quantity': FieldValue.increment(add)});
              }
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Update', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SUPERADMIN — SUPPLEMENT ORDERS TAB
// ═══════════════════════════════════════════════════════════════════════════════

class _SupplementOrdersTab extends StatefulWidget {
  @override
  State<_SupplementOrdersTab> createState() => _SupplementOrdersTabState();
}

class _SupplementOrdersTabState extends State<_SupplementOrdersTab> {
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Supplement Orders',
                style: AppTheme.heading.copyWith(fontSize: 22),
              ),
              const SizedBox(height: 12),
              _StatusFilter(
                selected: _filter,
                onChanged: (v) => setState(() => _filter = v),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('allOrders')
                .snapshots(),
            builder: (_, snap) {
              if (!snap.hasData) {
                return const Center(
                  child: CircularProgressIndicator(color: AppTheme.primary),
                );
              }
              var docs = snap.data!.docs;
              if (_filter != 'all') {
                docs = docs
                    .where((d) => (d.data() as Map)['status'] == _filter)
                    .toList();
              }
              if (docs.isEmpty) {
                return _EmptyState(label: 'No orders found');
              }
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                itemCount: docs.length,
                itemBuilder: (_, i) {
                  final d = docs[i];
                  final data = d.data() as Map<String, dynamic>;
                  return _FullOrderCard(data: data, docRef: d.reference);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _StatusFilter extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;
  const _StatusFilter({required this.selected, required this.onChanged});

  static const _options = [
    ('all', 'All'),
    ('processing', 'Processing'),
    ('completed', 'Completed'),
    ('failed', 'Failed'),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _options.map((o) {
          final sel = o.$1 == selected;
          return GestureDetector(
            onTap: () => onChanged(o.$1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: sel ? AppTheme.primary : AppTheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: sel ? AppTheme.primary : AppTheme.divider,
                ),
              ),
              child: Text(
                o.$2,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: sel ? Colors.white : AppTheme.muted,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _FullOrderCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final DocumentReference docRef;
  const _FullOrderCard({required this.data, required this.docRef});

  @override
  Widget build(BuildContext context) {
    final status = data['status'] as String? ?? 'processing';
    final date = (data['date'] as Timestamp?)?.toDate();
    final items = (data['items'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: AppTheme.card(radius: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['userEmail'] as String? ?? '—',
                        style: AppTheme.subheading.copyWith(fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        date != null
                            ? '${date.day}/${date.month}/${date.year}  ${date.hour}:${date.minute.toString().padLeft(2, '0')}'
                            : '—',
                        style: AppTheme.body.copyWith(fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Text(
                  '\$${_safeDouble(data['total']).toStringAsFixed(2)}',
                  style: AppTheme.subheading.copyWith(
                    fontSize: 15,
                    color: AppTheme.primary,
                  ),
                ),
              ],
            ),
          ),
          // Items
          if (items.isNotEmpty) ...[
            const Divider(color: AppTheme.divider, height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
              child: Column(
                children: items
                    .map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.science_rounded,
                              color: AppTheme.accent,
                              size: 14,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${item['name']} × ${item['qty']}',
                                style: AppTheme.body.copyWith(fontSize: 12),
                              ),
                            ),
                            Text(
                              '\$${_safeDouble(item['price']).toStringAsFixed(2)}',
                              style: AppTheme.body.copyWith(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
          // Status + address
          const Divider(color: AppTheme.divider, height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if ((data['address'] as String? ?? '').isNotEmpty)
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_rounded,
                              color: AppTheme.muted,
                              size: 13,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                data['address'] as String,
                                style: AppTheme.body.copyWith(fontSize: 11),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                // Status dropdown
                _StatusDropdown(
                  status: status,
                  onChanged: (newStatus) async {
                    // Update allOrders (admin view)
                    await docRef.update({'status': newStatus});
                    // Also update the user's own order so they see it live
                    final userId = data['userId'] as String? ?? '';
                    final orderId = data['id'] as String? ?? '';
                    if (userId.isNotEmpty && orderId.isNotEmpty) {
                      await FirebaseFirestore.instance
                          .collection('orders')
                          .doc(userId)
                          .collection('userOrders')
                          .doc(orderId)
                          .update({'status': newStatus});
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusDropdown extends StatelessWidget {
  final String status;
  final ValueChanged<String> onChanged;
  const _StatusDropdown({required this.status, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
      ),
      child: DropdownButton<String>(
        value: status,
        isDense: true,
        underline: const SizedBox(),
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppTheme.primary,
        ),
        items: const [
          DropdownMenuItem(value: 'processing', child: Text('Processing')),
          DropdownMenuItem(value: 'completed', child: Text('Completed')),
          DropdownMenuItem(value: 'failed', child: Text('Failed')),
        ],
        onChanged: (v) {
          if (v != null) onChanged(v);
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SUPERADMIN — CONSULTATIONS TAB
// ═══════════════════════════════════════════════════════════════════════════════

class _ConsultationsTab extends StatefulWidget {
  @override
  State<_ConsultationsTab> createState() => _ConsultationsTabState();
}

class _ConsultationsTabState extends State<_ConsultationsTab> {
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Consultations',
                style: AppTheme.heading.copyWith(fontSize: 22),
              ),
              const SizedBox(height: 12),
              _StatusFilter(
                selected: _filter,
                onChanged: (v) => setState(() => _filter = v),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('bookings')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (_, snap) {
              if (!snap.hasData) {
                return const Center(
                  child: CircularProgressIndicator(color: AppTheme.primary),
                );
              }
              var docs = snap.data!.docs;
              if (_filter != 'all') {
                docs = docs
                    .where((d) => (d.data() as Map)['status'] == _filter)
                    .toList();
              }
              if (docs.isEmpty) {
                return _EmptyState(label: 'No consultations found');
              }
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                itemCount: docs.length,
                itemBuilder: (_, i) {
                  final d = docs[i];
                  final data = d.data() as Map<String, dynamic>;
                  return _ConsultationCard(data: data, docId: d.id);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ConsultationCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String docId;
  const _ConsultationCard({required this.data, required this.docId});

  @override
  Widget build(BuildContext context) {
    final status = data['status'] as String? ?? 'pending';
    final statusColor = status == 'confirmed'
        ? Colors.green
        : status == 'cancelled'
        ? Colors.red
        : Colors.orange;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: AppTheme.card(radius: 18),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.video_call_rounded,
                    color: AppTheme.accent,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['specialistName'] as String? ?? '—',
                        style: AppTheme.subheading.copyWith(fontSize: 14),
                      ),
                      Text(
                        data['specialty'] as String? ?? '',
                        style: AppTheme.body.copyWith(fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Text(
                  '\$${_safeDouble(data['price']).toStringAsFixed(0)}',
                  style: AppTheme.subheading.copyWith(
                    fontSize: 15,
                    color: AppTheme.primary,
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: AppTheme.divider, height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today_rounded,
                  color: AppTheme.muted,
                  size: 13,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${data['date'] ?? '—'}  ${data['time'] ?? ''}',
                    style: AppTheme.body.copyWith(fontSize: 12),
                  ),
                ),
                // Status badge + change button
                GestureDetector(
                  onTap: () => _changeStatus(context, docId, status),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Text(
                          status,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: statusColor,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.edit_rounded, size: 11, color: statusColor),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if ((data['address'] as String? ?? '').isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: [
                  const Icon(
                    Icons.location_on_rounded,
                    color: AppTheme.muted,
                    size: 13,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      data['address'] as String,
                      style: AppTheme.body.copyWith(fontSize: 11),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _changeStatus(BuildContext context, String docId, String current) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Text(
              'Update Status',
              style: AppTheme.subheading.copyWith(fontSize: 16),
            ),
            const SizedBox(height: 12),
            ...['pending', 'confirmed', 'cancelled'].map((s) {
              final col = s == 'confirmed'
                  ? Colors.green
                  : s == 'cancelled'
                  ? Colors.red
                  : Colors.orange;
              return ListTile(
                leading: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: col.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.circle, color: col, size: 12),
                ),
                title: Text(
                  s,
                  style: AppTheme.subheading.copyWith(fontSize: 14),
                ),
                trailing: current == s
                    ? const Icon(Icons.check_rounded, color: AppTheme.primary)
                    : null,
                onTap: () async {
                  await FirebaseFirestore.instance
                      .collection('bookings')
                      .doc(docId)
                      .update({'status': s});
                  if (context.mounted) Navigator.pop(context);
                },
              );
            }),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SUPERADMIN — FEEDBACK TAB
// ═══════════════════════════════════════════════════════════════════════════════

class _FeedbackTab extends StatefulWidget {
  @override
  State<_FeedbackTab> createState() => _FeedbackTabState();
}

class _FeedbackTabState extends State<_FeedbackTab> {
  int _starFilter = 0; // 0 = all

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('feedback')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (_, snap) {
        if (!snap.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primary),
          );
        }
        var docs = snap.data!.docs;
        if (_starFilter > 0) {
          docs = docs.where((d) {
            final r = _safeInt((d.data() as Map)['rating']);
            return r == _starFilter;
          }).toList();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'User Feedback',
                    style: AppTheme.heading.copyWith(fontSize: 22),
                  ),
                  Text(
                    '${snap.data!.docs.length} total reviews',
                    style: AppTheme.body.copyWith(fontSize: 12),
                  ),
                  const SizedBox(height: 14),
                  // ── Star filter row ──────────────────────────────────
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _StarChip(
                          label: 'All',
                          selected: _starFilter == 0,
                          onTap: () => setState(() => _starFilter = 0),
                        ),
                        const SizedBox(width: 8),
                        ...List.generate(5, (i) {
                          final star = 5 - i;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _StarChip(
                              label: '$star★',
                              selected: _starFilter == star,
                              color: star <= 2
                                  ? Colors.red
                                  : star == 3
                                  ? Colors.orange
                                  : Colors.green,
                              onTap: () => setState(() => _starFilter = star),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${docs.length} result${docs.length == 1 ? "" : "s"}',
                    style: AppTheme.body.copyWith(fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: docs.isEmpty
                  ? _EmptyState(label: 'No feedback found')
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                      itemCount: docs.length,
                      itemBuilder: (_, i) => _FeedbackCard(
                        docId: docs[i].id,
                        data: docs[i].data() as Map<String, dynamic>,
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _StarChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  const _StarChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.color = const Color(0xFF5C3D2E),
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color : AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? color : AppTheme.divider),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppTheme.muted,
          ),
        ),
      ),
    );
  }
}

class _FeedbackCard extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;
  const _FeedbackCard({required this.docId, required this.data});

  @override
  Widget build(BuildContext context) {
    final rating = _safeInt(data['rating']);
    final replied = data['adminReplied'] as bool? ?? false;
    final adminNote = data['adminNote'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppTheme.card(radius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar circle
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      (data['userName'] as String? ?? 'A')
                          .substring(0, 1)
                          .toUpperCase(),
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['userName'] as String? ??
                            data['userEmail'] as String? ??
                            'Anonymous',
                        style: AppTheme.subheading.copyWith(fontSize: 14),
                      ),
                      Text(
                        data['productName'] as String? ?? '',
                        style: AppTheme.body.copyWith(fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Star rating
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      children: List.generate(
                        5,
                        (i) => Icon(
                          i < rating
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          color: Colors.amber,
                          size: 15,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(data['createdAt'] as Timestamp?),
                      style: AppTheme.body.copyWith(fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Comment
          if ((data['comment'] as String? ?? '').isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Text(
                data['comment'] as String,
                style: AppTheme.body.copyWith(
                  fontSize: 13,
                  height: 1.5,
                  color: AppTheme.dark,
                ),
              ),
            ),
          // Admin note (if any)
          if (adminNote.isNotEmpty)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppTheme.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.admin_panel_settings_rounded,
                    color: AppTheme.primary,
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Admin note: $adminNote',
                      style: AppTheme.body.copyWith(
                        fontSize: 12,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          // Action buttons
          const Divider(color: AppTheme.divider, height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: Row(
              children: [
                // Replied badge
                if (replied)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          color: Colors.green,
                          size: 12,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Noted',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            color: Colors.green,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                const Spacer(),
                // Note button
                _ActionBtn(
                  icon: Icons.edit_note_rounded,
                  label: adminNote.isEmpty ? 'Add Note' : 'Edit Note',
                  color: AppTheme.primary,
                  onTap: () => _showNoteDialog(context, adminNote),
                ),
                const SizedBox(width: 8),
                // Mark noted / un-note
                _ActionBtn(
                  icon: replied
                      ? Icons.remove_done_rounded
                      : Icons.done_all_rounded,
                  label: replied ? 'Unmark' : 'Mark Noted',
                  color: replied ? AppTheme.muted : Colors.green,
                  onTap: () async {
                    await FirebaseFirestore.instance
                        .collection('feedback')
                        .doc(docId)
                        .update({'adminReplied': !replied});
                  },
                ),
                const SizedBox(width: 8),
                // Delete button
                _ActionBtn(
                  icon: Icons.delete_outline_rounded,
                  label: 'Delete',
                  color: Colors.red,
                  onTap: () => _confirmDelete(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showNoteDialog(BuildContext context, String current) {
    final ctrl = TextEditingController(text: current);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Admin Note',
          style: AppTheme.subheading.copyWith(fontSize: 15),
        ),
        content: TextField(
          controller: ctrl,
          maxLines: 3,
          decoration: AppTheme.inputDecoration(
            'Write a note...',
            Icons.edit_note_rounded,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('feedback')
                  .doc(docId)
                  .update({'adminNote': ctrl.text.trim()});
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Delete Review?',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        content: const Text(
          'This will permanently remove this review. This cannot be undone.',
          style: TextStyle(fontFamily: 'Poppins', fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(fontFamily: 'Poppins'),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('feedback')
                  .doc(docId)
                  .delete();
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.white, fontFamily: 'Poppins'),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(Timestamp? ts) {
    if (ts == null) return '';
    final d = ts.toDate();
    return '${d.day}/${d.month}/${d.year}';
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// RESTAURANT — MY MEALS TAB (edit meal prices & details)
// ═══════════════════════════════════════════════════════════════════════════════

class _RestaurantMealsTab extends StatefulWidget {
  final String restaurantId;
  final String restaurantName;
  const _RestaurantMealsTab({
    required this.restaurantId,
    required this.restaurantName,
  });

  @override
  State<_RestaurantMealsTab> createState() => _RestaurantMealsTabState();
}

class _RestaurantMealsTabState extends State<_RestaurantMealsTab> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('resturants')
          .doc(widget.restaurantId)
          .collection('meals')
          .snapshots(),
      builder: (_, snap) {
        if (!snap.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primary),
          );
        }
        final docs = snap.data!.docs;
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
          children: [
            Text(
              widget.restaurantName,
              style: AppTheme.heading.copyWith(fontSize: 22),
            ),
            Text(
              '${docs.length} meals on your menu',
              style: AppTheme.body.copyWith(fontSize: 12),
            ),
            const SizedBox(height: 16),
            if (docs.isEmpty)
              _EmptyState(
                label: 'No meals found in Firestore for this restaurant',
              ),
            ...docs.map(
              (d) => _MealEditCard(
                docRef: d.reference,
                data: d.data() as Map<String, dynamic>,
              ),
            ),
            // Add Meal button
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => _showAddMealDialog(context),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AppTheme.primary.withValues(alpha: 0.3),
                    width: 1.5,
                    strokeAlign: BorderSide.strokeAlignInside,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_circle_outline_rounded,
                      color: AppTheme.primary,
                      size: 20,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Add New Meal',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showAddMealDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final kcalCtrl = TextEditingController();
    final proteinCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Add New Meal',
          style: AppTheme.subheading.copyWith(fontSize: 16),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: AppTheme.inputDecoration(
                  'Meal name',
                  Icons.restaurant_menu_rounded,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: descCtrl,
                maxLines: 2,
                decoration: AppTheme.inputDecoration(
                  'Description',
                  Icons.description_rounded,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: priceCtrl,
                keyboardType: TextInputType.number,
                decoration: AppTheme.inputDecoration(
                  'Price (\$)',
                  Icons.attach_money_rounded,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: kcalCtrl,
                decoration: AppTheme.inputDecoration(
                  'Calories (e.g. 450 kcal)',
                  Icons.local_fire_department_rounded,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: proteinCtrl,
                decoration: AppTheme.inputDecoration(
                  'Protein (e.g. 32g)',
                  Icons.fitness_center_rounded,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              final name = nameCtrl.text.trim();
              final price = double.tryParse(priceCtrl.text.trim()) ?? 0.0;
              if (name.isEmpty) return;
              await FirebaseFirestore.instance
                  .collection('resturants')
                  .doc(widget.restaurantId)
                  .collection('meals')
                  .add({
                    'name': name,
                    'description': descCtrl.text.trim(),
                    'price': price,
                    'kcal': kcalCtrl.text.trim(),
                    'protein': proteinCtrl.text.trim(),
                    'available': true,
                    'createdAt': FieldValue.serverTimestamp(),
                  });
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text(
              'Add Meal',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _MealEditCard extends StatelessWidget {
  final DocumentReference docRef;
  final Map<String, dynamic> data;
  const _MealEditCard({required this.docRef, required this.data});

  @override
  Widget build(BuildContext context) {
    final available = data['available'] as bool? ?? true;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: AppTheme.card(radius: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Meal image if available
          if ((data['mealAsset'] as String? ?? '').isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18),
              ),
              child: Image.asset(
                data['mealAsset'] as String,
                height: 130,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        data['name'] as String? ?? '—',
                        style: AppTheme.subheading.copyWith(fontSize: 15),
                      ),
                    ),
                    // Available toggle
                    GestureDetector(
                      onTap: () async {
                        await docRef.update({'available': !available});
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: available
                              ? Colors.green.withValues(alpha: 0.12)
                              : Colors.red.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          available ? 'Available' : 'Unavailable',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: available ? Colors.green : Colors.red,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  data['description'] as String? ?? '',
                  style: AppTheme.body.copyWith(fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _MacroChip(
                      Icons.attach_money_rounded,
                      '\$${_safeDouble(data['price']).toStringAsFixed(2)}',
                      AppTheme.primary,
                    ),
                    const SizedBox(width: 8),
                    _MacroChip(
                      Icons.local_fire_department_rounded,
                      data['kcal'] as String? ?? '—',
                      Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    _MacroChip(
                      Icons.fitness_center_rounded,
                      data['protein'] as String? ?? '—',
                      Colors.blue,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Edit button
                SizedBox(
                  width: double.infinity,
                  child: GestureDetector(
                    onTap: () => _showEditDialog(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.edit_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Edit Meal',
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
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    final nameCtrl = TextEditingController(text: data['name'] as String? ?? '');
    final descCtrl = TextEditingController(
      text: data['description'] as String? ?? '',
    );
    final priceCtrl = TextEditingController(
      text: (data['price'] as num?)?.toString() ?? '',
    );
    final kcalCtrl = TextEditingController(text: data['kcal'] as String? ?? '');
    final proteinCtrl = TextEditingController(
      text: data['protein'] as String? ?? '',
    );

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Edit Meal',
          style: AppTheme.subheading.copyWith(fontSize: 16),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: AppTheme.inputDecoration(
                  'Meal name',
                  Icons.restaurant_menu_rounded,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: descCtrl,
                maxLines: 2,
                decoration: AppTheme.inputDecoration(
                  'Description',
                  Icons.description_rounded,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: priceCtrl,
                keyboardType: TextInputType.number,
                decoration: AppTheme.inputDecoration(
                  'Price (\$)',
                  Icons.attach_money_rounded,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: kcalCtrl,
                decoration: AppTheme.inputDecoration(
                  'Calories',
                  Icons.local_fire_department_rounded,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: proteinCtrl,
                decoration: AppTheme.inputDecoration(
                  'Protein',
                  Icons.fitness_center_rounded,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              await docRef.update({
                'name': nameCtrl.text.trim(),
                'description': descCtrl.text.trim(),
                'price':
                    double.tryParse(priceCtrl.text.trim()) ?? data['price'],
                'kcal': kcalCtrl.text.trim(),
                'protein': proteinCtrl.text.trim(),
              });
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text(
              'Save Changes',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _MacroChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _MacroChip(this.icon, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// RESTAURANT — MEAL ORDERS TAB
// ═══════════════════════════════════════════════════════════════════════════════

class _MealOrdersTab extends StatefulWidget {
  final String restaurantId;
  const _MealOrdersTab({required this.restaurantId});

  @override
  State<_MealOrdersTab> createState() => _MealOrdersTabState();
}

class _MealOrdersTabState extends State<_MealOrdersTab> {
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Meal Orders',
                style: AppTheme.heading.copyWith(fontSize: 22),
              ),
              const SizedBox(height: 12),
              _StatusFilter(
                selected: _filter,
                onChanged: (v) => setState(() => _filter = v),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('mealOrders')
                .where('restaurantId', isEqualTo: widget.restaurantId)
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (_, snap) {
              if (!snap.hasData) {
                return const Center(
                  child: CircularProgressIndicator(color: AppTheme.primary),
                );
              }
              var docs = snap.data!.docs;
              if (_filter != 'all') {
                docs = docs
                    .where((d) => (d.data() as Map)['status'] == _filter)
                    .toList();
              }
              if (docs.isEmpty) {
                return _EmptyState(label: 'No meal orders yet');
              }
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                itemCount: docs.length,
                itemBuilder: (_, i) {
                  final d = docs[i];
                  final data = d.data() as Map<String, dynamic>;
                  return _FullOrderCard(data: data, docRef: d.reference);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SHARED UTILITY WIDGETS
// ═══════════════════════════════════════════════════════════════════════════════

class _EmptyState extends StatelessWidget {
  final String label;
  const _EmptyState({required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(
              Icons.inbox_rounded,
              color: AppTheme.muted.withValues(alpha: 0.4),
              size: 60,
            ),
            const SizedBox(height: 14),
            Text(
              label,
              textAlign: TextAlign.center,
              style: AppTheme.body.copyWith(fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
