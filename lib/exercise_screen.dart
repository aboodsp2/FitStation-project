import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'app_theme.dart';

class ExerciseScreen extends StatelessWidget {
  final String muscleGroup;
  final String level;
  final String gender;

  const ExerciseScreen({
    super.key,
    required this.muscleGroup,
    required this.level,
    required this.gender,
  });

  static const Map<String, Map<String, Map<String, List<Map<String, String>>>>>
  _exercises = {
    'male': {
      'beginner': {
        'chest': [
          {
            'name': 'Bench Press',
            'video': 'assets/Mbeginner/chest/bench-press.mp4',
          },
          {
            'name': 'Chest Press',
            'video': 'assets/Mbeginner/chest/chest-press.mp4',
          },
          {
            'name': 'Chest Stretch',
            'video': 'assets/Mbeginner/chest/chest-stretch.mp4',
          },
          {'name': 'Push Up', 'video': 'assets/Mbeginner/chest/push-up.mp4'},
        ],
        'back': [
          {
            'name': 'Straight Seated Row',
            'video': 'assets/Mbeginner/back/straight-seated-row.mp4',
          },
          {
            'name': 'Wheel Rollout',
            'video': 'assets/Mbeginner/back/wheel-rollout.mp4',
          },
          {
            'name': 'Wide Pulldown',
            'video': 'assets/Mbeginner/back/wide-pulldown.mp4',
          },
          {'name': 'Shrug', 'video': 'assets/Mbeginner/back/shrug.mp4'},
        ],
        'legs': [
          {
            'name': 'Seated Leg Curl',
            'video': 'assets/Mbeginner/legs/seated-leg-curl.mp4',
          },
          {
            'name': 'Leg Extension',
            'video': 'assets/Mbeginner/legs/leg-extension.mp4',
          },
          {
            'name': 'Seated Calf',
            'video': 'assets/Mbeginner/legs/seated-calf.mp4',
          },
        ],
        'shoulders': [
          {
            'name': 'Lying Around The World',
            'video': 'assets/Mbeginner/shoulders/lying-around-theworld.mp4',
          },
          {
            'name': 'Shoulder Press',
            'video': 'assets/Mbeginner/shoulders/shoulder-press.mp4',
          },
          {
            'name': 'Lateral Shoulder',
            'video': 'assets/Mbeginner/shoulders/lateral-shoulder.mp4',
          },
        ],
        'arms': [
          {
            'name': 'Alt Biceps',
            'video': 'assets/Mbeginner/arms/alt-biceps.mp4',
          },
          {
            'name': 'Curl Biceps',
            'video': 'assets/Mbeginner/arms/curl-biceps.mp4',
          },
          {
            'name': 'Triceps Pushdown',
            'video': 'assets/Mbeginner/arms/triceps-pushdown.mp4',
          },
          {
            'name': 'Seated Bench',
            'video': 'assets/Mbeginner/arms/seated-bench.mp4',
          },
        ],
        'core': [
          {
            'name': 'Lever Back',
            'video': 'assets/Mbeginner/core/lever-back.mp4',
          },
          {
            'name': 'Lever Seated',
            'video': 'assets/Mbeginner/core/lever-seated.mp4',
          },
          {
            'name': 'Yoga Cobra',
            'video': 'assets/Mbeginner/core/yoga-cobra.mp4',
          },
        ],
      },
      'intermediate': {
        'chest': [
          {'name': 'Chest Dip', 'video': 'assets/Mmed/chest/chest-dip.mp4'},
          {
            'name': 'Fly Dumbbell',
            'video': 'assets/Mmed/chest/fly-dumbbell.mp4',
          },
          {
            'name': 'Incline Bench Press',
            'video': 'assets/Mmed/chest/incline-bench-press.mp4',
          },
        ],
        'back': [
          {
            'name': 'Bent Over Row',
            'video': 'assets/Mmed/back/bent-over-row.mp4',
          },
          {'name': 'Chin Up', 'video': 'assets/Mmed/back/chin-up.mp4'},
          {
            'name': 'Lever Pullover',
            'video': 'assets/Mmed/back/lever-pullover.mp4',
          },
          {'name': 'Smith Shrug', 'video': 'assets/Mmed/back/smith-shrug.mp4'},
        ],
        'legs': [
          {
            'name': 'Dumbbell Swing',
            'video': 'assets/Mmed/legs/dumbbell-swing.mp4',
          },
          {'name': 'Good Morning', 'video': 'assets/Mmed/legs/goodmorning.mp4'},
          {
            'name': 'Kneeling Curl',
            'video': 'assets/Mmed/legs/kneeling-curl.mp4',
          },
          {'name': 'Inverse Leg', 'video': 'assets/Mmed/legs/lnverse-leg.mp4'},
        ],
        'shoulders': [
          {
            'name': 'Cross Over Reverse Fly',
            'video': 'assets/Mmed/shoulders/cross-over-reverse-fly.mp4',
          },
          {
            'name': 'Dumbbell Shoulder Press',
            'video': 'assets/Mmed/shoulders/dumbbell-shoulder-press.mp4',
          },
          {'name': 'Rear Fly', 'video': 'assets/Mmed/shoulders/rear-fly.mp4'},
          {
            'name': 'Upright Row',
            'video': 'assets/Mmed/shoulders/upright-row.mp4',
          },
        ],
        'arms': [
          {
            'name': 'Dumbbell Reverse Wrist',
            'video': 'assets/Mmed/arms/dumbbell-reverse-wrist.mp4',
          },
          {
            'name': 'EZ Barbell Curl',
            'video': 'assets/Mmed/arms/ez-barbell-curl.mp4',
          },
          {
            'name': 'High Pulley Triceps',
            'video': 'assets/Mmed/arms/high-pulley-triceps-extension.mp4',
          },
          {
            'name': 'Inner Biceps Curl',
            'video': 'assets/Mmed/arms/inner-biceps-curl.mp4',
          },
        ],
        'core': [
          {'name': 'Dead Bug', 'video': 'assets/Mmed/core/dead-bug.mp4'},
          {
            'name': 'Kneeling Crunch',
            'video': 'assets/Mmed/core/kneeling-crunch.mp4',
          },
          {
            'name': 'Russian Twist',
            'video': 'assets/Mmed/core/russian-twist.mp4',
          },
          {'name': 'Side Plank', 'video': 'assets/Mmed/core/side-plank.mp4'},
        ],
      },
      'advanced': {
        'chest': [
          {
            'name': 'Cable Low Fly',
            'video': 'assets/Madv/chest/cable-low-fly.mp4',
          },
          {
            'name': 'Cobra Pushup',
            'video': 'assets/Madv/chest/cobra-pushup.mp4',
          },
          {
            'name': 'Dumbbell Decline Fly',
            'video': 'assets/Madv/chest/dumbbell-decline-fly.mp4',
          },
          {
            'name': 'Dumbbell Squeeze',
            'video': 'assets/Madv/chest/dumbbell-squeeze.mp4',
          },
          {'name': 'Svend Press', 'video': 'assets/Madv/chest/svend-press.mp4'},
        ],
        'back': [
          {
            'name': 'Cable Pulldown',
            'video': 'assets/Madv/back/cable-pulldown.mp4',
          },
          {
            'name': 'Kneeling One Arm Pulldown',
            'video': 'assets/Madv/back/kneeling-one-arm-pulldown.mp4',
          },
          {'name': 'Pull Up', 'video': 'assets/Madv/back/pullup.mp4'},
          {'name': 'T-Bar Row', 'video': 'assets/Madv/back/t-bar.mp4'},
        ],
        'legs': [
          {'name': 'Deadlift', 'video': 'assets/Madv/legs/deadlift.mp4'},
          {'name': 'Hip Thrust', 'video': 'assets/Madv/legs/hip-thrust.mp4'},
          {'name': 'Lunges', 'video': 'assets/Madv/legs/lunges.mp4'},
          {'name': 'Smith Squat', 'video': 'assets/Madv/legs/smith-squat.mp4'},
        ],
        'shoulders': [
          {
            'name': 'Arnold Press',
            'video': 'assets/Madv/shoulders/arnold-press.mp4',
          },
          {
            'name': 'Front Raise',
            'video': 'assets/Madv/shoulders/front-raise.mp4',
          },
        ],
        'arms': [
          {
            'name': 'Cable Kickback',
            'video': 'assets/Madv/arms/cable-kickback.mp4',
          },
          {
            'name': 'Dumbbell Incline',
            'video': 'assets/Madv/arms/dumbbell-incline.mp4',
          },
          {
            'name': 'EZ Barbell Spider',
            'video': 'assets/Madv/arms/ez-barbell-spider.mp4',
          },
          {
            'name': 'Reverse Wrist Curl',
            'video': 'assets/Madv/arms/reverse-wrist-curl.mp4',
          },
        ],
        'core': [
          {
            'name': 'Decline Crunch',
            'video': 'assets/Madv/core/decline-crunch.mp4',
          },
          {
            'name': 'Elbow To Knee',
            'video': 'assets/Madv/core/elbow-to-knee.mp4',
          },
          {'name': 'Front Plank', 'video': 'assets/Madv/core/front-plank.mp4'},
        ],
      },
    },
    'female': {
      'beginner': {
        'chest': [
          {
            'name': 'Chest Behind',
            'video': 'assets/Fbeg/chest/chest-behind.mp4',
          },
          {'name': 'Push Up', 'video': 'assets/Fbeg/chest/pushup.mp4'},
          {'name': 'Roll Chest', 'video': 'assets/Fbeg/chest/roll-chest.mp4'},
        ],
        'back': [
          {
            'name': 'Around The World',
            'video': 'assets/Fbeg/back/around-the-world.mp4',
          },
          {
            'name': 'Back Extension',
            'video': 'assets/Fbeg/back/back-extension.mp4',
          },
          {
            'name': 'Dumbbell Standing',
            'video': 'assets/Fbeg/back/dumbbell-standing.mp4',
          },
          {
            'name': 'Seated Behind Back',
            'video': 'assets/Fbeg/back/seated-behind-back.mp4',
          },
        ],
        'legs': [
          {
            'name': 'Barbell Kas Glute',
            'video': 'assets/Fbeg/legs/barbell-kas-glute.mp4',
          },
          {
            'name': 'Bulgarin Split',
            'video': 'assets/Fbeg/legs/bulgarin-split.mp4',
          },
          {
            'name': 'Hyperextension Hold',
            'video': 'assets/Fbeg/legs/hyperextension-hold.mp4',
          },
          {'name': 'Roll Foot', 'video': 'assets/Fbeg/legs/roll-foot.mp4'},
        ],
        'shoulders': [
          {
            'name': 'Lying Around The World',
            'video': 'assets/Fbeg/shoulders/lying-around-the-world.mp4',
          },
          {
            'name': 'Prayer Push',
            'video': 'assets/Fbeg/shoulders/prayer-push.mp4',
          },
          {
            'name': 'Roll Shoulder',
            'video': 'assets/Fbeg/shoulders/roll-shoulder.mp4',
          },
          {
            'name': 'Seated Ballerine',
            'video': 'assets/Fbeg/shoulders/seated-ballerine.mp4',
          },
        ],
        'arms': [
          {
            'name': 'Dumbbell Single Arm',
            'video': 'assets/Fbeg/arms/dumbbell-single-arm.mp4',
          },
          {
            'name': 'Overhead Triceps',
            'video': 'assets/Fbeg/arms/overhead-triceps.mp4',
          },
          {'name': 'Roll Biceps', 'video': 'assets/Fbeg/arms/roll-biceps.mp4'},
          {
            'name': 'Roll Forearms',
            'video': 'assets/Fbeg/arms/roll-forearms.mp4',
          },
        ],
        'core': [
          {
            'name': 'Abdominal Vacuum',
            'video': 'assets/Fbeg/core/abdominal-vacuum.mp4',
          },
          {
            'name': 'Crunch Against Wall',
            'video': 'assets/Fbeg/core/crunch-against-wall.mp4',
          },
          {
            'name': 'Seated Twist',
            'video': 'assets/Fbeg/core/seated-twist.mp4',
          },
          {
            'name': 'Standing Twist',
            'video': 'assets/Fbeg/core/standing-twist.mp4',
          },
        ],
      },
      'intermediate': {
        'chest': [
          {
            'name': 'Chest Opener',
            'video': 'assets/Fmed/chest/chest-opener.mp4',
          },
          {
            'name': 'Dumbbell Incline Press',
            'video': 'assets/Fmed/chest/dumbbell-incline-press.mp4',
          },
          {
            'name': 'Kneeling Pushup',
            'video': 'assets/Fmed/chest/kneeling-pushup.mp4',
          },
        ],
        'back': [
          {
            'name': 'Back Squeeze',
            'video': 'assets/Fmed/back/back-squeeze.mp4',
          },
          {
            'name': 'Cable Row Vbar',
            'video': 'assets/Fmed/back/cable-row-vbar.mp4',
          },
          {'name': 'Gorilla Row', 'video': 'assets/Fmed/back/gorilla-row.mp4'},
          {
            'name': 'Superman Row',
            'video': 'assets/Fmed/back/superman-row.mp4',
          },
        ],
        'legs': [
          {
            'name': 'Good Morning Machine',
            'video': 'assets/Fmed/legs/good-morning-machine.mp4',
          },
          {
            'name': 'Half Pigeon Hip',
            'video': 'assets/Fmed/legs/half-pigeon-hip.mp4',
          },
          {
            'name': 'Roll Hamstrings',
            'video': 'assets/Fmed/legs/roll-hamstrings.mp4',
          },
          {
            'name': 'Single Leg Calve',
            'video': 'assets/Fmed/legs/single-leg-calve.mp4',
          },
        ],
        'shoulders': [
          {
            'name': 'Bottle Halo',
            'video': 'assets/Fmed/shoulders/bottle-halo.mp4',
          },
          {
            'name': 'Lateral Raise',
            'video': 'assets/Fmed/shoulders/lateral-raise.mp4',
          },
          {
            'name': 'Stick Shoulders',
            'video': 'assets/Fmed/shoulders/stick-shoulders.mp4',
          },
        ],
        'arms': [
          {
            'name': 'Alt Hammer Curl',
            'video': 'assets/Fmed/arms/alt-hammer-curl.mp4',
          },
          {
            'name': 'Band Triceps Pushdown',
            'video': 'assets/Fmed/arms/band-triceps-pushdown.mp4',
          },
          {
            'name': 'Concentration Curl',
            'video': 'assets/Fmed/arms/concentration-curl.mp4',
          },
          {
            'name': 'Reverse Extensions',
            'video': 'assets/Fmed/arms/reverse-extensions.mp4',
          },
        ],
        'core': [
          {
            'name': 'Band Air Bike',
            'video': 'assets/Fmed/core/band-air-bike.mp4',
          },
          {'name': 'Lying Raise', 'video': 'assets/Fmed/core/lying-raise.mp4'},
          {'name': 'Plank Jack', 'video': 'assets/Fmed/core/plank-jack.mp4'},
          {'name': 'Stick Side', 'video': 'assets/Fmed/core/stick-side.mp4'},
        ],
      },
      'advanced': {
        'chest': [
          {
            'name': 'Kneeling Pushup',
            'video': 'assets/Fadv/chest/kneeling-pushup.mp4',
          },
          {
            'name': 'Lying Chest Press',
            'video': 'assets/Fadv/chest/lying-chest-press.mp4',
          },
          {'name': 'Svend Press', 'video': 'assets/Fadv/chest/svend-press.mp4'},
        ],
        'back': [
          {
            'name': 'Cambered Bar',
            'video': 'assets/Fadv/back/cambered-bar.mp4',
          },
          {'name': 'Pullover', 'video': 'assets/Fadv/back/pullover.mp4'},
          {'name': 'Ring High', 'video': 'assets/Fadv/back/ring-high.mp4'},
          {'name': 'Wide Chinup', 'video': 'assets/Fadv/back/wide-chinup.mp4'},
        ],
        'legs': [
          {
            'name': 'Band Reverse Hyper',
            'video': 'assets/Fadv/legs/band-reverse-hyper.mp4',
          },
          {
            'name': 'Elevated Hip Thrust',
            'video': 'assets/Fadv/legs/elevated-hip-thrust.mp4',
          },
          {'name': 'Plyo Squat', 'video': 'assets/Fadv/legs/plyo-squat.mp4'},
          {
            'name': 'Romanian Deadlift',
            'video': 'assets/Fadv/legs/romanian-deadlift.mp4',
          },
        ],
        'shoulders': [
          {
            'name': 'Handstand Wall',
            'video': 'assets/Fadv/shoulders/handstand-wall.mp4',
          },
          {
            'name': 'Shoulder Press',
            'video': 'assets/Fadv/shoulders/shoulder-press.mp4',
          },
          {
            'name': 'Single Arm Shoulder Flexion',
            'video': 'assets/Fadv/shoulders/single-arm-shoulder-flexion.mp4',
          },
          {
            'name': 'Upright Row',
            'video': 'assets/Fadv/shoulders/upright-row.mp4',
          },
        ],
        'arms': [
          {'name': 'Dip Floor', 'video': 'assets/Fadv/arms/dip-floor.mp4'},
          {
            'name': 'Roll Forearms Wall',
            'video': 'assets/Fadv/arms/roll-forearms-wall.mp4',
          },
          {
            'name': 'Triceps Extension',
            'video': 'assets/Fadv/arms/triceps-extension.mp4',
          },
        ],
        'core': [
          {
            'name': 'Kneeling Plank',
            'video': 'assets/Fadv/core/kneeling-plank.mp4',
          },
          {
            'name': 'Leg Front Kick',
            'video': 'assets/Fadv/core/leg-front-kick.mp4',
          },
          {
            'name': 'Overhead Crunch',
            'video': 'assets/Fadv/core/overhead-crunch.mp4',
          },
          {'name': 'Pull In', 'video': 'assets/Fadv/core/pull-in.mp4'},
        ],
      },
    },
  };

  List<Map<String, String>> get _currentExercises {
    final g = gender.toLowerCase();
    final l = level.toLowerCase();
    final m = muscleGroup.toLowerCase();
    return _exercises[g]?[l]?[m] ?? [];
  }

  Color get _accentColor {
    switch (level.toLowerCase()) {
      case 'beginner':
        return const Color(0xFF6BAF6B);
      case 'intermediate':
        return AppTheme.accent;
      case 'advanced':
        return AppTheme.primary;
      default:
        return AppTheme.accent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final exercises = _currentExercises;
    final accent = _accentColor;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${muscleGroup[0].toUpperCase()}${muscleGroup.substring(1)} Exercises',
              style: const TextStyle(
                fontFamily: 'Poppins',
                color: AppTheme.dark,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              '${level[0].toUpperCase()}${level.substring(1)} • ${exercises.length} exercises',
              style: TextStyle(
                fontFamily: 'Poppins',
                color: AppTheme.muted,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(color: AppTheme.divider, height: 1),
        ),
      ),
      body: exercises.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.fitness_center_rounded,
                    size: 64,
                    color: AppTheme.accent.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  Text('No exercises yet', style: AppTheme.body),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
              itemCount: exercises.length,
              itemBuilder: (context, index) => _ExerciseCard(
                exercise: exercises[index],
                index: index,
                accent: accent,
              ),
            ),
    );
  }
}

// ── Exercise Card ────────────────────────────────────────────────────

class _ExerciseCard extends StatefulWidget {
  final Map<String, String> exercise;
  final int index;
  final Color accent;

  const _ExerciseCard({
    required this.exercise,
    required this.index,
    required this.accent,
  });

  @override
  State<_ExerciseCard> createState() => _ExerciseCardState();
}

class _ExerciseCardState extends State<_ExerciseCard> {
  VideoPlayerController? _controller;
  bool _initialized = false;
  bool _isPlaying = false;
  bool _loading = false;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _initAndPlay() async {
    if (_initialized) {
      if (_isPlaying) {
        await _controller!.pause();
        setState(() => _isPlaying = false);
      } else {
        await _controller!.play();
        setState(() => _isPlaying = true);
      }
      return;
    }
    setState(() => _loading = true);
    _controller = VideoPlayerController.asset(widget.exercise['video']!);
    await _controller!.initialize();
    _controller!.setLooping(true);
    await _controller!.play();
    if (mounted) {
      setState(() {
        _initialized = true;
        _isPlaying = true;
        _loading = false;
      });
    }
  }

  void _openFullscreen() {
    if (!_initialized || _controller == null) return;
    _controller!.pause();
    setState(() => _isPlaying = false);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _FullscreenVideoScreen(
          videoPath: widget.exercise['video']!,
          exerciseName: widget.exercise['name']!,
          accentColor: widget.accent,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + widget.index * 80),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 18 * (1 - value)),
          child: child,
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 18),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withValues(alpha: 0.07),
              blurRadius: 16,
              offset: const Offset(0, 5),
            ),
          ],
          border: Border.all(color: AppTheme.divider),
        ),
        child: Column(
          children: [
            // Video area
            GestureDetector(
              onTap: _initAndPlay,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                child: Container(
                  height: 200,
                  width: double.infinity,
                  color: AppTheme.background,
                  child: _loading
                      ? Center(
                          child: CircularProgressIndicator(
                            color: widget.accent,
                          ),
                        )
                      : _initialized
                      ? Stack(
                          alignment: Alignment.center,
                          children: [
                            AspectRatio(
                              aspectRatio: _controller!.value.aspectRatio,
                              child: VideoPlayer(_controller!),
                            ),
                            if (!_isPlaying)
                              Container(
                                width: 54,
                                height: 54,
                                decoration: BoxDecoration(
                                  color: widget.accent.withValues(alpha: 0.9),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: widget.accent.withValues(alpha: 0.35),
                                      blurRadius: 14,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.play_arrow_rounded,
                                  color: Colors.white,
                                  size: 30,
                                ),
                              ),
                            // Fullscreen button
                            Positioned(
                              top: 10,
                              right: 10,
                              child: GestureDetector(
                                onTap: _openFullscreen,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.4),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.fullscreen_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 58,
                              height: 58,
                              decoration: BoxDecoration(
                                color: widget.accent.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: widget.accent.withValues(alpha: 0.4),
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                Icons.play_arrow_rounded,
                                color: widget.accent,
                                size: 32,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Tap to play',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                color: AppTheme.muted,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),

            // Info row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  // Number badge
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: widget.accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        '${widget.index + 1}',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          color: widget.accent,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.exercise['name']!,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        color: AppTheme.dark,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (_initialized) ...[
                    // Fullscreen button
                    GestureDetector(
                      onTap: _openFullscreen,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: widget.accent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: widget.accent.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Icon(
                          Icons.fullscreen_rounded,
                          color: widget.accent,
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Play/pause button
                    GestureDetector(
                      onTap: _initAndPlay,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: widget.accent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: widget.accent.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Icon(
                          _isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: widget.accent,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Fullscreen Video Screen ──────────────────────────────────────────

class _FullscreenVideoScreen extends StatefulWidget {
  final String videoPath;
  final String exerciseName;
  final Color accentColor;

  const _FullscreenVideoScreen({
    required this.videoPath,
    required this.exerciseName,
    required this.accentColor,
  });

  @override
  State<_FullscreenVideoScreen> createState() => _FullscreenVideoScreenState();
}

class _FullscreenVideoScreenState extends State<_FullscreenVideoScreen> {
  late VideoPlayerController _controller;
  bool _initialized = false;
  bool _isPlaying = false;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _initVideo();
  }

  Future<void> _initVideo() async {
    _controller = VideoPlayerController.asset(widget.videoPath);
    await _controller.initialize();
    _controller.setLooping(true);
    await _controller.play();
    if (mounted) {
      setState(() {
        _initialized = true;
        _isPlaying = true;
      });
    }
    Future.delayed(const Duration(seconds: 3), _hideControls);
  }

  void _hideControls() {
    if (mounted) setState(() => _showControls = false);
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
    if (_showControls) {
      Future.delayed(const Duration(seconds: 3), _hideControls);
    }
  }

  void _togglePlay() async {
    if (_isPlaying) {
      await _controller.pause();
    } else {
      await _controller.play();
    }
    setState(() => _isPlaying = !_isPlaying);
  }

  @override
  void dispose() {
    _controller.dispose();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleControls,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _initialized
                ? Center(
                    child: AspectRatio(
                      aspectRatio: _controller.value.aspectRatio,
                      child: VideoPlayer(_controller),
                    ),
                  )
                : Center(
                    child: CircularProgressIndicator(color: widget.accentColor),
                  ),

            AnimatedOpacity(
              opacity: _showControls ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.55),
                      Colors.transparent,
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.55),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    // Close
                    Positioned(
                      top: 16,
                      left: 16,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.45),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.fullscreen_exit_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                    // Title
                    Positioned(
                      top: 22,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Text(
                          widget.exerciseName,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            shadows: [
                              Shadow(blurRadius: 8, color: Colors.black),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Play/Pause
                    Center(
                      child: GestureDetector(
                        onTap: _togglePlay,
                        child: Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            color: widget.accentColor.withValues(alpha: 0.9),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: widget.accentColor.withValues(alpha: 0.4),
                                blurRadius: 20,
                              ),
                            ],
                          ),
                          child: Icon(
                            _isPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 36,
                          ),
                        ),
                      ),
                    ),
                    // Progress bar
                    if (_initialized)
                      Positioned(
                        bottom: 20,
                        left: 20,
                        right: 20,
                        child: VideoProgressIndicator(
                          _controller,
                          allowScrubbing: true,
                          colors: VideoProgressColors(
                            playedColor: widget.accentColor,
                            bufferedColor: Colors.white24,
                            backgroundColor: Colors.white12,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
