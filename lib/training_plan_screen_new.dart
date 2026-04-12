import 'package:flutter/material.dart';
import 'exercise_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'app_theme.dart';

class TrainingPlanScreen extends StatefulWidget {
  final String level;
  final String gender;

  const TrainingPlanScreen({
    super.key,
    required this.level,
    required this.gender,
  });

  @override
  State<TrainingPlanScreen> createState() => _TrainingPlanScreenState();
}

class _TrainingPlanScreenState extends State<TrainingPlanScreen>
    with TickerProviderStateMixin {
  List<Map<String, dynamic>> _muscleGroups = [];
  bool _loading = true;
  String? _error;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // Level badge colors — warm tones matching AppTheme
  Map<String, Color> get _levelColor => {
    'beginner': const Color(0xFF6BAF6B), // soft green
    'intermediate': AppTheme.accent, // gold
    'advanced': AppTheme.primary, // deep brown
  };

  Color get _accent => _levelColor[widget.level] ?? AppTheme.accent;

  // Icon mapping per muscle group
  static const Map<String, IconData> _muscleIcons = {
    'chest': Icons.airline_seat_flat_rounded,
    'back': Icons.accessibility_new_rounded,
    'legs': Icons.directions_run_rounded,
    'shoulders': Icons.sports_gymnastics_rounded,
    'arms': Icons.sports_handball_rounded,
    'core': Icons.crop_square_rounded,
    'default': Icons.fitness_center_rounded,
  };

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _loadMuscleGroups();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadMuscleGroups() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('training_plans')
          .doc(widget.gender)
          .collection(widget.level)
          .get();

      if (snapshot.docs.isEmpty) {
        final fallback = await FirebaseFirestore.instance
            .collection('training_plans')
            .where('gender', isEqualTo: widget.gender)
            .where('level', isEqualTo: widget.level)
            .get();
        setState(() {
          _muscleGroups = fallback.docs
              .map((d) => {'id': d.id, ...d.data()})
              .toList();
          _loading = false;
        });
      } else {
        setState(() {
          _muscleGroups = snapshot.docs
              .map((d) => {'id': d.id, ...d.data()})
              .toList();
          _loading = false;
        });
      }
      _fadeController.forward();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  String get _levelLabel {
    switch (widget.level) {
      case 'beginner':
        return 'Beginner';
      case 'intermediate':
        return 'Intermediate';
      case 'advanced':
        return 'Advanced';
      default:
        return widget.level;
    }
  }

  IconData _iconForMuscle(String name) =>
      _muscleIcons[name.toLowerCase()] ?? _muscleIcons['default']!;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          if (_loading)
            SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(color: _accent)),
            )
          else if (_error != null)
            SliverFillRemaining(child: _buildError())
          else if (_muscleGroups.isEmpty)
            SliverFillRemaining(child: _buildEmpty())
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildMuscleCard(index),
                  childCount: _muscleGroups.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 210,
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
        titlePadding: const EdgeInsets.only(left: 20, bottom: 18),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$_levelLabel Plan',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppTheme.dark,
                letterSpacing: -0.3,
              ),
            ),
            Text(
              '${widget.gender == 'female' ? 'Women' : 'Men'} • ${_muscleGroups.length} muscle groups',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppTheme.muted,
              ),
            ),
          ],
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Warm cream base
            Container(color: AppTheme.background),
            // Subtle top gradient
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 210,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [_accent.withValues(alpha: 0.12), AppTheme.background],
                  ),
                ),
              ),
            ),
            // Decorative circle
            Positioned(
              right: -30,
              top: -30,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _accent.withValues(alpha: 0.08),
                ),
              ),
            ),
            // Level badge
            Positioned(
              right: 20,
              top: 70,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: _accent,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: _accent.withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  _levelLabel.toUpperCase(),
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
            // Divider line at bottom
            Positioned(
              bottom: 0,
              left: 20,
              right: 20,
              child: Divider(color: AppTheme.divider, thickness: 1),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMuscleCard(int index) {
    final group = _muscleGroups[index];
    final name =
        (group['name'] as String?) ?? group['id'] as String? ?? 'Unknown';
    final exerciseCount = group['exerciseCount'] as int? ?? 0;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 350 + index * 70),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: child,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: _MuscleGroupCard(
          name: name,
          exerciseCount: exerciseCount,
          icon: _iconForMuscle(name),
          accent: _accent,
          onTap: () => _onGroupTap(group),
        ),
      ),
    );
  }

  void _onGroupTap(Map<String, dynamic> group) {
    final name = (group['name'] as String? ?? group['id'] as String? ?? '')
        .toLowerCase();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ExerciseScreen(
          muscleGroup: name,
          level: widget.level,
          gender: widget.gender,
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 64, color: AppTheme.muted),
            const SizedBox(height: 16),
            Text('Something went wrong', style: AppTheme.subheading),
            const SizedBox(height: 8),
            Text(_error!, textAlign: TextAlign.center, style: AppTheme.body),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() => _loading = true);
                _loadMuscleGroups();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 14,
                ),
              ),
              child: const Text(
                'Retry',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.fitness_center_rounded,
              size: 72,
              color: AppTheme.accent.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 20),
            Text('No plans yet', style: AppTheme.subheading),
            const SizedBox(height: 10),
            Text(
              'No ${_levelLabel.toLowerCase()} plans found for ${widget.gender == 'female' ? 'women' : 'men'} yet.\nCheck back soon!',
              textAlign: TextAlign.center,
              style: AppTheme.body,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Muscle Group Card ────────────────────────────────────────────────

class _MuscleGroupCard extends StatefulWidget {
  final String name;
  final int exerciseCount;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;

  const _MuscleGroupCard({
    required this.name,
    required this.exerciseCount,
    required this.icon,
    required this.accent,
    required this.onTap,
  });

  @override
  State<_MuscleGroupCard> createState() => _MuscleGroupCardState();
}

class _MuscleGroupCardState extends State<_MuscleGroupCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.97,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.reverse(),
      onTapUp: (_) {
        _ctrl.forward();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.forward(),
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, child) =>
            Transform.scale(scale: _ctrl.value, child: child),
        child: Container(
          height: 80,
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withValues(alpha: 0.07),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: AppTheme.divider),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                // Icon container
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: widget.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(widget.icon, color: widget.accent, size: 22),
                ),
                const SizedBox(width: 16),
                // Text
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.name,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.dark,
                          letterSpacing: -0.1,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${widget.exerciseCount} exercises',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: AppTheme.muted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                // Arrow
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: widget.accent.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 13,
                    color: widget.accent,
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
