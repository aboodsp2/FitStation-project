import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'training_plan_screen_new.dart';
import 'app_theme.dart';

class LevelSelectionScreen extends StatefulWidget {
  const LevelSelectionScreen({super.key});

  @override
  State<LevelSelectionScreen> createState() => _LevelSelectionScreenState();
}

class _LevelSelectionScreenState extends State<LevelSelectionScreen>
    with TickerProviderStateMixin {
  String? _gender;
  bool _loading = true;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final List<_LevelData> _levels = [
    _LevelData(
      title: 'Beginner',
      subtitle: 'Start your journey',
      description:
          'Simple, foundational exercises designed to build core strength and establish healthy movement patterns.',
      icon: Icons.self_improvement_rounded,
      accent: const Color(0xFF6BAF6B),
      tag: 'beginner',
      badge: 'LEVEL 1',
    ),
    _LevelData(
      title: 'Intermediate',
      subtitle: 'Level up your game',
      description:
          'Challenging routines that push your limits and accelerate progress with compound movements and higher intensity.',
      icon: Icons.fitness_center_rounded,
      accent: AppTheme.accent,
      tag: 'intermediate',
      badge: 'LEVEL 2',
    ),
    _LevelData(
      title: 'Advanced',
      subtitle: 'Dominate every rep',
      description:
          'High-intensity programming built for experienced athletes ready to push beyond their perceived limits.',
      icon: Icons.local_fire_department_rounded,
      accent: AppTheme.primary,
      tag: 'advanced',
      badge: 'LEVEL 3',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );
    _fetchGender();
  }

  Future<void> _fetchGender() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .get();
        setState(() {
          _gender = (doc.data()?['gender'] as String?)?.toLowerCase() ?? 'male';
          _loading = false;
        });
      } else {
        setState(() {
          _gender = 'male';
          _loading = false;
        });
      }
    } catch (_) {
      setState(() {
        _gender = 'male';
        _loading = false;
      });
    }
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _onSelectLevel(String level) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, animation, _) =>
            TrainingPlanScreen(level: level, gender: _gender ?? 'male'),
        transitionsBuilder: (_, animation, _, child) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(0.05, 0),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
            child: child,
          ),
        ),
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: _loading
          ? Center(child: CircularProgressIndicator(color: AppTheme.accent))
          : CustomScrollView(
              slivers: [
                _buildSliverAppBar(),
                SliverToBoxAdapter(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildGenderBadge(),
                            const SizedBox(height: 24),
                            ..._buildLevelCards(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 160,
      pinned: true,
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
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppTheme.primary,
            size: 16,
          ),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
        title: Text(
          'Choose Your\nLevel',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppTheme.dark,
            letterSpacing: -0.3,
            height: 1.2,
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(color: AppTheme.background),
            // Subtle warm gradient top-right
            Positioned(
              right: -20,
              top: -20,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.accent.withValues(alpha: 0.09),
                ),
              ),
            ),
            Positioned(
              right: 40,
              top: 30,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primary.withValues(alpha: 0.06),
                ),
              ),
            ),
            // Bottom divider
            Positioned(
              bottom: 0,
              left: 20,
              right: 20,
              child: Divider(color: AppTheme.divider, height: 1),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenderBadge() {
    final isFemale = _gender == 'female';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppTheme.accent.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isFemale ? Icons.female_rounded : Icons.male_rounded,
            color: AppTheme.accent,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            isFemale ? 'Plans for Women' : 'Plans for Men',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildLevelCards() {
    return _levels.asMap().entries.map((entry) {
      final index = entry.key;
      final level = entry.value;
      return TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: Duration(milliseconds: 400 + index * 100),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) => Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _LevelCard(
            data: level,
            onTap: () => _onSelectLevel(level.tag),
          ),
        ),
      );
    }).toList();
  }
}

// ── Level Card ───────────────────────────────────────────────────────

class _LevelCard extends StatefulWidget {
  final _LevelData data;
  final VoidCallback onTap;

  const _LevelCard({required this.data, required this.onTap});

  @override
  State<_LevelCard> createState() => _LevelCardState();
}

class _LevelCardState extends State<_LevelCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressController;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.97,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _pressController.reverse(),
      onTapUp: (_) {
        _pressController.forward();
        widget.onTap();
      },
      onTapCancel: () => _pressController.forward(),
      child: AnimatedBuilder(
        animation: _pressController,
        builder: (_, child) =>
            Transform.scale(scale: _pressController.value, child: child),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withValues(alpha: 0.08),
                blurRadius: 18,
                offset: const Offset(0, 5),
              ),
            ],
            border: Border.all(color: AppTheme.divider),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                // Subtle accent tint in top-right corner
                Positioned(
                  right: -20,
                  top: -20,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.data.accent.withValues(alpha: 0.08),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icon
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: widget.data.accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          widget.data.icon,
                          color: widget.data.accent,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Text content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  widget.data.title,
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.dark,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Level badge
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: widget.data.accent.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(5),
                                    border: Border.all(
                                      color: widget.data.accent.withValues(
                                        alpha: 0.3,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    widget.data.badge,
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: widget.data.accent,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              widget.data.subtitle,
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: widget.data.accent,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.data.description,
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                height: 1.55,
                                color: AppTheme.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Arrow
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: widget.data.accent.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: widget.data.accent.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 13,
                          color: widget.data.accent,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LevelData {
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final Color accent;
  final String tag;
  final String badge;

  const _LevelData({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.accent,
    required this.tag,
    required this.badge,
  });
}
