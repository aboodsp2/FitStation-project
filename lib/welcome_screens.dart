import 'package:fitness_app/profile_form_screen.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class WelcomeScreens extends StatefulWidget {
  const WelcomeScreens({super.key});
  @override State<WelcomeScreens> createState() => _WelcomeScreensState();
}

class _WelcomeScreensState extends State<WelcomeScreens> {
  final _ctrl = PageController();
  int _page = 0;

  void _next() {
    if (_page < 2) {
      _ctrl.nextPage(duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut);
    } else {
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => const ProfileFormScreen()));
    }
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(children: [
        PageView(
          controller: _ctrl,
          onPageChanged: (i) => setState(() => _page = i),
          physics: const NeverScrollableScrollPhysics(),
          children: const [_Slide1(), _Slide2(), _Slide3()],
        ),

        // dot indicators
        Positioned(
          bottom: 128, left: 0, right: 0,
          child: Row(mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: _page == i ? 22 : 7, height: 7,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: _page == i ? 0.95 : 0.35),
                borderRadius: BorderRadius.circular(10),
              ),
            ))),
        ),

        // next / get started button
        Positioned(
          bottom: 48, left: 28, right: 28,
          child: SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: _next,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: Text(
                _page == 2 ? "GET STARTED" : "Next",
                style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: Colors.black87),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

// ── Slide 1 — Static image background ───────────────────────────────────────
class _Slide1 extends StatelessWidget {
  const _Slide1();

  @override
  Widget build(BuildContext context) {
    return Stack(fit: StackFit.expand, children: [
      Image.asset('assets/welcome_1.jpg', fit: BoxFit.cover),
      // gradient overlay
      Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.black],
            stops: [0.42, 1.0],
          ),
        ),
      ),
      Positioned(
        bottom: 178, left: 28, right: 28,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
          Text("Welcome",
              style: TextStyle(fontFamily: 'Poppins', fontSize: 40,
                  fontWeight: FontWeight.w800, color: Colors.white, height: 1.1)),
          SizedBox(height: 12),
          Text("Your all-in-one platform for transforming your body and lifestyle.",
              style: TextStyle(fontFamily: 'Poppins', fontSize: 15,
                  color: Colors.white70, height: 1.55)),
        ]),
      ),
    ]);
  }
}

// ── Slide 2 — Video background (assets/welcome_2.mp4) ───────────────────────
class _Slide2 extends StatefulWidget {
  const _Slide2();
  @override State<_Slide2> createState() => _Slide2State();
}
class _Slide2State extends State<_Slide2> {
  late VideoPlayerController _vc;

  @override
  void initState() {
    super.initState();
    _vc = VideoPlayerController.asset('assets/welcome_2.mp4')
      ..initialize().then((_) {
        _vc.setLooping(true);
        _vc.setVolume(0);
        _vc.play();
        if (mounted) setState(() {});
      });
  }
  @override void dispose() { _vc.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Stack(fit: StackFit.expand, children: [
      _vc.value.isInitialized
          ? FittedBox(fit: BoxFit.cover,
              child: SizedBox(width: _vc.value.size.width,
                  height: _vc.value.size.height, child: VideoPlayer(_vc)))
          : Container(color: Colors.black),
      Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [Color(0x55000000), Colors.black],
            stops: [0.3, 1.0],
          ),
        ),
      ),
      Positioned(
        bottom: 178, left: 28, right: 28,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
          Text("Training Plans",
              style: TextStyle(fontFamily: 'Poppins', fontSize: 38,
                  fontWeight: FontWeight.w800, color: Colors.white, height: 1.1)),
          SizedBox(height: 12),
          Text("Whether you're a beginner or athlete, access workout plans\ncrafted by professionals to match your goals.",
              style: TextStyle(fontFamily: 'Poppins', fontSize: 15,
                  color: Colors.white70, height: 1.55)),
        ]),
      ),
    ]);
  }
}

// ── Slide 3 — Video background (assets/welcome_3.mp4) ───────────────────────
class _Slide3 extends StatefulWidget {
  const _Slide3();
  @override State<_Slide3> createState() => _Slide3State();
}
class _Slide3State extends State<_Slide3> {
  late VideoPlayerController _vc;

  @override
  void initState() {
    super.initState();
    _vc = VideoPlayerController.asset('assets/welcome_3.mp4')
      ..initialize().then((_) {
        _vc.setLooping(true);
        _vc.setVolume(0);
        _vc.play();
        if (mounted) setState(() {});
      });
  }
  @override void dispose() { _vc.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Stack(fit: StackFit.expand, children: [
      _vc.value.isInitialized
          ? FittedBox(fit: BoxFit.cover,
              child: SizedBox(width: _vc.value.size.width,
                  height: _vc.value.size.height, child: VideoPlayer(_vc)))
          : Container(color: Colors.black),
      Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [Color(0x33000000), Colors.black],
            stops: [0.3, 1.0],
          ),
        ),
      ),
      Positioned(
        bottom: 178, left: 28, right: 28,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
          Text("Supplements",
              style: TextStyle(fontFamily: 'Poppins', fontSize: 38,
                  fontWeight: FontWeight.w800, color: Colors.white,
                  fontStyle: FontStyle.italic, height: 1.1)),
          SizedBox(height: 12),
          Text("With us you can fuel your body the right way.",
              style: TextStyle(fontFamily: 'Poppins', fontSize: 15,
                  color: Colors.white70, height: 1.55)),
        ]),
      ),
    ]);
  }
}
