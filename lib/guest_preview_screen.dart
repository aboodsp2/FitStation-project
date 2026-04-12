import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'auth_screen.dart';

// ── Shared guest wall bottom sheet ──────────────────────────────────────────

void showGuestSignupSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(28, 20, 28, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 28),
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppTheme.accent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lock_outline_rounded,
              color: AppTheme.accent,
              size: 34,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Create an Account',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppTheme.dark,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Sign up to unlock training plans, meal plans, supplements, consultations and more.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              height: 1.6,
              color: AppTheme.muted,
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const AuthFlowHandler()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Sign Up — It\'s Free',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const AuthFlowHandler()),
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: AppTheme.primary, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Already have an account? Log In',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
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

// ── Shared locked overlay widget ─────────────────────────────────────────────

Widget lockedOverlay(BuildContext context, {required Widget child}) {
  return Stack(
    children: [
      child,
      Positioned.fill(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.background.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock_rounded, color: Colors.white, size: 13),
                    SizedBox(width: 5),
                    Text(
                      'Sign up to unlock',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ],
  );
}

// ── Shared app bar ────────────────────────────────────────────────────────────

PreferredSizeWidget guestAppBar(BuildContext context, String title) {
  return AppBar(
    backgroundColor: AppTheme.background,
    elevation: 0,
    surfaceTintColor: Colors.transparent,
    leading: IconButton(
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: AppTheme.primary,
          size: 16,
        ),
      ),
      onPressed: () => Navigator.pop(context),
    ),
    title: Text(
      title,
      style: const TextStyle(
        fontFamily: 'Poppins',
        color: AppTheme.dark,
        fontSize: 17,
        fontWeight: FontWeight.w700,
      ),
    ),
    actions: [
      GestureDetector(
        onTap: () => showGuestSignupSheet(context),
        child: Container(
          margin: const EdgeInsets.only(right: 16),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: AppTheme.primary,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            'Sign Up',
            style: TextStyle(
              fontFamily: 'Poppins',
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    ],
    bottom: PreferredSize(
      preferredSize: const Size.fromHeight(1),
      child: Divider(color: AppTheme.divider, height: 1),
    ),
  );
}

// ════════════════════════════════════════════════════════════════════════════
// 1. TRAINING PLAN PREVIEW
// ════════════════════════════════════════════════════════════════════════════

class GuestTrainingPreview extends StatelessWidget {
  const GuestTrainingPreview({super.key});

  static const _levels = [
    {
      'title': 'Beginner',
      'subtitle': 'Start your journey',
      'desc':
          'Foundational exercises to build core strength and healthy movement patterns.',
      'badge': 'LEVEL 1',
      'icon': Icons.self_improvement_rounded,
      'accent': Color(0xFF6BAF6B),
    },
    {
      'title': 'Intermediate',
      'subtitle': 'Level up your game',
      'desc':
          'Challenging routines with compound movements and higher intensity.',
      'badge': 'LEVEL 2',
      'icon': Icons.fitness_center_rounded,
      'accent': Color(0xFFC9A87C),
    },
    {
      'title': 'Advanced',
      'subtitle': 'Dominate every rep',
      'desc':
          'High-intensity programming for experienced athletes pushing their limits.',
      'badge': 'LEVEL 3',
      'icon': Icons.local_fire_department_rounded,
      'accent': Color(0xFF5C3D2E),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: guestAppBar(context, 'Training Plans'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        children: [
          // Preview banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.accent.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.accent.withValues(alpha: 0.3)),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.visibility_rounded,
                  color: AppTheme.accent,
                  size: 18,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Preview mode — sign up to start training',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          ..._levels.map(
            (level) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: GestureDetector(
                onTap: () => showGuestSignupSheet(context),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppTheme.divider),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withValues(alpha: 0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: (level['accent'] as Color).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          level['icon'] as IconData,
                          color: level['accent'] as Color,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  level['title'] as String,
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.dark,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: (level['accent'] as Color)
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(5),
                                    border: Border.all(
                                      color: (level['accent'] as Color)
                                          .withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Text(
                                    level['badge'] as String,
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: level['accent'] as Color,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              level['subtitle'] as String,
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: level['accent'] as Color,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              level['desc'] as String,
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                height: 1.5,
                                color: AppTheme.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.lock_rounded,
                        color: AppTheme.muted,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Muscles preview
          const SizedBox(height: 8),
          Text(
            'Muscle Groups Included',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.dark,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['Chest', 'Back', 'Legs', 'Shoulders', 'Arms', 'Core']
                .map(
                  (m) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.divider),
                    ),
                    child: Text(
                      m,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 28),
          _signUpCta(context),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// 2. SUPPLEMENTS PREVIEW
// ════════════════════════════════════════════════════════════════════════════

class GuestSupplementsPreview extends StatelessWidget {
  const GuestSupplementsPreview({super.key});

  static const _items = [
    {
      'name': 'Whey Protein Gold',
      'category': 'Proteins & Recovery',
      'price': 45.0,
      'icon': Icons.science_rounded,
    },
    {
      'name': 'Pre-Workout Blast',
      'category': 'Pre-Workouts',
      'price': 32.0,
      'icon': Icons.bolt_rounded,
    },
    {
      'name': 'Creatine Monohydrate',
      'category': 'Creatine & Performance',
      'price': 28.0,
      'icon': Icons.fitness_center_rounded,
    },
    {
      'name': 'BCAA Complex',
      'category': 'Proteins & Recovery',
      'price': 38.0,
      'icon': Icons.biotech_rounded,
    },
    {
      'name': 'Mass Gainer Pro',
      'category': 'Mass Gainers',
      'price': 62.0,
      'icon': Icons.monitor_weight_rounded,
    },
    {
      'name': 'Vitamin D3 + K2',
      'category': 'Vitamins & Health',
      'price': 18.0,
      'icon': Icons.local_pharmacy_rounded,
    },
  ];

  static const _categories = [
    'Pre-Workouts',
    'Proteins & Recovery',
    'Mass Gainers',
    'Creatine & Performance',
    'Vitamins & Health',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: guestAppBar(context, 'Supplement Store'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        children: [
          // Preview banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.accent.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.accent.withValues(alpha: 0.3)),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.storefront_rounded,
                  color: AppTheme.accent,
                  size: 18,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Browse our supplement store — sign up to purchase',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Categories row
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) => Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: i == 0 ? AppTheme.primary : AppTheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: i == 0 ? AppTheme.primary : AppTheme.divider,
                  ),
                ),
                child: Text(
                  _categories[i],
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: i == 0 ? Colors.white : AppTheme.muted,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Product grid (locked)
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 0.82,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            children: _items
                .map(
                  (item) => GestureDetector(
                    onTap: () => showGuestSignupSheet(context),
                    child: lockedOverlay(
                      context,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.divider),
                        ),
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: AppTheme.accent.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                item['icon'] as IconData,
                                color: AppTheme.accent,
                                size: 24,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              item['name'] as String,
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.dark,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item['category'] as String,
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 10,
                                color: AppTheme.muted,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Text(
                                  '\$${(item['price'] as double).toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.primary,
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppTheme.accent.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.add_rounded,
                                    color: AppTheme.accent,
                                    size: 16,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 28),
          _signUpCta(context),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// 3. MEAL PLAN PREVIEW
// ════════════════════════════════════════════════════════════════════════════

class GuestMealPreview extends StatelessWidget {
  const GuestMealPreview({super.key});

  static const _goals = [
    {
      'label': 'Weight Loss',
      'icon': Icons.trending_down_rounded,
      'cal': '1,500 kcal/day',
      'color': Color(0xFF6BAF6B),
    },
    {
      'label': 'Maintain',
      'icon': Icons.balance_rounded,
      'cal': '2,000 kcal/day',
      'color': Color(0xFFC9A87C),
    },
    {
      'label': 'Muscle Gain',
      'icon': Icons.trending_up_rounded,
      'cal': '2,800 kcal/day',
      'color': Color(0xFF5C3D2E),
    },
  ];

  static const _sampleMeals = [
    {
      'time': 'Breakfast',
      'meal': 'Oatmeal with berries & almond milk',
      'icon': Icons.wb_sunny_rounded,
    },
    {
      'time': 'Lunch',
      'meal': 'Grilled chicken breast + quinoa salad',
      'icon': Icons.wb_cloudy_rounded,
    },
    {
      'time': 'Dinner',
      'meal': 'Steamed fish + broccoli & sweet potato',
      'icon': Icons.nightlight_rounded,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: guestAppBar(context, 'Meal Plans'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.accent.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.accent.withValues(alpha: 0.3)),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.restaurant_menu_rounded,
                  color: AppTheme.accent,
                  size: 18,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Personalized meal plans for your goals — sign up to access',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Goal cards
          Text(
            'Choose Your Goal',
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.dark,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: _goals
                .map(
                  (g) => Expanded(
                    child: GestureDetector(
                      onTap: () => showGuestSignupSheet(context),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 10,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppTheme.divider),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primary.withValues(alpha: 0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Icon(
                              g['icon'] as IconData,
                              color: g['color'] as Color,
                              size: 24,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              g['label'] as String,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.dark,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              g['cal'] as String,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 9,
                                color: AppTheme.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 24),
          // Sample plan (locked)
          Text(
            'Sample Plan — Lean Green',
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.dark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Weight Loss • \$35/week',
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              color: AppTheme.muted,
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => showGuestSignupSheet(context),
            child: lockedOverlay(
              context,
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.divider),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: _sampleMeals
                      .map(
                        (m) => Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppTheme.accent.withValues(alpha: 0.10),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  m['icon'] as IconData,
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
                                      m['time'] as String,
                                      style: const TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.muted,
                                      ),
                                    ),
                                    Text(
                                      m['meal'] as String,
                                      style: const TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.dark,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),
          _signUpCta(context),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// 4. CONSULTATION PREVIEW
// ════════════════════════════════════════════════════════════════════════════

class GuestConsultationPreview extends StatelessWidget {
  const GuestConsultationPreview({super.key});

  static const _trainers = [
    {
      'name': 'Ahmed Al-Rashid',
      'specialty': 'Strength & Conditioning',
      'rating': '4.9',
      'price': '\$60/session',
    },
    {
      'name': 'Sara Mansour',
      'specialty': 'Nutrition & Weight Loss',
      'rating': '4.8',
      'price': '\$55/session',
    },
    {
      'name': 'Khalid Nasser',
      'specialty': 'Muscle Building',
      'rating': '4.7',
      'price': '\$65/session',
    },
    {
      'name': 'Lara Haddad',
      'specialty': 'Yoga & Recovery',
      'rating': '5.0',
      'price': '\$50/session',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: guestAppBar(context, 'Consultation'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.accent.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.accent.withValues(alpha: 0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.people_rounded, color: AppTheme.accent, size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Book 1-on-1 sessions with certified trainers — sign up to book',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Our Trainers',
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.dark,
            ),
          ),
          const SizedBox(height: 12),
          ..._trainers.map(
            (t) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () => showGuestSignupSheet(context),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.divider),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Avatar
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: AppTheme.accent.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            (t['name'] as String)
                                .split(' ')
                                .map((w) => w[0])
                                .take(2)
                                .join(),
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t['name'] as String,
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.dark,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              t['specialty'] as String,
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                color: AppTheme.muted,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  color: Color(0xFFF5A623),
                                  size: 14,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  t['rating'] as String,
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.dark,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  t['price'] as String,
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Icon(
                        Icons.lock_rounded,
                        color: AppTheme.muted,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Locked booking form preview
          GestureDetector(
            onTap: () => showGuestSignupSheet(context),
            child: lockedOverlay(
              context,
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.divider),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Book a Session',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.dark,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _fakeField('Select Trainer', Icons.person_rounded),
                    const SizedBox(height: 10),
                    _fakeField('Pick a Date', Icons.calendar_today_rounded),
                    const SizedBox(height: 10),
                    _fakeField('Select Time Slot', Icons.access_time_rounded),
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Text(
                          'Confirm Booking',
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
            ),
          ),
          const SizedBox(height: 28),
          _signUpCta(context),
        ],
      ),
    );
  }

  Widget _fakeField(String hint, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.muted, size: 18),
          const SizedBox(width: 10),
          Text(
            hint,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              color: AppTheme.muted,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared Sign Up CTA ───────────────────────────────────────────────────────

Widget _signUpCta(BuildContext context) {
  return GestureDetector(
    onTap: () => showGuestSignupSheet(context),
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: AppTheme.primary,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_open_rounded, color: Colors.white, size: 18),
          SizedBox(width: 8),
          Text(
            'Sign Up to Unlock Full Access',
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
  );
}
